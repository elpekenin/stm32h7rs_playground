//! Configure the clocks in the MCU
//!
//! Eg, to enable GPIO ports.

const std = @import("std");
const hal = @import("../hal.zig");

var _tmpreg: u32 = 0;
const tmpreg: *volatile u32 = &_tmpreg;

const Clock = struct {
    const Self = @This();

    register: *volatile u32,
    bitmask: u32,

    pub fn enable(self: Self) void {
        self.register.* |= self.bitmask;
        tmpreg.* = self.register.*;
    }

    pub fn disable(self: Self) void {
        self.register.* &= ~self.bitmask;
        tmpreg.* = self.register.*;
    }
};

const RCC: *hal.c.RCC_TypeDef = @ptrFromInt(hal.c.RCC_BASE);
const AHB4ENR = &RCC.AHB4ENR;
const AHB5ENR = &RCC.AHB5ENR;
const APB1ENR1 = &RCC.APB1ENR1;
const APB4ENR = &RCC.APB4ENR;

pub const GPIOA: Clock = .{
    .register = AHB4ENR,
    .bitmask = hal.c.RCC_AHB4ENR_GPIOAEN,
};

pub const GPIOB: Clock = .{
    .register = AHB4ENR,
    .bitmask = hal.c.RCC_AHB4ENR_GPIOBEN,
};

pub const GPIOC: Clock = .{
    .register = AHB4ENR,
    .bitmask = hal.c.RCC_AHB4ENR_GPIOCEN,
};

pub const GPIOD: Clock = .{
    .register = AHB4ENR,
    .bitmask = hal.c.RCC_AHB4ENR_GPIODEN,
};

pub const GPIOE: Clock = .{
    .register = AHB4ENR,
    .bitmask = hal.c.RCC_AHB4ENR_GPIOEEN,
};

pub const GPIOF: Clock = .{
    .register = AHB4ENR,
    .bitmask = hal.c.RCC_AHB4ENR_GPIOFEN,
};

pub const GPIOG: Clock = .{
    .register = AHB4ENR,
    .bitmask = hal.c.RCC_AHB4ENR_GPIOGEN,
};

pub const GPIOH: Clock = .{
    .register = AHB4ENR,
    .bitmask = hal.c.RCC_AHB4ENR_GPIOHEN,
};

pub const GPIOM: Clock = .{
    .register = AHB4ENR,
    .bitmask = hal.c.RCC_AHB4ENR_GPIOMEN,
};

pub const GPION: Clock = .{
    .register = AHB4ENR,
    .bitmask = hal.c.RCC_AHB4ENR_GPIONEN,
};

pub const GPIOO: Clock = .{
    .register = AHB4ENR,
    .bitmask = hal.c.RCC_AHB4ENR_GPIOOEN,
};

pub const GPIOP: Clock = .{
    .register = AHB4ENR,
    .bitmask = hal.c.RCC_AHB4ENR_GPIOPEN,
};

pub const SDMMC1: Clock = .{
    .register = AHB5ENR,
    .bitmask = hal.c.RCC_AHB5ENR_SDMMC1EN,
};

pub const XSPIM: Clock = .{
    .register = AHB5ENR,
    .bitmask = hal.c.RCC_AHB5ENR_XSPIMEN,
};

pub const XSPI1: Clock = .{
    .register = AHB5ENR,
    .bitmask = hal.c.RCC_AHB5ENR_XSPI1EN,
};

pub const XSPI2: Clock = .{
    .register = AHB5ENR,
    .bitmask = hal.c.RCC_AHB5ENR_XSPI2EN,
};

pub const SBS: Clock = .{
    .register = APB4ENR,
    .bitmask = hal.c.RCC_APB4ENR_SBSEN,
};

pub const TIM6: Clock = .{
    .register = APB1ENR1,
    .bitmask = hal.c.RCC_APB1ENR1_TIM6EN,
};

fn port_to_clock(port: *hal.c.GPIO_TypeDef) Clock {
    return switch (port) {
        hal.c.GPIOA => GPIOA,
        hal.c.GPIOB => GPIOB,
        hal.c.GPIOC => GPIOC,
        hal.c.GPIOD => GPIOD,
        hal.c.GPIOE => GPIOE,
        hal.c.GPIOF => GPIOF,
        hal.c.GPIOG => GPIOG,
        hal.c.GPIOH => GPIOH,
        hal.c.GPIOM => GPIOM,
        hal.c.GPION => GPION,
        hal.c.GPIOO => GPIOO,
        hal.c.GPIOP => GPIOP,

        else => unreachable,
    };
}

/// Convenience to access GPIO sructs by the pointer to the port
pub fn enable_gpio(port: *hal.c.GPIO_TypeDef) void {
    port_to_clock(port).enable();
}

/// Convenience to access GPIO sructs by the pointer to the port
pub fn disable_gpio(port: *hal.c.GPIO_TypeDef) void {
    port_to_clock(port).disable();
}

/// Configure RCC
pub fn config(rcc_config: *hal.c.RCC_OscInitTypeDef) !void {
    if (hal.c.HAL_RCC_OscConfig(rcc_config) != hal.c.HAL_OK) {
        std.debug.panic("HAL_RCC_OscConfig", .{});
    }
}
