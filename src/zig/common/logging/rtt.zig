//! Logging backend for the RTT protocol

const std = @import("std");

const rtt = @import("rtt");

const hal = @import("../hal.zig");

fn time_getter() rtt.Time {
    return rtt.Time{ .seconds = hal.HAL_GetTick(), .microseconds = 0 };
}

fn init() void {
    rtt.config_up_buffer(.{
        .index = 0,
        .name = "debug",
        .mode = .BlockIfFifoFull,
    });

    rtt.set_time_getter(time_getter);
}

pub fn log(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const state = struct {
        var init = false;
    };

    if (!state.init) {
        init();
        state.init = true;
    }

    rtt.logFn(level, scope, format, args);
}
