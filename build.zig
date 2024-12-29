const std = @import("std");

const BuildConfig = @import("build/Config.zig");
const version_info = @import("build/version_info.zig");

/// Fix the fake RTC shown by zfat/FatFS, to the date of building
fn currentDate(b: *std.Build) []const u8 {
    const out = b.run(&.{ "date", "+\"%Y-%m-%d\"" });
    return out[1 .. out.len - 2]; // output is wrapped in quotes, remove them
}

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
    const version = version_info.getOptions(b);

    // Modules that do not depend on build config, just pull them from zon
    const defmt = b.dependency("defmt", .{}).module("defmt");
    const fatfs = b.dependency(
        "zfat",
        .{
            .chmod = true,
            //  with .no_advanced: f_stat(), f_getfree(), f_unlink(), f_mkdir(), f_truncate() and f_rename() are removed.
            // .minimize = .no_advanced,
            .relative_path_api = .enabled_with_getcwd,
            .@"no-libc" = true,
            .@"static-rtc" = currentDate(b),
        },
    ).module("zfat");
    const rtt = b.dependency("rtt", .{}).module("rtt");
    const ushell = b.dependency("ushell", .{}).module("ushell");

    // Not standalone (yet?)
    const mx66 = b.addModule("mx66", .{
        .root_source_file = b.path("modules/mx66/mod.zig"),
    });
    const sd_fatfs = b.addModule("sd_fatfs", .{
        .root_source_file = b.path("modules/sd_fatfs.zig"),
    });

    // Put things together
    fatfs.linkLibrary(libc);

    hal.linkLibrary(libc);
    hal.addConfigHeader(halconf);

    mx66.addImport("hal", hal);
    mx66.addImport("program", program);

    sd_fatfs.addImport("fatfs", fatfs);
    sd_fatfs.addImport("hal", hal);

    program.addImport("config", options);
    program.addImport("defmt", defmt);
    program.addImport("fatfs", fatfs);
    program.addImport("hal", hal);
    program.addImport("mx66", mx66);
    program.addImport("rtt", rtt);
    program.addImport("sd_fatfs", sd_fatfs);
    program.addImport("ushell", ushell);
    program.addImport("version", version);

    startup.linkLibrary(libc);
    startup.root_module.addImport("config", options);
    startup.root_module.addImport("fatfs", fatfs);
    startup.root_module.addImport("hal", hal);
    startup.root_module.addImport("program", program);
    startup.root_module.addImport("rtt", rtt);
    startup.root_module.addImport("sd_fatfs", sd_fatfs);
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
