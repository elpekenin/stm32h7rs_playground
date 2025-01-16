//! Which program is being build
//!   - Bootloader
//!   - Application

const std = @import("std");
const Build = std.Build;
const Options = Build.Step.Options;

const Config = @import("Config.zig");

const Self = @This();

const Type = enum {
    bootloader,
    application,
};

type: Type,

pub fn name(self: *const Self) []const u8 {
    return @tagName(self.type);
}

pub fn fromArgs(b: *Build) Self {
    const type_: Type = Config.option(
        b,
        Type,
        "program",
        "target program",
        .bootloader,
    );

    return Self{
        .type = type_,
    };
}

pub fn dumpOptions(self: *const Self, options: *Options) void {
    options.addOption([]const u8, "program", self.name());
}
