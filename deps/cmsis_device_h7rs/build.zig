const std = @import("std");

pub fn build(b: *std.Build) !void {
    // options:
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const dep = b.dependency("upstream", .{});

    const lib = b.addStaticLibrary(.{
        .name = "lib",
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("../dummy.zig"),
    });
    lib.installHeadersDirectory(dep.path("Include"), "", .{});

    b.installArtifact(lib);
}
