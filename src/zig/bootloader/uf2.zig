//! UF2 logic to receive, write and execute user-land code
//! over USB

const std = @import("std");

const hal = @import("../common/hal.zig");
const board = @import("../common/board.zig");

const ext_flash = @import("ext_flash.zig");
const _jump = @import("jump.zig").to;

const UF2_FLAG = 0xBEBECAFE;
var uf2_var: u32 linksection(".preserve.0") = undefined;

pub fn set_flag() void {
    uf2_var = UF2_FLAG;
}

pub fn clear_flag() void {
    uf2_var = 0;
}

pub fn chance() void {
    set_flag();
    hal.HAL_Delay(500);
    clear_flag();
}

pub fn check() bool {
    return uf2_var == UF2_FLAG;
}

pub inline fn app_jump() noreturn {
    std.debug.panic("Unimplemented.", .{});
    // _jump(ext_flash.BASE);
}

pub fn main() noreturn {
    // indicate that we are in bootloader
    const maybe_led = board.LD1.as_out(.High);
    if (maybe_led) |led| {
        led.set(true);
    }

    while (true) {
        // expose USB MSC
        // wait for input, break on that scenario
    }

    // check family id
    // ... and start address
    // if correct, write it to flash

    // upon completion
    if (maybe_led) |led| {
        led.set(false);
    }
    return app_jump();
}
