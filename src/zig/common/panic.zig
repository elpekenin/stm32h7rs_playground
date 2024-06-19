//! Panic function to be used on both bootloader- and application- level code
//! Thus, broken down into a reusable file under `common/`
//!
//! Note: The root of the project (aka: `app.zig` or `bootloader.zig`) has to import
//! and publicly re-export this function it to be applied.

const std = @import("std");
const hal = @import("hal.zig");
const logging = @import("logging.zig");

/// Function used by STM HAL on panics, expose it as a way of executing zig's panic
export fn Error_Handler() callconv(.C) noreturn {
    std.debug.panic("[C] HAL Panic", .{});
}

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, ret_add: ?usize) noreturn {
    @setCold(true);

    logging.fs.log(.err, .panic, "{s}", .{msg});
    logging.rtt.log(.err, .panic,
        \\
        \\   msg: {s}
        \\ trace: {any}
        \\return: 0x{X:0>8}
    , .{ msg, error_return_trace, ret_add orelse 0 });

    inline for (hal.dk.LEDS, 0..) |led, i| {
        hal.zig.clocks.enable_gpio(led.port);
        const active = if (i <= 1) .High else .Low;
        led.as_out(active).set(true);
    }

    while (true) {
        inline for (hal.dk.LEDS) |led| {
            // .Low / .High ignored here, we just toggling
            led.as_out(.Low).toggle();
            hal.c.HAL_Delay(100);
        }
    }
}
