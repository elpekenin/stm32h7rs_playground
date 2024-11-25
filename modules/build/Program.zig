//! Which program is being build
//!   - Bootloader
//!   - Application

const std = @import("std");
const Build = std.Build;
const Options = Build.Step.Options;

const Self = @This();

const Type = enum {
    bootloader,
    application,

    fn name(self: Type) []const u8 {
        return switch (self) {
            .bootloader => "bootloader",
            .application => "application",
        };
    }
};

type: Type,

pub fn name(self: *const Self) []const u8 {
    return self.type.name();
}

pub fn fromArgs(b: *Build) Self {
    const type_: Type = b.option(
        Type,
        "program",
        "target program",
    ) orelse .bootloader;

    return Self{
        .type = type_,
    };
}

pub fn dumpOptions(self: *const Self, options: *Options) void {
    options.addOption([]const u8, "program", self.name());
}
