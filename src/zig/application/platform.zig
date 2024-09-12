//! Write here the platform-dependant code specific to your use case.

const hal = @import("hal");

const asyncio = @import("asyncio.zig");

pub fn lock() void {
    hal.assembly.disable_irq();
}

pub fn unlock() void {
    hal.assembly.enable_irq();
}

pub fn getTicks() asyncio.Ticks {
    return hal.c.HAL_GetTick();
}
