//! Second-stage bootloader, allowing to jump into STM-DFU,
//! or use UF2

const std = @import("std");
const hal = @import("common/hal.zig");
const stm_dfu = @import("bootloader/stm_dfu.zig");
const uf2 = @import("bootloader/uf2.zig");

pub const std_options = @import("common/logging.zig").std_options;
pub const panic = @import("common/panic.zig").panic;

/// Arguments' signature doesn't really matter as picolibc will be
/// doing `int ret = main(0, NULL)`
///
/// But, just for reference, according to C11, `argv` should be a
/// non-const, null-terminated list of null-terminated strings.
///
/// Our main consists on doing some initial setup of HAL compontents to
/// then jump into application code.
export fn main(argc: i32, argv: [*c][*:0]u8) callconv(.C) i32 {
    _ = argc;
    _ = argv;

    const ret = hal.c.HAL_Init();
    if (ret != hal.c.HAL_OK) {
        std.debug.panic("HAL_Init", .{});
    }

    hal.zig.init.clocks();
    hal.c.SystemCoreClockUpdate();

    // for LEDs to work in panic handler, regardless of when that happens
    // but doing it earlier than this might be a bad idea as previous setup
    // has not be done yet (?)
    hal.zig.clocks.GPIOM.enable();
    hal.zig.clocks.GPIOO.enable();

    // warning if SD not available
    if (!hal.zig.sd.is_connected()) {
        std.log.warn("404 SD not found", .{});
    }

    run();
}

/// Actual entrypoint/logic of the bootloader
fn run() noreturn {
    // button pressed on boot => STM DFU
    if (stm_dfu.check()) {
        std.log.debug("Running STM-DFU", .{});
        return stm_dfu.jump();
    }

    // double press, or app code setting sentinel + reset => UF2 bootloader
    if (uf2.check()) {
        std.log.debug("Running UF2 bootloader", .{});
        uf2.clear_flag();
        return uf2.main();
    }

    // give chance for a double reset into bootloader
    uf2.chance();

    // jump to user code
    std.log.debug("Running user code", .{});

    return uf2.app_jump();
}
