//! Configure the clocks in the MCU
//!
//! Eg, to enable GPIO ports.

const std = @import("std");
const hal = @import("../hal.zig");
const c = hal.c;
const RCC = hal.zig.peripherals.RCC;

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

const AHB4ENR = &RCC.AHB4ENR;
const AHB5ENR = &RCC.AHB5ENR;
const APB1ENR1 = &RCC.APB1ENR1;
const APB4ENR = &RCC.APB4ENR;

pub const GPIOA: Clock = .{
    .register = AHB4ENR,
    .bitmask = c.RCC_AHB4ENR_GPIOAEN,
};

pub const GPIOB: Clock = .{
    .register = AHB4ENR,
    .bitmask = c.RCC_AHB4ENR_GPIOBEN,
};

pub const GPIOC: Clock = .{
    .register = AHB4ENR,
    .bitmask = c.RCC_AHB4ENR_GPIOCEN,
};

pub const GPIOD: Clock = .{
    .register = AHB4ENR,
    .bitmask = c.RCC_AHB4ENR_GPIODEN,
};

pub const GPIOE: Clock = .{
    .register = AHB4ENR,
    .bitmask = c.RCC_AHB4ENR_GPIOEEN,
};

pub const GPIOF: Clock = .{
    .register = AHB4ENR,
    .bitmask = c.RCC_AHB4ENR_GPIOFEN,
};

pub const GPIOG: Clock = .{
    .register = AHB4ENR,
    .bitmask = c.RCC_AHB4ENR_GPIOGEN,
};

pub const GPIOH: Clock = .{
    .register = AHB4ENR,
    .bitmask = c.RCC_AHB4ENR_GPIOHEN,
};

pub const GPIOM: Clock = .{
    .register = AHB4ENR,
    .bitmask = c.RCC_AHB4ENR_GPIOMEN,
};

pub const GPION: Clock = .{
    .register = AHB4ENR,
    .bitmask = c.RCC_AHB4ENR_GPIONEN,
};

pub const GPIOO: Clock = .{
    .register = AHB4ENR,
    .bitmask = c.RCC_AHB4ENR_GPIOOEN,
};

pub const GPIOP: Clock = .{
    .register = AHB4ENR,
    .bitmask = c.RCC_AHB4ENR_GPIOPEN,
};

pub const SDMMC1: Clock = .{
    .register = AHB5ENR,
    .bitmask = c.RCC_AHB5ENR_SDMMC1EN,
};

pub const XSPIM: Clock = .{
    .register = AHB5ENR,
    .bitmask = c.RCC_AHB5ENR_XSPIMEN,
};

pub const XSPI1: Clock = .{
    .register = AHB5ENR,
    .bitmask = c.RCC_AHB5ENR_XSPI1EN,
};

pub const XSPI2: Clock = .{
    .register = AHB5ENR,
    .bitmask = c.RCC_AHB5ENR_XSPI2EN,
};

pub const SBS: Clock = .{
    .register = APB4ENR,
    .bitmask = c.RCC_APB4ENR_SBSEN,
};

pub const TIM6: Clock = .{
    .register = APB1ENR1,
    .bitmask = c.RCC_APB1ENR1_TIM6EN,
};

fn port_to_clock(port: *c.GPIO_TypeDef) Clock {
    return switch (port) {
        c.GPIOA => GPIOA,
        c.GPIOB => GPIOB,
        c.GPIOC => GPIOC,
        c.GPIOD => GPIOD,
        c.GPIOE => GPIOE,
        c.GPIOF => GPIOF,
        c.GPIOG => GPIOG,
        c.GPIOH => GPIOH,
        c.GPIOM => GPIOM,
        c.GPION => GPION,
        c.GPIOO => GPIOO,
        c.GPIOP => GPIOP,

        else => unreachable,
    };
}

/// Convenience to access GPIO sructs by the pointer to the port
pub fn enable_gpio(port: *c.GPIO_TypeDef) void {
    port_to_clock(port).enable();
}

/// Convenience to access GPIO sructs by the pointer to the port
pub fn disable_gpio(port: *c.GPIO_TypeDef) void {
    port_to_clock(port).disable();
}

/// Configure RCC
pub fn config(rcc_config: *c.RCC_OscInitTypeDef) !void {
    if (c.HAL_RCC_OscConfig(rcc_config) != c.HAL_OK) {
        std.debug.panic("HAL_RCC_OscConfig", .{});
    }
}
