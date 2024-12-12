//! UF2 logic to receive, write and execute user-land code
//! over USB

const std = @import("std");
const logger = std.log.scoped(.uf2);

const hal = @import("hal");
const jump = @import("jump.zig");

const mx66 = @import("mx66");

/// Green LED
const INDICATOR = hal.bsp.LEDS[0];

pub const FLASH_BASE = 0x70000000;
pub const FLASH_SIZE = 0x08000000;

const Flag = struct {
    const MAGIC = 0xBEBECAFE;

    var value: u32 linksection(".preserve.0") = undefined;

    fn set() void {
        value = MAGIC;
    }

    fn clear() void {
        value = 0;
    }

    fn chance() void {
        set();
        hal.zig.timer.sleep(.{ .milliseconds = 500 });
        clear();
    }

    fn check() bool {
        return value == MAGIC;
    }
};

fn flashTest() !i32 {
    var flash = try mx66.new(.{
        .protocol = .OPI,
        .rate = .DTR,
    });

    const SIZE = 10;

    const write_buf = [_]u8{0xAA} ** SIZE;
    try flash.write(0, &write_buf);

    var read_buf = [_]u8{0xFF} ** SIZE;
    try flash.read(0, &read_buf);

    return 0;
}

pub const checkJump = Flag.check;
pub const doubleResetChance = Flag.chance;

pub fn jumpToUserCode() !noreturn {
    // fails, for now.
    _ = flashTest() catch {};

    jump.to(FLASH_BASE);
}

pub fn loop() noreturn {
    Flag.clear();

    INDICATOR.set(true);
    hal.zig.timer.sleep(.{ .milliseconds = 500 });
    INDICATOR.set(false);

    while (true) {
        // expose USB MSC
        // wait for input, break on that scenario
    }

    // check family id
    // ... and start address
    // if correct, write it to flash

    jumpToUserCode();
}
