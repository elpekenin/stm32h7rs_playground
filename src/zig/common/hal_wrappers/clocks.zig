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

pub fn addr_of(name: []const u8) *u32 {
    const rcc_addr = hal.c.RCC_BASE;
    const offset = @offsetOf(hal.c.RCC_TypeDef, name);
    return @ptrFromInt(rcc_addr + offset);
}

const AHB4ENR = addr_of("AHB4ENR");
const AHB5ENR = addr_of("AHB5ENR");
const APB4ENR = addr_of("APB4ENR");

pub const GPIOA = Clock{
    .register = AHB4ENR,
    .bitmask = hal.c.RCC_AHB4ENR_GPIOAEN,
};

pub const GPIOB = Clock{
    .register = AHB4ENR,
    .bitmask = hal.c.RCC_AHB4ENR_GPIOBEN,
};

pub const GPIOC = Clock{
    .register = AHB4ENR,
    .bitmask = hal.c.RCC_AHB4ENR_GPIOCEN,
};

pub const GPIOD = Clock{
    .register = AHB4ENR,
    .bitmask = hal.c.RCC_AHB4ENR_GPIODEN,
};

pub const GPIOE = Clock{
    .register = AHB4ENR,
    .bitmask = hal.c.RCC_AHB4ENR_GPIOEEN,
};

pub const GPIOF = Clock{
    .register = AHB4ENR,
    .bitmask = hal.c.RCC_AHB4ENR_GPIOFEN,
};

pub const GPIOG = Clock{
    .register = AHB4ENR,
    .bitmask = hal.c.RCC_AHB4ENR_GPIOGEN,
};

pub const GPIOH = Clock{
    .register = AHB4ENR,
    .bitmask = hal.c.RCC_AHB4ENR_GPIOHEN,
};

pub const GPIOM = Clock{
    .register = AHB4ENR,
    .bitmask = hal.c.RCC_AHB4ENR_GPIOMEN,
};

pub const GPION = Clock{
    .register = AHB4ENR,
    .bitmask = hal.c.RCC_AHB4ENR_GPIONEN,
};

pub const GPIOO = Clock{
    .register = AHB4ENR,
    .bitmask = hal.c.RCC_AHB4ENR_GPIOOEN,
};

pub const GPIOP = Clock{
    .register = AHB4ENR,
    .bitmask = hal.c.RCC_AHB4ENR_GPIOPEN,
};

pub const SDMMC1 = Clock{
    .register = AHB5ENR,
    .bitmask = hal.c.RCC_AHB5ENR_SDMMC1EN,
};

pub const XSPIM = Clock{
    .register = AHB5ENR,
    .bitmask = hal.c.RCC_AHB5ENR_XSPIMEN,
};

pub const XSPI1 = Clock{
    .register = AHB5ENR,
    .bitmask = hal.c.RCC_AHB5ENR_XSPI1EN,
};

pub const XSPI2 = Clock{
    .register = AHB5ENR,
    .bitmask = hal.c.RCC_AHB5ENR_XSPI2EN,
};

pub const SBS = Clock{
    .register = APB4ENR,
    .bitmask = hal.c.RCC_APB4ENR_SBSEN,
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
