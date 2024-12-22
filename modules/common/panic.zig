//! Override builtin panic handler

const std = @import("std");
const logger = std.log.scoped(.panic);

const hal = @import("hal");
const config = @import("config");

fn deadlock() noreturn {
    while (true) {
        @breakpoint();
    }
}

fn on() void {
    inline for (hal.bsp.LEDS) |led| {
        led.set(true);
    }
}

fn cycle() noreturn {
    // sync LEDs
    on();

    while (true) {
        inline for (hal.bsp.LEDS) |led| {
            led.toggle();
            hal.zig.timer.sleep(.{ .milliseconds = config.panic.time });
        }
    }
}

fn toggle() noreturn {
    // sync LEDs
    on();

    while (true) {
        inline for (hal.bsp.LEDS) |led| {
            led.toggle();
        }
        hal.zig.timer.sleep(config.panic.time);
    }
}

pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    @branchHint(.cold);

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
