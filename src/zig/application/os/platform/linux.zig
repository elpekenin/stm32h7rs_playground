const std = @import("std");

const Thread = @import("../Thread.zig");

pub fn lock() void {}

pub fn unlock() void {}

pub fn getTicks() Thread.Ticks {
    return @intCast(std.time.timestamp() & 0xFFFFFFFF);
}