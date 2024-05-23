//! UF2 logic to receive, write and execute user-land code
//! over USB

const std = @import("std");
const hal = @import("../common/hal.zig");
const jump = @import("jump.zig");

const ext_flash = @import("ext_flash.zig");
const ext_ram = @import("ext_ram.zig");

const UF2_FLAG = 0xBEBECAFE;
var uf2_var: u32 linksection(".preserve.0") = undefined;

const state = struct {
    var is_flash_init = false;
    var is_ram_init = false;
};

fn init_flash_once() !void {
    if (state.is_flash_init) {
        return;
    }

    try ext_flash.init();
    state.is_flash_init = true;
}

fn init_ram_once() void {
    if (state.is_ram_init) {
        return;
    }

    ext_ram.init();
    state.is_ram_init = true;
}

pub fn set_flag() void {
    uf2_var = UF2_FLAG;
}

pub fn clear_flag() void {
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

fn try_write_flash() void {
    init_flash_once() catch {
        std.debug.panic("ext_flash.init()", .{});
    };

    const write = [_]u8{0xAA} ** 256;
    ext_flash.write(0, &write) catch {
        ext_flash.print_error();
        std.debug.panic("ext_flash.write()", .{});
    };

    var read: [5]u8 = undefined;
    ext_flash.read(0, &read) catch {
        std.debug.panic("ext_flash.read()", .{});
    };

    std.log.debug("read {s}", .{read});
}

pub inline fn app_jump() noreturn {
    // try_write_flash();

    std.debug.panic("app_jump unimplemented", .{});
    // jump.to(ext_flash.BASE);
}

pub fn main() noreturn {
    // indicate that we are in bootloader
    const led = hal.zig.LD1.as_out(.High);
    led.set(true);

    while (true) {
        // expose USB MSC
        // wait for input, break on that scenario
    }

    // check family id
    // ... and start address
    // if correct, write it to flash

    // upon completion
    led.set(false);

    return app_jump();
}
