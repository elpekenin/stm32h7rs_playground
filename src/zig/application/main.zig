const std = @import("std");

const hal = @import("hal");

const asyncio = @import("asyncio.zig");

pub const log_scope_levels = &.{
    std.log.ScopeLevel{
        .scope = .asyncio,
        .level = .info,
    },
};

const Blinky = struct {
    const Ret = asyncio.Generator(void, void, u32);

    const Args = struct {
        pin: hal.zig.DigitalOut,
        delay: asyncio.Time,
        sleep: asyncio.Sleep = .{ .args = 0, .state = .Completed },
    };

    fn bar(args: *Args) Ret {
        if (args.sleep.state == .Completed) {
            args.pin.toggle();
            args.sleep = asyncio.sleep(args.delay);
            return Ret.yield({});
        }

        // can we make this prettier?
        _ = args.sleep.next();
        return Ret.yield({});
    }
};

pub fn main() noreturn {
    var state_1: Blinky.Args = .{
        .pin = hal.dk.LEDS[0],
        .delay = .{ .ms = 200 },
    };

    var state_2: Blinky.Args = .{
        .pin = hal.dk.LEDS[1],
        .delay = .{ .ms = 400 },
    };

    var coro_1 = asyncio.Coroutine.from(Blinky.bar, &state_1);
    var coro_2 = asyncio.Coroutine.from(Blinky.bar, &state_2);

    while (true) {
        _ = coro_1.next();
        _ = coro_2.next();
    }
}
