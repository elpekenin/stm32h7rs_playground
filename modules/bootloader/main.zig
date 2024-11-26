//! Second-stage bootloader, allowing to jump into STM-DFU,
//! or use UF2

const std = @import("std");
const logger = std.log.scoped(.bootloader);

const dfu = @import("dfu.zig");
const uf2 = @import("uf2.zig");

/// Actual entrypoint/logic of the bootloader
pub fn main() !noreturn {
    // button pressed on boot => STM DFU
    if (dfu.checkJump()) {
        logger.debug("STM-DFU", .{});
        dfu.jumpToBootloader();
    }

    // UF2 bootloader's logic is triggeren after:
    //   a) quick double reset
    //   b) user-level code setting sentinel + resetting
    if (uf2.checkJump()) {
        logger.debug("UF2 bootloader", .{});
        uf2.main();
    }

    // give chance for a double reset into bootloader
    uf2.doubleResetChance();

    // jump to user code
    logger.debug("User code", .{});
    try uf2.jumpToUserCode();
}
