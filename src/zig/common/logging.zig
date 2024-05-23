//! Logging configuration to be used on both bootloader- and application- level code
//! Thus, broken down into a reusable file under `common/`
//!
//! Note: The root of the project (aka: `app.zig` or `bootloader.zig`) has to import
//! and publicly re-export `std_options`

const std = @import("std");
pub const fs = @import("logging/fs.zig");
pub const rtt = @import("logging/rtt.zig");

// TODO: Add time
pub fn prefix(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
) []const u8 {
    _ = scope;
    return "[" ++ comptime level.asText() ++ "]: ";
}

fn logFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    if (scope == .fatfs and level == .debug) {
        // FatFS is too verbose with debug messages ON, lets ignore them
        return;
    }

    rtt.log(level, scope, format, args);
    fs.log(level, scope, format, args);
}

pub const std_options = .{
    .log_level = .debug,
    .logFn = logFn,
};
