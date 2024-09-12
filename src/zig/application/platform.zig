//! Write here the platform-dependant code specific to your use case.

const hal = @import("hal");

pub const Tick = u32;

pub fn lock() void {
    hal.assembly.disable_irq();
}

pub fn unlock() void {
    hal.assembly.enable_irq();
}

pub fn getTicks() Tick {
    return hal.c.HAL_GetTick();
}
