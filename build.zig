const std = @import("std");

const Config = @import("modules/build/Config.zig");

const BUILD_CONFIG = "build_config";

fn currentDate(b: *std.Build) []const u8 {
    const out = b.run(&.{ "date", "+\"%Y-%m-%d\"" });
    return out[1 .. out.len - 2]; // output is wrapped in quotes, remove them
}

pub fn build(b: *std.Build) !void {
    // *** Build configuration ***
    const config = Config.fromArgs(b);
    const halconf = config.hal.configHeader(b);

    const target = b.resolveTargetQuery(.{
        .cpu_arch = .thumb,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m7 },
        .cpu_features_add = std.Target.arm.featureSet(&.{
            // FIXME: which one is correct?
            .vfp4d16,
            // .fp_armv8d16,
        }),
        .os_tag = .freestanding,
        .abi = .eabihf,
    });

    const optimize: std.builtin.OptimizeMode = .ReleaseSmall;

    // *** Entry point ***
    const start = b.addExecutable(.{
        .name = b.fmt("{s}.elf", .{config.program.name}), // STM32CubeProgrammer does not like the lack of extension
        .root_source_file = b.path("modules/common/start.zig"),
        .target = target,
        .optimize = optimize,
        .strip = false,
        .error_tracing = true,
    });
    start.setLinkerScript(b.path(b.fmt("ld/{s}.ld", .{config.program.name})));

    // *** Dependencies ***
    const libc_dep = b.dependency(
        config.libc.dependency,
        .{
            .target = target,
            .optimize = optimize,
        },
    );
    const libc_lib = libc_dep.artifact(config.libc.artifact);

    const hal_dep = b.dependency("hal", .{});
    const hal_module = hal_dep.module("hal");

    const rtt_dep = b.dependency("rtt", .{}).module("rtt");

    const zfat_dep = b.dependency(
        "zfat",
        .{
            .target = target,
            .optimize = optimize,
            .@"static-rtc" = currentDate(b),
            .@"no-libc" = true,
        },
    );
    const zfat_module = zfat_dep.module("zfat");

    // *** zig code ***
    const program_module = b.addModule(
        "program",
        .{
            .root_source_file = b.path(
                b.fmt("modules/{s}/main.zig", .{config.program.name}),
            ),
        },
    );

    const logging_module = b.addModule(
        "logging",
        .{
            .root_source_file = b.path("modules/logging/logging.zig"),
        },
    );

    // *** Expose build config to code ***
    const options = config.addOptions(b);
    options.addOption(bool, "has_zfat", true);
    const options_module = options.createModule();

    // *** Glue together (sorted alphabetically just because) ***
    program_module.addImport("hal", hal_module);
    program_module.addImport(BUILD_CONFIG, options_module);

    hal_module.addConfigHeader(halconf);
    hal_module.linkLibrary(libc_lib);

    libc_lib.link_gc_sections = true;
    libc_lib.link_data_sections = true;
    libc_lib.link_function_sections = true;

    logging_module.addImport("fatfs", zfat_module);
    logging_module.addImport("hal", hal_module);
    logging_module.addImport(BUILD_CONFIG, options_module);
    logging_module.addImport("rtt", rtt_dep);

    start.linkLibrary(libc_lib);
    start.root_module.addImport("program", program_module);
    start.root_module.addImport("hal", hal_module);
    start.root_module.addImport("logging", logging_module);
    start.root_module.addImport(BUILD_CONFIG, options_module);
    start.step.dependOn(&halconf.step); // FIXME: remove hack

    zfat_module.linkLibrary(libc_lib);

    // otherwise it gets optimized away
    start.forceUndefinedSymbol("vector_table");

    // *** Output ***
    b.installArtifact(start);
}
