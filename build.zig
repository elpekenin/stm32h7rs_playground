const std = @import("std");

const AppType = enum {
    const Self = @This();

    Bootloader,
    UserLand,

    pub fn name(self: Self) []const u8 {
        return switch (self) {
            .Bootloader => "bootloader",
            .UserLand => "application",
        };
    }
};

const StringBuilder = struct {
    const Self = @This();

    allocator: std.mem.Allocator,

    pub fn concat(self: Self, first: []const u8, second: []const u8) []const u8 {
        const buff = self.allocator.alloc(u8, first.len + second.len) catch @panic("OOM");

        var i: usize = 0;
        for (first) |val| {
            buff[i] = val;
            i += 1;
        }

        for (second) |val| {
            buff[i] = val;
            i += 1;
        }

        return buff;
    }
};

pub fn build(b: *std.Build) !void {
    // *** Helper for string manipulations ***
    const string_builder = StringBuilder{ .allocator = b.allocator };

    // *** Build configuration ***
    const app_type = b.option(AppType, "application", "Type of appication being built (bootloader or user)") orelse .Bootloader;
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .thumb,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m7 },
        .os_tag = .freestanding,
        .abi = .eabihf,
    });
    const optimize: std.builtin.OptimizeMode = .ReleaseSmall;

    // *** Entry point ***
    const start = b.addExecutable(.{
        .name = string_builder.concat(app_type.name(), ".elf"), // STM32CubeProgrammer does not like the lack of extension
        .root_source_file = b.path("src/zig/start.zig"),
        .target = target,
        .optimize = optimize,
        .strip = false,
        .error_tracing = true,
    });
    start.setLinkerScript(b.path(string_builder.concat("ld/", string_builder.concat(app_type.name(), ".ld"))));

    // *** Dependencies ***
    const libc_dep = b.dependency("picolibc", .{
        .target = target,
        .optimize = optimize,
    }).artifact("c");

    const hal_dep = b.dependency("hal", .{
        .target = target,
        .optimize = optimize,
    }).artifact("hal");

    const rtt_dep = b.dependency("rtt", .{}).module("rtt");

    const zfat_dep = b.dependency("zfat", .{
        .target = target,
        .optimize = optimize,
        .@"static-rtc" = @as([]const u8, "2024-06-17"),
        .@"no-libc" = true,
    }).module("zfat");

    // *** zig code ***
    const hal_module = b.addModule("hal", .{
        .root_source_file = b.path("src/zig/hal/hal.zig"),
    });
    hal_module.addCSourceFiles(.{ // User-level configuration of the HAL
        .files = stubs,
        .flags = &.{"-fno-sanitize=undefined"},
        .root = b.path("src/c"),
    });
    hal_dep.addIncludePath(b.path("src/c")); // hal_conf.h
    hal_module.addIncludePath(b.path("src/c")); // for @cImport
    inline for (.{
        // prevent CMSIS from providing a default entrypoint
        // zig does not properly handle the typedef in a func and C->zig fails
        // ... and we shouldnt need "copy_table_t" or "zero_table_t"
        "-D__PROGRAM_START=_start",

        // needed for a HAL code to be compiled
        // usually defined by STM32IDE (im assuming, not seen on any file)
        "-DSTM32H7S7xx",
        "-DUSE_HAL_DRIVER",
    }) |macro| {
        hal_dep.root_module.c_macros.append(b.allocator, macro) catch @panic("OOM");
        hal_module.c_macros.append(b.allocator, macro) catch @panic("OOM");
    }

    const app_module = b.addModule("application", .{
        .root_source_file = b.path(
            string_builder.concat("src/zig/", string_builder.concat(app_type.name(), "/main.zig")),
        ),
    });

    const logging_module = b.addModule("logging", .{
        .root_source_file = b.path("src/zig/logging/logging.zig"),
    });

    const options = b.addOptions();
    options.addOption(bool, "has_zfat", true);
    options.addOption([]const u8, "app_name", app_type.name());
    const options_module = options.createModule();

    // *** Glue together (sorted alphabetically just because) ***
    app_module.addImport("hal", hal_module);
    app_module.addImport("options", options_module);

    hal_module.linkLibrary(hal_dep);

    logging_module.addImport("fatfs", zfat_dep);
    logging_module.addImport("hal", hal_module);
    logging_module.addImport("options", options_module);
    logging_module.addImport("rtt", rtt_dep);

    start.root_module.addImport("application", app_module);
    start.root_module.addImport("hal", hal_module);
    start.root_module.addImport("logging", logging_module);
    start.root_module.addImport("options", options_module);

    // Pieces that depend on libc must link explicitly against it
    // chain of dependencies doesnt seem to work
    inline for (.{
        start,
        hal_dep,
        zfat_dep,
        hal_module,
    }) |module| {
        module.linkLibrary(libc_dep);
    }

    // strip unused symbols to save space, flash is small
    inline for (.{
        libc_dep,
        hal_dep,
    }) |module| {
        module.link_gc_sections = true;
        module.link_data_sections = true;
        module.link_function_sections = true;
    }

    b.installArtifact(start);
}

const stubs = &.{
    "dummy_syscalls.c",
    "interrupt_table.c",
    "system_stm32rsxx.c",
    "stm32h7rsxx_hal_timebase_tim.c",
};
