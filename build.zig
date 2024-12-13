const std = @import("std");

const BuildConfig = @import("build/Config.zig");

/// Entrypoint for the build script
pub fn build(b: *std.Build) !void {
    // Build configuration
    const build_config = BuildConfig.fromArgs(b);
    const halconf = build_config.hal.configHeader(b);

    // Actual code to run
    const program = build_config.getProgram(b);
    const startup = build_config.getEntrypoint(b);

    // Dependencies/helper modules
    const hal = build_config.getHal(b);
    const libc = build_config.getLibC(b);
    const options = build_config.getOptions(b);

    const defmt = b.dependency("defmt", .{}).module("defmt");
    const ushell = b.dependency("ushell", .{}).module("ushell");

    const mx66 = b.addModule("mx66", .{
        .root_source_file = b.path("modules/mx66/mod.zig"),
    });

    // Put things together
    hal.linkLibrary(libc);
    hal.addConfigHeader(halconf);

    mx66.addImport("hal", hal);
    mx66.addImport("program", program);

    program.addImport("build_config", options);
    program.addImport("defmt", defmt);
    program.addImport("hal", hal);
    program.addImport("mx66", mx66);
    program.addImport("rtt", startup.root_module.import_table.get("rtt").?); // FIXME: remove hack
    program.addImport("ushell", ushell);

    startup.linkLibrary(libc);
    startup.root_module.addImport("build_config", options);
    startup.root_module.addImport("hal", hal);
    startup.root_module.addImport("program", program);
    startup.step.dependOn(&halconf.step); // FIXME: remove hack

    // Reduce size
    libc.link_gc_sections = true;
    libc.link_data_sections = true;
    libc.link_function_sections = true;

    // Prevent vector table from being optimized away
    startup.forceUndefinedSymbol("vector_table");

    // Binary output
    b.installArtifact(startup);
}
