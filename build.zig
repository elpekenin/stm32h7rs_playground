const std = @import("std");

const BuildConfig = @import("build/Config.zig");
const version_info = @import("build/version_info.zig");

/// Lock the fake RTC shown by zfat, to the date of building
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
    const exe = config.getEntrypoint(b);
    const program = config.getProgram(b);

    // Modules
    const defmt = b.dependency("defmt", .{
        .optimize = config.optimize,
    }).module("defmt");

    const foundation = b.dependency("foundation-libc", .{
        .optimize = config.optimize,
        .target = config.target,
    }).artifact("foundation");

    const hal = b.dependency("hal", .{
        .optimize = config.optimize,
        .target = config.target,
    }).module("hal");

    const mx66 = b.createModule(.{
        .root_source_file = b.path("modules/mx66/mod.zig"),
        .optimize = config.optimize,
    });

    const rtt = b.dependency("rtt", .{
        .optimize = config.optimize,
    }).module("rtt");

    const sd = b.createModule(.{
        .root_source_file = b.path("modules/sd.zig"),
        .optimize = config.optimize,
    });

    const ushell = b.dependency("ushell", .{
        .optimize = config.optimize,
    }).module("ushell");

    const zfat = b.dependency("zfat", .{
        .optimize = config.optimize,
        .chmod = true,
        //  with .no_advanced: f_stat(), f_getfree(), f_unlink(), f_mkdir(), f_truncate() and f_rename() are removed.
        // .minimize = .no_advanced,
        .relative_path_api = .enabled_with_getcwd,
        .@"no-libc" = true,
        .@"static-rtc" = currentDate(b),
    }).module("zfat");

    // Put things together
    exe.linkLibrary(foundation);
    exe.root_module.addImport("config", options);
    exe.root_module.addImport("hal", hal);
    exe.root_module.addImport("program", program);
    exe.root_module.addImport("rtt", rtt);
    exe.root_module.addImport("sd", sd);
    exe.root_module.addImport("zfat", zfat);
    exe.step.dependOn(&halconf.step); // FIXME: remove hack

    hal.linkLibrary(foundation);
    hal.addConfigHeader(halconf);

    mx66.addImport("hal", hal);
    mx66.addImport("program", program);

    program.addImport("config", options);
    program.addImport("defmt", defmt);
    program.addImport("hal", hal);
    program.addImport("mx66", mx66);
    program.addImport("rtt", rtt);
    program.addImport("sd", sd);
    program.addImport("ushell", ushell);
    program.addImport("version", version);
    program.addImport("zfat", zfat);

    sd.addImport("hal", hal);
    sd.addImport("zfat", zfat);

    zfat.linkLibrary(foundation);

    // Reduce size
    foundation.link_gc_sections = true;
    foundation.link_data_sections = true;
    foundation.link_function_sections = true;

    // Prevent vector table from being optimized away
    exe.forceUndefinedSymbol("vector_table");

    // Binary output
    const elf = b.addInstallArtifact(exe, .{});
    const bin = b.addObjCopy(elf.emitted_bin.?, .{
        .format = .bin,
    });
    const install_bin = b.addInstallBinFile(
        bin.getOutput(),
        b.fmt("{s}.bin", .{config.program.name()}),
    );

    install_bin.step.dependOn(&elf.step);
    b.default_step.dependOn(&install_bin.step);
}
