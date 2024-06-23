//! Control instruction and data caches

const std = @import("std");
const hal = @import("../hal.zig");

inline fn DSB() void {
    asm volatile ("dsb 0xF");
}

inline fn ISB() void {
    asm volatile ("isb 0xF");
}

const SCB = @as(*hal.c.SCB_Type, @ptrFromInt(hal.c.SCB_BASE));

pub const i_cache = struct {
    pub fn enable() void {
        if ((SCB.CCR & hal.c.SCB_CCR_IC_Msk) != 0) {
            std.log.info("i-cache was already enabled", .{});
            return;
        }

        DSB();
        ISB();

        // invalidate i-cache
        SCB.ICIALLU = 0;

        DSB();
        ISB();

        // enable i-cache
        SCB.CCR |= hal.c.SCB_CCR_IC_Msk;

        DSB();
        ISB();

        std.log.debug("i-cache enabled", .{});
    }

    pub fn disable() void {
        DSB();
        ISB();

        // disable i-cache
        SCB.CCR &= ~hal.c.SCB_CCR_IC_Msk;

        // invalidate i-cache
        SCB.ICIALLU = 0;

        DSB();
        ISB();

        std.log.debug("i-cache disabled", .{});
    }
};
