const hal = @import("hal");

const Thread = @import("../Thread.zig");

pub fn lock() void {
    hal.assembly.disable_irq();
}

pub fn unlock() void {
    hal.assembly.enable_irq();
}

pub fn getTicks() Thread.Ticks {
    return hal.c.HAL_GetTick();
}