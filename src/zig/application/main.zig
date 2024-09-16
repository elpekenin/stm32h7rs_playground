const std = @import("std");

const hal = @import("hal");

const asyncio = @import("playground.zig");

const Foo = struct {
    const Ret = asyncio.Generator(void, void, u32);

    const Args = struct {
        pin: hal.zig.DigitalOut,
        delay: asyncio.Time,
        sleep: ?*asyncio.Sleep = null,
    };

    fn bar(args: *Args) Ret {
        args.pin.toggle();

        if (args.sleep == null) {
            var sleep = asyncio.sleep(args.delay);
            args.sleep = &sleep;
        }

        const sleep = args.sleep.?;
        if (sleep.state != .Completed) {
            // bleh...
            _ = sleep.next();
            return Ret.yield({});
        }

        args.sleep = null;

        return Ret.yield({});
    }
};

pub fn main() noreturn {
    var state_1 = Foo.Args{
        .pin = hal.dk.LEDS[0],
        .delay = .{ .ms = 200 },
    };

    var state_2 = Foo.Args{
        .pin = hal.dk.LEDS[1],
        .delay = .{ .ms = 400 },
    };

    var coro_1 = asyncio.Coroutine.from(Foo.bar, &state_1);
    var coro_2 = asyncio.Coroutine.from(Foo.bar, &state_2);

    while (true) {
        _ = coro_1.next();
        _ = coro_2.next();
    }
}
