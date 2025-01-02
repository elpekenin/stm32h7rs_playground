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
    const config = BuildConfig.fromArgs(b);
    const halconf = config.hal.configHeader(b);
    const options = config.getOptions(b);
    const version = version_info.getOptions(b);

    // Actual code to run
    const program = config.getProgram(b);
    const startup = config.getEntrypoint(b);

    // Modules
    const defmt = b.dependency("defmt", .{
        .optimize = config.optimize,
    }).module("defmt");

    const fatfs = b.dependency(
        "fatfs",
        .{
            .optimize = config.optimize,
            .chmod = true,
            //  with .no_advanced: f_stat(), f_getfree(), f_unlink(), f_mkdir(), f_truncate() and f_rename() are removed.
            // .minimize = .no_advanced,
            .relative_path_api = .enabled_with_getcwd,
            .@"no-libc" = true,
            .@"static-rtc" = currentDate(b),
        },
    ).module("zfat");

    const hal = b.dependency(
        "hal",
        .{
            .optimize = config.optimize,
            .target = config.target,
        },
    ).module("hal");

    const libc = config.getLibC(b);

    const mx66 = b.addModule("mx66", .{
        .root_source_file = b.path("modules/mx66/mod.zig"),
        .optimize = config.optimize,
    });

    const rtt = b.dependency("rtt", .{
        .optimize = config.optimize,
    }).module("rtt");

    const sd_fatfs = b.addModule("sd_fatfs", .{
        .root_source_file = b.path("modules/sd_fatfs.zig"),
        .optimize = config.optimize,
    });

    const ushell = b.dependency("ushell", .{
        .optimize = config.optimize,
    }).module("ushell");

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
