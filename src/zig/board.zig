// Constants for DK board peripherals
const hal = @import("hal.zig");

pub const Pin = struct {
    port: *hal.GPIO_TypeDef,
    pin: u16,
};

pub const LD1 = Pin{
    .port = hal.GPIOO,
    .pin = hal.GPIO_PIN_1,
};

pub const LD2 = Pin{
    .port = hal.GPIOO,
    .pin = hal.GPIO_PIN_5,
};

pub const LD3 = Pin{
    .port = hal.GPIOM,
    .pin = hal.GPIO_PIN_2,
};

pub const LD4 = Pin{
    .port = hal.GPIOM,
    .pin = hal.GPIO_PIN_3,
};

pub const LEDS = .{ LD1, LD2, LD3, LD4 };

pub export fn togglePins() void {
    inline for (LEDS) |led| {
        hal.HAL_GPIO_TogglePin(led.port, led.pin);
    }
}
