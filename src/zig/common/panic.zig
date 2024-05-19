//! Panic function to be used on both bootloader- and application- level code
//! Thus, broken down into a reusable file under `common/`
//!
//! Note: The root of the project (aka: `app.zig` or `bootloader.zig`) has to import
//! and publicly re-export this function it to be applied.

const std = @import("std");

const rtt = @import("logging/rtt.zig");

const hal = @import("hal.zig");
const board = @import("board.zig");

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, ret_add: ?usize) noreturn {
    @setCold(true);

    rtt.log(.err, .panic,
        \\
        \\===============
        \\           msg: {s}
        \\   error trace: {any}
        \\return address: 0x{X:0>8}
        \\===============
    , .{ msg, error_return_trace, ret_add orelse 0 });

    inline for (board.LEDS, 0..) |pin, i| {
        const active = if (i <= 1) .High else .Low;

        if (pin.as_out(active)) |led| {
            led.set(true);
        }
    }

    while (true) {
        inline for (board.LEDS) |pin| {
            // .Low / .High ignored here, we just toggling
            if (pin.as_out(.Low)) |led| {
                led.toggle();
            }
            hal.HAL_Delay(100);
        }
    }
}
