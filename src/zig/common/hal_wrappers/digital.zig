//! Control GPIO as digital input or output

const std = @import("std");

const hal = @import("../hal.zig");

const clocks = @import("clocks.zig");

pub const Active = enum {
    Low,
    High,
};

pub const BasePin = struct {
    const Self = @This();

    port: *hal.GPIO_TypeDef,
    pin: u16,

    fn init(self: Self, mode: c_uint, pull: c_uint, speed: c_uint) !void {
        try clocks.enable.gpio(self.port);

        const GPIO_InitStruct: hal.GPIO_InitTypeDef = hal.GPIO_InitTypeDef{
            .Pin = self.pin,
            .Mode = mode,
            .Pull = pull,
            .Speed = speed,
        };

        hal.HAL_GPIO_Init(self.port, &GPIO_InitStruct);
    }

    /// Initialize a pin as output
    pub fn as_out(self: Self, active: Active) ?DigitalOut {
        const ret = DigitalOut{
            .base = self,
            .active = active,
        };

        ret.init() catch return null;

        return ret;
    }

    pub fn as_in(self: Self, active: Active) ?DigitalIn {
        const ret = DigitalIn{
            .base = self,
            .active = active,
        };

        ret.init() catch return null;

        return ret;
    }
};

pub const DigitalIn = struct {
    const Self = @This();

    base: BasePin,
    active: Active,

    /// Configure the pin
    fn init(self: Self) !void {
        const hal_pull = switch (self.active) {
            .Low => std.debug.panic("Unimplemented.", .{}),
            .High => hal.GPIO_PULLDOWN,
        };

        try self.base.init(hal.GPIO_MODE_INPUT, hal_pull, hal.GPIO_SPEED_FREQ_LOW);
    }

    /// Read input, takin into account the pull, to return "is button pressed"
    pub fn read(self: Self) bool {
        return switch (self.active) {
            .Low => std.debug.panic("Unimplemented.", .{}),
            .High => hal.HAL_GPIO_ReadPin(self.base.port, self.base.pin) == hal.GPIO_PIN_SET,
        };
    }
};

pub const DigitalOut = struct {
    const Self = @This();

    base: BasePin,
    active: Active,

    /// Configure the pin and set it at "off" state
    fn init(self: Self) !void {
        // TODO?: Something based on `self.active`
        try self.base.init(hal.GPIO_MODE_OUTPUT_PP, hal.GPIO_PULLUP, hal.GPIO_SPEED_FREQ_VERY_HIGH);
    }

    /// Set the **logical** output level (according to active-ness)
    pub fn set(self: Self, value: bool) void {
        const output = switch (self.active) {
            .Low => !value,
            .High => value,
        };

        const hal_out: c_uint = if (output) hal.GPIO_PIN_SET else hal.GPIO_PIN_RESET;

        hal.HAL_GPIO_WritePin(self.base.port, self.base.pin, hal_out);
    }

    /// Toggle the output voltage
    pub fn toggle(self: Self) void {
        hal.HAL_GPIO_TogglePin(self.base.port, self.base.pin);
    }
};
