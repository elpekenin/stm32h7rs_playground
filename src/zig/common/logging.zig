//! Logging configuration to be used on both bootloader- and application- level code
//! Thus, broken down into a reusable file under `common/`
//!
//! Note: The root of the project (aka: `app.zig` or `bootloader.zig`) has to import
//! and publicly re-export `std_options`

const std = @import("std");

const fs = @import("logging/fs.zig");
const rtt = @import("logging/rtt.zig");

pub fn prefix(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
) []const u8 {
    return "[" ++ comptime level.asText() ++ "] (" ++ @tagName(scope) ++ "): ";
}

/// Expose logging functionality to C
/// We could use picolibc's printf implemenation but that pulls extra
/// code (thus, flash cost) without any real benefit/need
export fn zig_print(msg: [*:0]const u8) callconv(.C) void {
    std.log.info("C said: {s}", .{msg});
}

fn logFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    // if (@intFromEnum(level) < @intFromEnum(std.log.Level.info)) {
    //     // no .debug logging
    //     return;
    // }

    rtt.log(level, scope, format, args);
    // fs.log(level, scope, format, args);
}

pub const std_options = .{
    .log_level = .debug,
    .logFn = logFn,
};
