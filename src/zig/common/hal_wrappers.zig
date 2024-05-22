//! "Tiny" zig wrappers on top of STM HAL

const std = @import("std");
const hal = @import("hal.zig");

pub const clocks = @import("hal_wrappers/clocks.zig");
pub const digital = @import("hal_wrappers/digital.zig");
pub const irq = @import("hal_wrappers/irq.zig");
pub const sd = @import("hal_wrappers/sd.zig");
pub const usb = @import("hal_wrappers/usb.zig");

pub const Active = enum {
    Low,
    High,
};

pub const BasePin = struct {
    const Self = @This();

    port: *hal.c.GPIO_TypeDef,
    pin: u16,

    pub fn __init(self: Self, mode: c_uint, pull: c_uint, speed: c_uint) void {
        clocks.enable.gpio(self.port);

        var GPIO_InitStruct = std.mem.zeroes(hal.c.GPIO_InitTypeDef);
        GPIO_InitStruct = .{
            .Pin = self.pin,
            .Mode = mode,
            .Pull = pull,
            .Speed = speed,
        };
        hal.c.HAL_GPIO_Init(self.port, &GPIO_InitStruct);
    }

    /// Initialize a pin as output
    pub fn as_out(self: Self, active: Active) digital.DigitalOut {
        const ret = digital.DigitalOut{
            .base = self,
            .active = active,
        };

        ret.__init();

        return ret;
    }

    pub fn as_in(self: Self, active: Active) digital.DigitalIn {
        const ret = digital.DigitalIn{
            .base = self,
            .active = active,
        };

        ret.__init();

        return ret;
    }
};

// Constants for DK board
// Constants for DK board peripherals, with tiny wrappers over
// HAL functions, for ease of use

/// Var because .hsd will be changed
pub var SD = sd.SDType.new(hal.c.SDMMC1, BasePin{
    .port = hal.c.GPIOM,
    .pin = hal.c.GPIO_PIN_14,
});

pub const BoardError = error{
    HalError,
    SDNotReady,
};

// Button
pub const USER = BasePin{
    .port = hal.c.GPIOC,
    .pin = hal.c.GPIO_PIN_13,
};

// LEDs
pub const LD1 = BasePin{
    .port = hal.c.GPIOO,
    .pin = hal.c.GPIO_PIN_1,
};

pub const LD2 = BasePin{
    .port = hal.c.GPIOO,
    .pin = hal.c.GPIO_PIN_5,
};

pub const LD3 = BasePin{
    .port = hal.c.GPIOM,
    .pin = hal.c.GPIO_PIN_2,
};

pub const LD4 = BasePin{
    .port = hal.c.GPIOM,
    .pin = hal.c.GPIO_PIN_3,
};

pub const LEDS = .{ LD1, LD2, LD3, LD4 };
