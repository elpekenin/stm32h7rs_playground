//! Overall configuration of a build

const std = @import("std");

const Self = @This();

const LibC = @import("LibC.zig");
const Hal = @import("Hal.zig");
const Panic = @import("Panic.zig");
const Program = @import("Program.zig");

libc: LibC,
hal: Hal,
panic: Panic,
program: Program,

pub fn fromArgs(b: *std.Build) Self {
    var self: Self = undefined;

    inline for (@typeInfo(Self).Struct.fields) |field| {
        @field(self, field.name) = field.type.fromArgs(b);
    }

    return self;
}

pub fn addOptions(self: *const Self, b: *std.Build) *std.Build.Step.Options {
    const options = b.addOptions();

    inline for (@typeInfo(Self).Struct.fields) |field| {
        options.addOption(field.type, field.name, @field(self, field.name));
    }

    return options;
}
