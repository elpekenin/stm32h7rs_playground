const std = @import("std");

const BuildConfig = @import("modules/build/Config.zig");

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
    const logging = build_config.getLogging(b);
    const options = build_config.getOptions(b);

    // Put things together
    hal.linkLibrary(libc);
    hal.addConfigHeader(halconf);

    logging.addImport(BuildConfig.IMPORT_NAME, options);
    logging.addImport("hal", hal);

    program.addImport(BuildConfig.IMPORT_NAME, options);
    program.addImport("hal", hal);

    startup.linkLibrary(libc);
    startup.root_module.addImport(BuildConfig.IMPORT_NAME, options);
    startup.root_module.addImport("hal", hal);
    startup.root_module.addImport("logging", logging);
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
