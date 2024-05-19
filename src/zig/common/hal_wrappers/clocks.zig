//! Configure the clocks in the MCU
//!
//! Eg, to enable GPIO ports.

const std = @import("std");

const hal = @import("../hal.zig");

var RCC = @as(*hal.RCC_TypeDef, @ptrFromInt(hal.RCC_BASE));
var _tmpreg: u32 = 0;
const tmpreg: *volatile u32 = &_tmpreg;

pub const enable = struct {
    /// This will also give power to O/M ports
    pub fn gpio(port: *hal.GPIO_TypeDef) !void {
        // should use `hal.__HAL_RCC_GPIO%_CLK_ENABLE();`, but zig doesnt like those macros

        switch (port) {
            hal.GPIOA => RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIOAEN,
            hal.GPIOB => RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIOBEN,
            hal.GPIOC => RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIOCEN,
            hal.GPIOD => RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIODEN,
            hal.GPIOE => RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIOEEN,
            hal.GPIOF => RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIOFEN,
            hal.GPIOG => RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIOGEN,
            hal.GPIOH => RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIOHEN,
            hal.GPIOM => RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIOMEN,
            hal.GPION => RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIONEN,
            hal.GPIOO => RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIOOEN,
            hal.GPIOP => RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIOPEN,

            else => std.debug.panic("Unknown GPIO port.", .{}),
        }

        tmpreg.* = RCC.AHB4ENR;
    }

    pub fn sdmmc1() void {
        RCC.AHB5ENR |= hal.RCC_AHB5ENR_SDMMC1EN;
        tmpreg.* = RCC.AHB5ENR;
    }
};

pub const force_reset = struct {
    pub fn sdmmc1() void {
        RCC.AHB5RSTR |= hal.RCC_AHB5RSTR_SDMMC1RST;
    }
};

pub const release_reset = struct {
    pub fn sdmmc1() void {
        RCC.AHB5RSTR &= ~hal.RCC_AHB5RSTR_SDMMC1RST;
    }
};
