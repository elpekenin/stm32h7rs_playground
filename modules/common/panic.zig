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

fn leds_on() noreturn {
    inline for (hal.dk.LEDS) |led| {
        led.set(true);
    }

    deadlock();
}

fn cycle_leds() noreturn {
    inline for (hal.dk.LEDS) |led| {
        led.set(true);
    }

    while (true) {
        inline for (hal.dk.LEDS) |led| {
            led.toggle();
            hal.zig.timer.sleep(config.panic.time);
        }
    }
}

fn toggle_leds() noreturn {
    inline for (hal.dk.LEDS) |led| {
        led.set(true);
    }

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
        .LedsOn => leds_on(),
        .CycleLeds => cycle_leds(),
        .ToggleLeds => toggle_leds(),
    }
}
