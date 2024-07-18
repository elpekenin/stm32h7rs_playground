const std = @import("std");

const hal = @import("hal");
const options = @import("options");

const PanicType = @import("panic_config.zig").PanicType;

pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    @setCold(true);

    std.log.err("Panic: {s}", .{msg});

    // endless rainbow
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
                    hal.c.HAL_Delay(options.panic_timer);
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
                hal.c.HAL_Delay(options.panic_timer);
            }
        },
    }
}
