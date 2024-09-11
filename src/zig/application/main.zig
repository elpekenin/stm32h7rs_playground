const std = @import("std");

const hal = @import("hal");

const Scheduler = @import("os/Scheduler.zig");
const Thread = @import("os/Thread.zig");

var scheduler = Scheduler.init();

const LedThreadState = struct {
    pin: hal.zig.DigitalOut,
    delay: Thread.Ticks,
};

fn toggleFn(state: Thread.State) Thread.Result {
    const s: *LedThreadState = @alignCast(@ptrCast(state.private));

    s.pin.toggle();

    return Thread.sleep(s.delay);
}

pub fn main() noreturn {
    var state_1 = LedThreadState{
        .pin = hal.dk.LEDS[0],
        .delay = 200,
    };

    var state_2 = LedThreadState{
        .pin = hal.dk.LEDS[1],
        .delay = 500,
    };
    
    _ = scheduler.spawn(toggleFn, &state_1);
    _ = scheduler.spawn(toggleFn, &state_2);

    while (true) {
        scheduler.run();
    }
}
