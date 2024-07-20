//! Second-stage bootloader, allowing to jump into STM-DFU,
//! or use UF2

const std = @import("std");
const logger = std.log.scoped(.bootloader);

const stm_dfu = @import("stm_dfu.zig");
const uf2 = @import("uf2.zig");

/// Actual entrypoint/logic of the bootloader
///
/// NOTE: It will never actually return an `i32` because all 3 "submain"
/// branches have `noreturn` logic, namely: jump into some other code.
pub fn run() !noreturn {
    // button pressed on boot => STM DFU
    if (stm_dfu.check()) {
        logger.debug("STM-DFU", .{});
        stm_dfu.bootloader();
    }

    // double press, or app code setting sentinel + reset => UF2 bootloader
    if (uf2.check()) {
        logger.debug("UF2 bootloader", .{});
        uf2.main();
    }

    // give chance for a double reset into bootloader
    uf2.chance();

    // jump to user code
    logger.debug("User code", .{});
    try uf2.app_jump();
}
