//! Configure the clocks in the MCU
//!
//! Eg, to enable GPIO ports.

const std = @import("std");

const hal = @import("../hal.zig");

var RCC = @as(*hal.c.RCC_TypeDef, @ptrFromInt(hal.c.RCC_BASE));
var _tmpreg: u32 = 0;
const tmpreg: *volatile u32 = &_tmpreg;

pub const enable = struct {
    /// This will also give power to O/M ports
    pub fn gpio(port: *hal.c.GPIO_TypeDef) void {
        // should use `hal.__HAL_RCC_GPIO%_CLK_ENABLE();`, but zig doesnt like those macros

        switch (port) {
            hal.c.GPIOA => RCC.AHB4ENR |= hal.c.RCC_AHB4ENR_GPIOAEN,
            hal.c.GPIOB => RCC.AHB4ENR |= hal.c.RCC_AHB4ENR_GPIOBEN,
            hal.c.GPIOC => RCC.AHB4ENR |= hal.c.RCC_AHB4ENR_GPIOCEN,
            hal.c.GPIOD => RCC.AHB4ENR |= hal.c.RCC_AHB4ENR_GPIODEN,
            hal.c.GPIOE => RCC.AHB4ENR |= hal.c.RCC_AHB4ENR_GPIOEEN,
            hal.c.GPIOF => RCC.AHB4ENR |= hal.c.RCC_AHB4ENR_GPIOFEN,
            hal.c.GPIOG => RCC.AHB4ENR |= hal.c.RCC_AHB4ENR_GPIOGEN,
            hal.c.GPIOH => RCC.AHB4ENR |= hal.c.RCC_AHB4ENR_GPIOHEN,
            hal.c.GPIOM => RCC.AHB4ENR |= hal.c.RCC_AHB4ENR_GPIOMEN,
            hal.c.GPION => RCC.AHB4ENR |= hal.c.RCC_AHB4ENR_GPIONEN,
            hal.c.GPIOO => RCC.AHB4ENR |= hal.c.RCC_AHB4ENR_GPIOOEN,
            hal.c.GPIOP => RCC.AHB4ENR |= hal.c.RCC_AHB4ENR_GPIOPEN,

            else => unreachable,
        }

        tmpreg.* = RCC.AHB4ENR;
    }

    pub fn sdmmc1() void {
        RCC.AHB5ENR |= hal.c.RCC_AHB5ENR_SDMMC1EN;
        tmpreg.* = RCC.AHB5ENR;
    }

    pub fn sbs() void {
        RCC.APB4ENR |= hal.c.RCC_APB4ENR_SBSEN;
        tmpreg.* = RCC.APB4ENR;
    }

    pub fn xspim() void {
        RCC.AHB5ENR |= hal.c.RCC_AHB5ENR_XSPIMEN;
        tmpreg.* = RCC.AHB5ENR;
    }

    pub fn xspi1() void {
        RCC.AHB5ENR |= hal.c.RCC_AHB5ENR_XSPI1EN;
        tmpreg.* = RCC.AHB5ENR;
    }

    pub fn xspi2() void {
        RCC.AHB5ENR |= hal.c.RCC_AHB5ENR_XSPI2EN;
        tmpreg.* = RCC.AHB5ENR;
    }
};

pub const disable = struct {
    pub fn sdmmc1() void {
        RCC.AHB5ENR &= ~hal.c.RCC_AHB5ENR_SDMMC1EN;
        tmpreg.* = RCC.AHB5ENR;
    }

    pub fn xspim() void {
        RCC.AHB5ENR &= ~hal.c.RCC_AHB5ENR_XSPIMEN;
        tmpreg.* = RCC.AHB5ENR;
    }

    pub fn xspi1() void {
        RCC.AHB5ENR &= ~hal.c.RCC_AHB5ENR_XSPI1EN;
        tmpreg.* = RCC.AHB5ENR;
    }

    pub fn xspi2() void {
        RCC.AHB5ENR &= ~hal.c.RCC_AHB5ENR_XSPI2EN;
        tmpreg.* = RCC.AHB5ENR;
    }
};

pub const force_reset = struct {
    pub fn sdmmc1() void {
        RCC.AHB5RSTR |= hal.c.RCC_AHB5RSTR_SDMMC1RST;
    }
};

pub const release_reset = struct {
    pub fn sdmmc1() void {
        RCC.AHB5RSTR &= ~hal.c.RCC_AHB5RSTR_SDMMC1RST;
    }
};
