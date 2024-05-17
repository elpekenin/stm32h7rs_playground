const std = @import("std");

const fs = @import("logging/fs.zig");
const rtt = @import("logging/rtt.zig");

pub fn prefix(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
) []const u8 {
    return "[" ++ comptime level.asText() ++ "] (" ++ @tagName(scope) ++ "): ";
}

pub fn log(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    if (@intFromEnum(level) < @intFromEnum(std.log.Level.info)) {
        // no .debug logging
        return;
    }

    rtt.log(level, scope, format, args);
    fs.log(level, scope, format, args);
}
