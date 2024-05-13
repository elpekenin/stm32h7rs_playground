// Main logic of the bootloader, allows:
//   - Jumping to STM DFU
//   - Jumping to UF2 bootloader
//   - Jumping to user code

const hal = @import("../common/hal.zig");

const stm_dfu = @import("stm_dfu.zig");
const uf2 = @import("uf2.zig");

pub fn run() noreturn {
    hal.early_init();

    // button pressed on boot => STM DFU
    if (stm_dfu.check()) {
        return stm_dfu.jump();
    }

    // double press, or app code setting sentinel + reset => UF2 bootloader
    if (uf2.check()) {
        uf2.clear_flag();
        return uf2.main();
    }

    // give chance for a double reset into bootloader
    uf2.set_flag();
    hal.HAL_Delay(500);
    uf2.clear_flag();

    // jump to user code
    return uf2.app_jump();
}
