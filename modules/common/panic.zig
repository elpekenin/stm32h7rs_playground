//! Override builtin panic handler

const std = @import("std");
const logger = std.log.scoped(.panic);

const hal = @import("hal");
const config = @import("build_config");

const Panic = @TypeOf(config.panic);

fn deadlock() noreturn {
    while (true) {
        @breakpoint();
    }
}

fn on() void {
    inline for (hal.dk.LEDS) |led| {
        led.set(true);
    }
}

fn cycle() noreturn {
    // sync LEDs
    on();

    while (true) {
        inline for (hal.dk.LEDS) |led| {
            led.toggle();
            hal.zig.timer.sleep(config.panic.time);
        }
    }
}

fn toggle() noreturn {
    // sync LEDs
    on();

    while (true) {
        inline for (hal.dk.LEDS) |led| {
            led.toggle();
        }
        hal.zig.timer.sleep(config.panic.time);
    }
}

pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    @setCold(true);

    logger.err("{s}", .{msg});
    switch (config.panic.type) {
        .Nothing => deadlock(),
        .LedsOn => {
            on();
            deadlock();
        },
        .CycleLeds => cycle(),
        .ToggleLeds => toggle(),
    }
}
