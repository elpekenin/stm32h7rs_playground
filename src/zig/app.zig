//! Just an user-land test program: blinking LEDs.

const bootstrap = @import("common/bootstrap.zig");
comptime {
    _ = bootstrap;
}

const hal = @import("common/hal.zig");
const board = @import("common/board.zig");

pub fn run() noreturn {
    while (true) {
        for (board.LEDS) |led| {
            led.as_out(.High).toggle();
        }
        hal.HAL_Delay(1000);
    }
}

const logging = @import("common/logging.zig");
pub const std_options = logging.std_options;

const panic_ = @import("common/panic.zig");
pub const panic = panic_.panic;
