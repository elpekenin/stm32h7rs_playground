//! Constants for DK board peripherals, with tiny wrappers over
//! HAL functions, for ease of use

const hal = @import("hal.zig");

const digital = @import("hal_wrappers/digital.zig");
pub const BasePin = digital.BasePin;
pub const DigitalIn = digital.DigitalIn;
pub const DigitalOut = digital.DigitalOut;

const sd = @import("hal_wrappers/sd.zig");
pub const SDType = sd.SDType;

pub const BoardError = error{
    HalError,
    SDNotReady,
};

// Button
pub const USER = BasePin{
    .port = hal.GPIOC,
    .pin = hal.GPIO_PIN_13,
};

// LEDs
pub const LD1 = BasePin{
    .port = hal.GPIOO,
    .pin = hal.GPIO_PIN_1,
};

pub const LD2 = BasePin{
    .port = hal.GPIOO,
    .pin = hal.GPIO_PIN_5,
};

pub const LD3 = BasePin{
    .port = hal.GPIOM,
    .pin = hal.GPIO_PIN_2,
};

pub const LD4 = BasePin{
    .port = hal.GPIOM,
    .pin = hal.GPIO_PIN_3,
};

pub const LEDS = .{ LD1, LD2, LD3, LD4 };

// SD
pub const SD = SDType{ .instance = hal.SDMMC1, .detection = BasePin{
    .port = hal.GPIOM,
    .pin = hal.GPIO_PIN_14,
} };
