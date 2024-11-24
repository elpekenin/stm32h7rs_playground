//! Configuration for `panic()`'s behavior
//!   - What to do: nothing, turn all LEDs on, toggle all LEDs, ...
//!   - Timing for above's loops

const std = @import("std");
const Self = @This();

pub const Type = enum {
    Nothing,
    LedsOn,
    CycleLeds,
    ToggleLeds,
};
pub const Time = u32;

type: Type,
time: Time,

pub fn fromArgs(b: *std.Build) Self {
    const type_: Type = b.option(
        Type,
        "panic_type",
        "Control panic behavior",
    ) orelse .CycleLeds;

    const time: Time = b.option(
        Time,
        "panic_timer",
        "Control panic behavior",
    ) orelse 500;

    return Self{
        .type = type_,
        .time = time,
    };
}
