// TODO: Flag/step to select between actual app and bootloader

const std = @import("std");

pub fn build(b: *std.Build) !void {
    // *** Build configuration ***
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .thumb,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m7 },
        .os_tag = .freestanding,
        .abi = .eabihf,
    });
    const optimize: std.builtin.OptimizeMode = .ReleaseSmall;

    // *** Deps ***
    const libc = b.dependency("picolibc", .{
        .target = target,
        .optimize = optimize,
    }).artifact("c");

    const hal = b.dependency("hal", .{
        .target = target,
        .optimize = optimize,
    }).artifact("hal");

    const rtt = b.dependency("rtt", .{
        .target = target,
        .optimize = optimize,
    }).module("rtt");

    const zfat_dependency = b.dependency("zfat", .{
        .target = target,
        .optimize = optimize,
        .@"static-rtc" = @as([]const u8, "2024-06-17"),
    });
    const zfat_artifact = zfat_dependency.artifact("zfat");
    const zfat_module = zfat_dependency.module("zfat");

    // *** Actual zig code ***
    const zig = b.addExecutable(.{
        .name = "app",
        .root_source_file = b.path("src/zig/bootloader.zig"),
        .target = target,
        .optimize = optimize,
    });

    // *** Glue everything together ***
    // Pieces that depend on libc must link explicitly agains it
    // chain of dependencies doesnt seem to work
    inline for (.{
        hal,
        zig,
        zfat_artifact,
    }) |module| {
        module.linkLibrary(libc); // also pulls headers
    }

    // User-level configuration of the HAL
    hal.addCSourceFiles(.{
        .files = stubs,
        .flags = &.{"-fno-sanitize=undefined"},
        .root = b.path("src/c"),
    });
    inline for (.{
        "src/c", // hal_conf.h
        "lib/cmsis/Include", // TODO: Move to repo's build.zig
        "lib/CMSIS_5/CMSIS/Core/Include", // TODO: Move to repo's build.zig
    }) |path| {
        // required for HAL to buiild
        hal.addIncludePath(b.path(path));

        // make them visible to anything linking against HAL (aka custom zig code)
        hal.installHeadersDirectory(b.path(path), "", .{});
    }

    // macros required on the toolchain level for HAL compilation
    // zig also requires them for `@cImport`, but are added with `@cDefine`
    // for better LSP support
    inline for (.{
        // prevent CMSIS from providing a defalt entrypoint
        // zig does not properly handle the typedef in a func and C->zig fails
        // ... and we shouldnt need "copy_table_t" or "zero_table_t"
        "-D__PROGRAM_START=_start",

        // needed for a HAL code to be compiled
        // usually defined by STM32IDE (im assuming, not seen on any file)
        "-DSTM32H7S7xx",
        "-DUSE_HAL_DRIVER",
        // "-DUSE_FULL_LL_DRIVER", // for .Debug, but still not working.
    }) |macro| {
        hal.root_module.c_macros.append(b.allocator, macro) catch @panic("OOM");
    }

    zig.linkLibrary(hal);

    zig.root_module.addImport("rtt", rtt);
    zig.root_module.addImport("fatfs", zfat_module);

    zig.setLinkerScript(b.path("ld/bootloader.ld"));

    // *** .elf -> .bin ***
    const elf = b.addInstallArtifact(zig, .{});
    b.default_step.dependOn(&elf.step);

    const elf2bin = b.addObjCopy(zig.getEmittedBin(), .{ .format = .bin });
    elf2bin.step.dependOn(&elf.step);

    const bin = b.addInstallBinFile(elf2bin.getOutput(), "app.bin");
    b.default_step.dependOn(&bin.step);
}

const stubs = &.{
    "dummy_syscalls.c",
    "interrupt_table.c",
    "system_stm32rsxx.c",
    "stm32h7rsxx_hal_timebase_tim.c",
};
