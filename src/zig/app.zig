//! Just an user-land test program: blinking LEDs.

const hal = @import("common/hal.zig");

pub fn run() noreturn {
    while (true) {
        for (hal.zig.LEDS) |led| {
            led.as_out(.High).toggle();
        }
        hal.HAL_Delay(1000);
    }
}

const logging = @import("common/logging.zig");
pub const std_options = logging.std_options;

const panic_ = @import("common/panic.zig");
pub const panic = panic_.panic;
