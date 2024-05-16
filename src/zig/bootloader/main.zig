// Main logic of the bootloader, allows:
//   - Jumping to STM DFU
//   - Jumping to UF2 bootloader
//   - Jumping to user code

const std = @import("std");

const hal = @import("../common/hal.zig");
const board = @import("../common/board.zig");

const stm_dfu = @import("stm_dfu.zig");
const uf2 = @import("uf2.zig");

pub fn run() noreturn {
    hal.early_init();

    // button pressed on boot => STM DFU
    if (stm_dfu.check()) {
        std.log.debug("Jumping to STM-DFU", .{});
        return stm_dfu.jump();
    }

    // double press, or app code setting sentinel + reset => UF2 bootloader
    if (uf2.check()) {
        std.log.debug("Jumping to UF2 bootloader", .{});
        uf2.clear_flag();
        return uf2.main();
    }

    // give chance for a double reset into bootloader
    uf2.set_flag();
    hal.HAL_Delay(500);
    uf2.clear_flag();

    // jump to user code
    std.log.debug("Jumping to application", .{});
    return uf2.app_jump();
}
