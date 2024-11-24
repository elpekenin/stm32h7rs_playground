//! Which program is being build
//!   - Bootloader
//!   - Application

const std = @import("std");
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
name: []const u8,

pub fn fromArgs(b: *std.Build) Self {
    const type_: Type = b.option(
        Type,
        "program",
        "Target program",
    ) orelse .bootloader;

    return Self{
        .type = type_,
        .name = Self.Type.name(type_),
    };
}
