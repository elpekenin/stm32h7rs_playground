//! Control GPIO as digital input or output

const std = @import("std");

const hal = @import("../hal.zig");

const clocks = @import("clocks.zig");

pub const DigitalIn = struct {
    const Self = @This();

    base: hal.zig.BasePin,
    active: hal.zig.Active,

    /// Configure the pin
    pub fn __init(self: Self) void {
        const hal_pull = switch (self.active) {
            .Low => hal.c.GPIO_PULLUP,
            .High => hal.c.GPIO_PULLDOWN,
        };

        self.base.__init(hal.c.GPIO_MODE_INPUT, hal_pull, hal.c.GPIO_SPEED_FREQ_LOW);
    }

    /// Read input, takin into account the pull, to return "is button pressed"
    pub fn read(self: Self) bool {
        const check = switch (self.active) {
            .Low => hal.c.GPIO_PIN_RESET,
            .High => hal.c.GPIO_PIN_SET,
        };

        return hal.c.HAL_GPIO_ReadPin(self.base.port, self.base.pin) == check;
    }
};

pub const DigitalOut = struct {
    const Self = @This();

    base: hal.zig.BasePin,
    active: hal.zig.Active,

    /// Configure the pin and set it at "off" state
    pub fn __init(self: Self) void {
        // TODO?: Something based on `self.active`
        self.base.__init(hal.c.GPIO_MODE_OUTPUT_PP, hal.c.GPIO_PULLUP, hal.c.GPIO_SPEED_FREQ_VERY_HIGH);
    }

    /// Set the **logical** output level (according to active-ness)
    pub fn set(self: Self, value: bool) void {
        const output = switch (self.active) {
            .Low => !value,
            .High => value,
        };

        const hal_out: c_uint = if (output) hal.c.GPIO_PIN_SET else hal.c.GPIO_PIN_RESET;

        hal.c.HAL_GPIO_WritePin(self.base.port, self.base.pin, hal_out);
    }

    /// Toggle the output voltage
    pub fn toggle(self: Self) void {
        hal.c.HAL_GPIO_TogglePin(self.base.port, self.base.pin);
    }
};
