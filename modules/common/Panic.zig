//! Override builtin Panic logic

const std = @import("std");
const StackTrace = std.builtin.StackTrace;
const logger = std.log.scoped(.panic);

const hal = @import("hal");
const config = @import("config");

fn deadlock() noreturn {
    while (true) {
        @breakpoint();
    }
}

fn on() void {
    for (hal.bsp.LEDS) |led| {
        led.set(true);
    }
}

fn cycle() noreturn {
    // sync LEDs
    on();

    while (true) {
        for (hal.bsp.LEDS) |led| {
            led.toggle();
            hal.zig.timer.sleep(.{ .milliseconds = config.panic.time });
        }
    }
}

fn toggle() noreturn {
    // sync LEDs
    on();

    while (true) {
        for (hal.bsp.LEDS) |led| {
            led.toggle();
        }
        hal.zig.timer.sleep(config.panic.time);
    }
}

pub fn call(msg: []const u8, _: ?*StackTrace, _: ?usize) noreturn {
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

pub fn inactiveUnionField(_: anytype, _: anytype) noreturn {
    @branchHint(.cold);
    call("inactiveUnionField", null, null);
}

pub const messages = std.debug.SimplePanic.messages;

pub fn outOfBounds(_: usize, _: usize) noreturn {
    @branchHint(.cold);
    call("outOfBounds", null, null);
}

pub fn sentinelMismatch(_: anytype, _: anytype) noreturn {
    @branchHint(.cold);
    call("sentinelMismatch", null, null);
}

pub fn startGreaterThanEnd(_: usize, _: usize) noreturn {
    @branchHint(.cold);
    call("startGreaterThanEnd", null, null);
}

pub fn unwrapError(_: ?*StackTrace, _: anyerror) noreturn {
    @branchHint(.cold);
    call("unwrapError", null, null);
}
