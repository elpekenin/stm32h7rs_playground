//! Control instruction and data caches

const std = @import("std");
const logger = std.log.scoped(.cache);

const hal = @import("../mod.zig");
const c = hal.c;
const SCB = hal.zig.SCB;

inline fn DSB() void {
    asm volatile ("dsb 0xF");
}

inline fn ISB() void {
    asm volatile ("isb 0xF");
}

pub const i_cache = struct {
    pub fn enable() !void {
        if ((SCB.CCR & c.SCB_CCR_IC_Msk) != 0) {
            // already enabled
            return;
        }

        DSB();
        ISB();

        // invalidate i-cache
        SCB.ICIALLU = 0;

        DSB();
        ISB();

        // enable i-cache
        SCB.CCR |= c.SCB_CCR_IC_Msk;

        DSB();
        ISB();

        logger.debug("i-cache enabled", .{});
    }

    pub fn disable() void {
        DSB();
        ISB();

        // disable i-cache
        SCB.CCR &= ~c.SCB_CCR_IC_Msk;

        // invalidate i-cache
        SCB.ICIALLU = 0;

        DSB();
        ISB();

        logger.debug("i-cache disabled", .{});
    }
};
