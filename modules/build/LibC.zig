//! Which implementation of C's standard library is being used
const std = @import("std");
const Self = @This();

const Impl = enum {
    picolibc,
    foundation,
};

dependency: []const u8,
artifact: []const u8,

fn from(impl: Impl) Self {
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
    const impl: Impl = b.option(
        Impl,
        "libc",
        "LibC implementation to use",
    ) orelse .foundation;

    return Self.from(impl);
}
