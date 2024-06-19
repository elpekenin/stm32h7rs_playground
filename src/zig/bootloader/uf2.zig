//! UF2 logic to receive, write and execute user-land code
//! over USB

const std = @import("std");
const hal = @import("../common/hal.zig");
const jump = @import("jump.zig");

const ext_flash = @import("mx66uw1g45g.zig");

const UF2_FLAG = 0xBEBECAFE;
var uf2_var: u32 linksection(".preserve.0") = undefined;

inline fn set_flag() void {
    uf2_var = UF2_FLAG;
}

inline fn clear_flag() void {
    uf2_var = 0;
}

pub fn chance() void {
    set_flag();
    hal.c.HAL_Delay(500);
    clear_flag();
}

pub fn check() bool {
    return uf2_var == UF2_FLAG;
}

fn flash_test() !void {
    try ext_flash.init();

    const write_buf = [_]u8{'F'} ** 128;
    try ext_flash.write(0, &write_buf);
    std.log.info("written to flash", .{});

    var read_buf: [write_buf.len]u8 = undefined;
    try ext_flash.read(0, &read_buf);
    std.log.info("read: {any}", .{read_buf});
}

pub fn app_jump() noreturn {
    flash_test() catch {
        std.debug.panic("testing external flash", .{});
    };

    std.debug.panic("app_jump unimplemented", .{});
    // jump.to(ext_flash.BASE);
}

pub fn main() noreturn {
    clear_flag();

    // indicate that we are in bootloader
    const led = hal.dk.LEDS[0].as_out(.High);
    led.set(true);
    hal.c.HAL_Delay(500);
    led.set(false);

    while (true) {
        // expose USB MSC
        // wait for input, break on that scenario
    }

    // check family id
    // ... and start address
    // if correct, write it to flash

    return app_jump();
}
