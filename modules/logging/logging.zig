//! Logging configuration to be used on both bootloader- and application- level code
//! Thus, broken down into a reusable file under `common/`
//!
//! Note: The root of the project (aka: `app.zig` or `bootloader.zig`) has to import
//! and publicly re-export `std_options`

const std = @import("std");
pub const fs = @import("backends/fs.zig");
pub const rtt = @import("backends/rtt.zig");

pub fn logFn(
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

/// Name that STM HAL expects to find
export fn assert_failed(file: [*:0]const u8, line: u32) callconv(.C) void {
    std.log.err("assert failed {s}:{}", .{ file, line });
}
