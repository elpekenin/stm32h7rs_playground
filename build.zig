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
    const options = config.getOptions(b);
    const version = version_info.getOptions(b);

    // Actual code to run
    const exe = config.getEntrypoint(b);
    const program = config.getProgram(b);

    // Steps
    const defmt = b.dependency("defmt", .{
        .optimize = config.optimize,
        .target = config.target,
    });
    const defmt_mod = defmt.module("defmt");

    const foundation = b.dependency("foundation-libc", .{
        .optimize = config.optimize,
        .target = config.target,
        .single_threaded = true,
    });
    const libc = foundation.artifact("foundation");

    const hal = b.dependency("hal", .{
        .optimize = config.optimize,
        .target = config.target,
        .libc_headers = libc.getEmittedIncludeTree(),
    });
    const hal_mod = hal.module("hal");

    const mx66 = b.createModule(.{
        .root_source_file = b.path("modules/mx66/mod.zig"),
        .optimize = config.optimize,
        .target = config.target,
    });

    const rtt = b.dependency("rtt", .{
        .optimize = config.optimize,
        .target = config.target,
    });
    const rtt_mod = rtt.module("rtt");

    const sd = b.createModule(.{
        .root_source_file = b.path("modules/sd.zig"),
        .optimize = config.optimize,
        .target = config.target,
    });

    const ushell = b.dependency("ushell", .{
        .optimize = config.optimize,
        .target = config.target,
    });
    const ushell_mod = ushell.module("ushell");

    const zfat = b.dependency("zfat", .{
        .optimize = config.optimize,
        .target = config.target,
        .chmod = true,
        //  with .no_advanced: f_stat(), f_getfree(), f_unlink(), f_mkdir(), f_truncate() and f_rename() are removed.
        // .minimize = .no_advanced,
        .relative_path_api = .enabled_with_getcwd,
        .@"no-libc" = true,
        .@"static-rtc" = currentDate(b),
    });
    const zfat_mod = zfat.module("zfat");

    // Glue together
    exe.linkLibrary(libc);
    exe.root_module.addImport("config", options);
    exe.root_module.addImport("hal", hal_mod);
    exe.root_module.addImport("program", program);
    exe.root_module.addImport("rtt", rtt_mod);
    exe.root_module.addImport("sd", sd);
    exe.root_module.addImport("zfat", zfat_mod);

    hal_mod.linkLibrary(libc);

    mx66.addImport("hal", hal_mod);
    mx66.addImport("program", program);

    program.addImport("config", options);
    program.addImport("defmt", defmt_mod);
    program.addImport("hal", hal_mod);
    program.addImport("mx66", mx66);
    program.addImport("rtt", rtt_mod);
    program.addImport("sd", sd);
    program.addImport("ushell", ushell_mod);
    program.addImport("version", version);
    program.addImport("zfat", zfat_mod);

    sd.addImport("hal", hal_mod);
    sd.addImport("zfat", zfat_mod);

    zfat_mod.linkLibrary(libc);

    // Reduce size
    libc.link_gc_sections = true;
    libc.link_data_sections = true;
    libc.link_function_sections = true;

    // Prevent vector table from being optimized away
    exe.forceUndefinedSymbol("vector_table");

    // Artifacts
    const elf = b.addInstallArtifact(exe, .{});
    const bin = b.addObjCopy(elf.emitted_bin.?, .{
        .format = .bin,
    });
    const install_bin = b.addInstallBinFile(
        bin.getOutput(),
        b.fmt("{s}.bin", .{config.program.name()}),
    );

    // Steps
    install_bin.step.dependOn(&elf.step);
    b.default_step.dependOn(&install_bin.step);
}
