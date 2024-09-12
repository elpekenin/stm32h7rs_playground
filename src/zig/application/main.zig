const std = @import("std");

const hal = @import("hal");

const asyncio = @import("asyncio.zig");

const LedThreadState = struct {
    pin: hal.zig.DigitalOut,
    delay: asyncio.Tick,
};

fn toggleFn(state: asyncio.State) asyncio.Result {
    const s: *LedThreadState = @alignCast(@ptrCast(state.private));

    s.pin.toggle();

    return asyncio.sleep(s.delay);
}

pub fn main() noreturn {
    var state_1 = LedThreadState{
        .pin = hal.dk.LEDS[0],
        .delay = 200,
    };

    var state_2 = LedThreadState{
        .pin = hal.dk.LEDS[1],
        .delay = 400,
    };
    
    _ = asyncio.spawn(toggleFn, &state_1);
    _ = asyncio.spawn(toggleFn, &state_2);

    while (true) {
        asyncio.run();
    }
}
