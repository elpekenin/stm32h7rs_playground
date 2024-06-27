//! Second-stage bootloader, allowing to jump into STM-DFU,
//! or use UF2

const std = @import("std");

const stm_dfu = @import("stm_dfu.zig");
const uf2 = @import("uf2.zig");

/// Actual entrypoint/logic of the bootloader
///
/// NOTE: It will never actually return an `i32` because all 3 "submain"
/// branches have `noreturn` logic, namely: jump into some other code.
pub fn run() !i32 {
    // button pressed on boot => STM DFU
    if (stm_dfu.check()) {
        std.log.debug("Running STM-DFU", .{});
        return stm_dfu.bootloader();
    }

    // double press, or app code setting sentinel + reset => UF2 bootloader
    if (uf2.check()) {
        std.log.debug("Running UF2 bootloader", .{});
        return uf2.main();
    }

    // give chance for a double reset into bootloader
    uf2.chance();

    // jump to user code
    std.log.debug("Running user code", .{});
    return uf2.app_jump();
}
