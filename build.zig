const std = @import("std");
const PanicType = @import("src/zig/common/panic_config.zig").PanicType;

const Program = enum {
    const Self = @This();

    bootloader,
    application,

    fn name(self: Self) []const u8 {
        return switch (self) {
            .bootloader => "bootloader",
            .application => "application",
        };
    }
};

const LibC = enum {
    const Self = @This();

    picolibc,
    foundation,

    fn dependency(self: Self) []const u8 {
        return switch (self) {
            .picolibc => "picolibc",
            .foundation => "foundation",
        };
    }

    fn artifact(self: Self) []const u8 {
        return switch (self) {
            .picolibc => "c",
            .foundation => "foundation",
        };
    }
};

pub fn build(b: *std.Build) !void {
    // *** Build configuration ***
    const program: Program = b.option(
        Program,
        "program",
        "Program to build",
    ) orelse @panic("Select target program");

    const libc: LibC = b.option(
        LibC,
        "libc",
        "LibC implementation to use",
    ) orelse @panic("Select a libc implementation");

    const panic_type: PanicType = b.option(
        PanicType,
        "panic_type",
        "Control panic behavior",
    ) orelse .ToggleLeds;

    const panic_timer: u16 = b.option(
        u16,
        "panic_timer",
        "Control panic behavior",
    ) orelse 500;

    const target = b.resolveTargetQuery(.{
        .cpu_arch = .thumb,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m7 },
        .cpu_features_add = std.Target.arm.featureSet(&.{
            // .vfp4d16,
            // .fp_armv8d16,
        }),
        .os_tag = .freestanding,
        .abi = .eabihf,
    });

    const optimize: std.builtin.OptimizeMode = .ReleaseSmall;

    // *** Entry point ***
    const start = b.addExecutable(.{
        .name = b.fmt("{s}.elf", .{program.name()}), // STM32CubeProgrammer does not like the lack of extension
        .root_source_file = b.path("src/zig/common/start.zig"),
        .target = target,
        .optimize = optimize,
        .strip = false,
        .error_tracing = true,
    });
    start.setLinkerScript(b.path(b.fmt("ld/{s}.ld", .{program.name()})));

    // *** Dependencies ***
    const libc_dep = b.dependency(
        libc.dependency(),
        .{
            .target = target,
            .optimize = optimize,
        },
    );
    const libc_lib = libc_dep.artifact(libc.artifact());

    const hal_dep = b.dependency(
        "hal",
        .{
            .target = target,
            .optimize = optimize,
        },
    ).artifact("lib");

    const rtt_dep = b.dependency("rtt", .{}).module("rtt");

    const zfat_dep = b.dependency(
        "zfat",
        .{
            .target = target,
            .optimize = optimize,
            .@"static-rtc" = @as([]const u8, "2025-01-01"),
            .@"no-libc" = true,
        },
    );
    const zfat_module = zfat_dep.module("zfat");

    // *** zig code ***
    const hal_module = b.addModule(
        "hal",
        .{
            .root_source_file = b.path("src/zig/hal/hal.zig"),
        },
    );
    hal_module.addCSourceFiles(.{ // User-level configuration of the HAL
        .files = stubs,
        .flags = &.{"-fno-sanitize=undefined"},
        .root = b.path("src/c"),
    });
    hal_dep.addIncludePath(b.path("src/c")); // hal_conf.h
    hal_module.addIncludePath(b.path("src/c")); // for @cImport
    inline for (.{
        // prevent CMSIS from providing a default entrypoint
        // and instead make it use the one defined on start.zig
        "-D__PROGRAM_START=_start",

        // needed for a HAL code to be compiled
        // usually defined by STM32IDE (im assuming, not seen on any file)
        "-DSTM32H7S7xx",
        "-DUSE_HAL_DRIVER",
    }) |macro| {
        hal_dep.root_module.c_macros.append(b.allocator, macro) catch @panic("OOM");
        hal_module.c_macros.append(b.allocator, macro) catch @panic("OOM");
    }

    const app_module = b.addModule(
        "application",
        .{
            .root_source_file = b.path(
                b.fmt("src/zig/{s}/main.zig", .{program.name()}),
            ),
        },
    );

    const logging_module = b.addModule(
        "logging",
        .{
            .root_source_file = b.path("src/zig/logging/logging.zig"),
        },
    );

    const options = b.addOptions();
    options.addOption(bool, "has_zfat", true);
    options.addOption([]const u8, "app_name", program.name());
    // TODO: Expose to CLI?
    options.addOption(usize, "panic_type", @intFromEnum(panic_type)); // HAL_Delay after iterating all LEDs
    options.addOption(u16, "panic_timer", panic_timer); // HAL_Delay between LEDs
    const options_module = options.createModule();

    // *** Glue together (sorted alphabetically just because) ***
    app_module.addImport("hal", hal_module);
    app_module.addImport("options", options_module);

    hal_dep.linkLibrary(libc_lib);
    hal_dep.link_gc_sections = true;
    hal_dep.link_data_sections = true;
    hal_dep.link_function_sections = true;

    hal_module.linkLibrary(hal_dep);
    hal_module.linkLibrary(libc_lib);

    libc_lib.link_gc_sections = true;
    libc_lib.link_data_sections = true;
    libc_lib.link_function_sections = true;

    logging_module.addImport("fatfs", zfat_module);
    logging_module.addImport("hal", hal_module);
    logging_module.addImport("options", options_module);
    logging_module.addImport("rtt", rtt_dep);

    start.linkLibrary(libc_lib);
    start.root_module.addImport("application", app_module);
    start.root_module.addImport("hal", hal_module);
    start.root_module.addImport("logging", logging_module);
    start.root_module.addImport("options", options_module);

    zfat_module.linkLibrary(libc_lib);

    // otherwise it gets optimized away
    start.forceUndefinedSymbol("vector_table");

    // *** Output ***
    b.installArtifact(start);
}

const stubs = &.{
    "system_stm32rsxx.c",
};
