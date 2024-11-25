//! Which implementation of C's standard library is being used

const std = @import("std");
const Build = std.Build;
const Options = Build.Step.Options;

const Self = @This();

const Implementation = enum {
    picolibc,
    foundation,
};

dependency: []const u8,
artifact: []const u8,

fn from(impl: Implementation) Self {
    return switch (impl) {
        .picolibc => Self{
            .dependency = "picolibc",
            .artifact = "c",
        },
        .foundation => Self{
            .dependency = "foundation",
            .artifact = "foundation",
        },
    };
}

pub fn fromArgs(b: *std.Build) Self {
    const implementation: Implementation = b.option(
        Implementation,
        "libc",
        "libc implementation to use",
    ) orelse .foundation;

    return Self.from(implementation);
}

pub fn dumpOptions(self: *const Self, options: *Options) void {
    _ = self;
    _ = options;
}
