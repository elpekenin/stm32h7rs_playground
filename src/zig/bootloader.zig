//! Second-stage bootloader, allowing to jump into STM-DFU,
//! or use UF2

const std = @import("std");

const stm_dfu = @import("bootloader/stm_dfu.zig");
const uf2 = @import("bootloader/uf2.zig");

pub const hal = @import("common/hal.zig");
// Please zig, do not garbage-collect this, we need it to export C funcs
comptime {
    _ = hal;
}

pub fn run() noreturn {
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

const logging = @import("common/logging.zig");
pub const std_options = logging.std_options;

const panic_ = @import("common/panic.zig");
pub const panic = panic_.panic;
