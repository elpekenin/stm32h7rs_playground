//! Override builtin panic handler

const std = @import("std");
const logger = std.log.scoped(.panic);

const hal = @import("hal");
const options = @import("options");

const PanicType = @import("panic_config.zig").PanicType;

/// Broken down to its own function so that we can show the indicator
/// when `main` exits (either return or error) instead of making
/// it `std.debug.panic` and cause a "panic" log message
pub fn indicator() noreturn {
    const panic_type: PanicType = @enumFromInt(options.panic_type);

    switch (panic_type) {
        .Nothing => while (true) {},
        .LedsOn => {
            inline for (hal.dk.LEDS) |led| {
                led.set(true);
            }

            while (true) {}
        },
        .CycleLeds => {
            inline for (hal.dk.LEDS) |led| {
                led.set(true);
            }

            while (true) {
                inline for (hal.dk.LEDS) |led| {
                    led.toggle();
                    hal.zig.timer.sleep(options.panic_timer);
                }
            }
        },
        .ToggleLeds => {
            inline for (hal.dk.LEDS) |led| {
                led.set(true);
            }

            while (true) {
                inline for (hal.dk.LEDS) |led| {
                    led.toggle();
                }
                hal.zig.timer.sleep(options.panic_timer);
            }
        },
    }
}

pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    @setCold(true);
    logger.err("{s}", .{msg});
    indicator();
}
