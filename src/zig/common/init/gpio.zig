//! Initialize GPIO

const std = @import("std");
const hal = @import("../hal.zig");

pub fn init() void {
    hal.zig.clocks.enable.gpio(hal.c.GPION);
    hal.zig.clocks.enable.gpio(hal.c.GPIOO);
    hal.zig.clocks.enable.gpio(hal.c.GPIOP);
}
