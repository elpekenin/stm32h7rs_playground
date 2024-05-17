const std = @import("std");

const rtt = @import("rtt");

fn init() void {
    rtt.config_up_buffer(.{
        .index = 0,
        .name = "debug",
        .mode = .BlockIfFifoFull,
    });
}

var initialized = false;

pub fn log(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    if (!initialized) {
        init();
        initialized = true;
    }

    rtt.logFn(level, scope, format, args);
}
