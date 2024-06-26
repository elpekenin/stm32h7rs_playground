const std = @import("std");
const PanicType = @import("src/zig/start.zig").PanicType;

const Program = enum {
    const Self = @This();

    Bootloader,
    Application,

    pub fn name(self: Self) []const u8 {
        return switch (self) {
            .Bootloader => "bootloader",
            .Application => "application",
        };
    }
};

pub fn build(b: *std.Build) !void {
    // *** Build configuration ***
    const app_type = b.option(Program, "program", "Program to build (bootloader or app)") orelse @panic("Select target program");
    const panic_type = b.option(PanicType, "panic", "What to do upon panic") orelse .ToggleLeds;

    const target = b.resolveTargetQuery(.{
        .cpu_arch = .thumb,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m7 },
        .os_tag = .freestanding,
        .abi = .eabihf,
    });
    const optimize: std.builtin.OptimizeMode = .ReleaseSmall;

    // *** Entry point ***
    const start = b.addExecutable(.{
        .name = b.fmt("{s}.elf", .{app_type.name()}), // STM32CubeProgrammer does not like the lack of extension
        .root_source_file = b.path("src/zig/start.zig"),
        .target = target,
        .optimize = optimize,
        .strip = false,
        .error_tracing = true,
    });
    start.setLinkerScript(b.path(b.fmt("ld/{s}.ld", .{app_type.name()})));

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
            b.fmt("src/zig/{s}/main.zig", .{app_type.name()}),
        ),
    });

    const logging_module = b.addModule("logging", .{
        .root_source_file = b.path("src/zig/logging/logging.zig"),
    });

    const options = b.addOptions();
    options.addOption(bool, "has_zfat", true);
    options.addOption([]const u8, "app_name", app_type.name());
    // TODO: Expose to CLI?
    options.addOption(usize, "panic_type", @intFromEnum(panic_type)); // HAL_Delay after iterating all LEDs
    options.addOption(u16, "panic_timer", 0); // HAL_Delay between LEDs
    const options_module = options.createModule();

    // *** Glue together (sorted alphabetically just because) ***
    app_module.addImport("hal", hal_module);
    app_module.addImport("options", options_module);

    hal_dep.linkLibrary(libc_dep);
    hal_dep.link_gc_sections = true;
    hal_dep.link_data_sections = true;
    hal_dep.link_function_sections = true;

    hal_module.linkLibrary(hal_dep);
    hal_module.linkLibrary(libc_dep);

    libc_dep.link_gc_sections = true;
    libc_dep.link_data_sections = true;
    libc_dep.link_function_sections = true;

    logging_module.addImport("fatfs", zfat_dep);
    logging_module.addImport("hal", hal_module);
    logging_module.addImport("options", options_module);
    logging_module.addImport("rtt", rtt_dep);

    start.linkLibrary(libc_dep);
    start.root_module.addImport("application", app_module);
    start.root_module.addImport("hal", hal_module);
    start.root_module.addImport("logging", logging_module);
    start.root_module.addImport("options", options_module);

    zfat_dep.linkLibrary(libc_dep);

    // *** Output ***
    b.installArtifact(start);
}

const stubs = &.{
    "dummy_syscalls.c",
    "interrupt_table.c",
    "system_stm32rsxx.c",
    "stm32h7rsxx_hal_timebase_tim.c",
};
