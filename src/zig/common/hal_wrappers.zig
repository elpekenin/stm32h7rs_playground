//! "Tiny" zig wrappers on top of STM HAL

const std = @import("std");
const hal = @import("hal.zig");

pub const clocks = @import("hal_wrappers/clocks.zig");
pub const digital = @import("hal_wrappers/digital.zig");
pub const sd = @import("hal_wrappers/sd.zig");
pub const usb = @import("hal_wrappers/usb.zig");

pub const init = struct {
    pub fn clocks() void {
        if (hal.c.HAL_PWREx_ControlVoltageScaling(hal.c.PWR_REGULATOR_VOLTAGE_SCALE0) != hal.c.HAL_OK) {
            std.debug.panic("HAL_PWREx_ControlVoltageScaling", .{});
        }

        var RCC_OscInitStruct = std.mem.zeroes(hal.c.RCC_OscInitTypeDef);
        RCC_OscInitStruct = .{
            .OscillatorType = hal.c.RCC_OSCILLATORTYPE_HSI48 | hal.c.RCC_OSCILLATORTYPE_HSI,
            .HSIState = hal.c.RCC_HSI_ON,
            .HSIDiv = hal.c.RCC_HSI_DIV1,
            .HSICalibrationValue = hal.c.RCC_HSICALIBRATION_DEFAULT,
            .HSI48State = hal.c.RCC_HSI48_ON,
            .PLL1 = .{
                .PLLState = hal.c.RCC_PLL_ON,
                .PLLSource = hal.c.RCC_PLLSOURCE_HSI,
                .PLLM = 32,
                .PLLN = 300,
                .PLLP = 1,
                .PLLQ = 2,
                .PLLR = 2,
                .PLLS = 2,
                .PLLT = 2,
                .PLLFractional = 0,
            },
            .PLL2 = .{
                .PLLState = hal.c.RCC_PLL_ON,
                .PLLSource = hal.c.RCC_PLLSOURCE_HSI,
                .PLLM = 4,
                .PLLN = 25,
                .PLLP = 2,
                .PLLQ = 2,
                .PLLR = 2,
                .PLLS = 2,
                .PLLT = 2,
                .PLLFractional = 0,
            },
            .PLL3 = .{
                .PLLState = hal.c.RCC_PLL_ON,
                .PLLSource = hal.c.RCC_PLLSOURCE_HSI,
                .PLLM = 4,
                .PLLN = 25,
                .PLLP = 2,
                .PLLQ = 20,
                .PLLR = 1,
                .PLLS = 2,
                .PLLT = 2,
                .PLLFractional = 0,
            },
        };
        if (hal.c.HAL_RCC_OscConfig(&RCC_OscInitStruct) != hal.c.HAL_OK) {
            std.debug.panic("HAL_RCC_OscConfig", .{});
        }

        var RCC_ClkInitStruct = std.mem.zeroes(hal.c.RCC_ClkInitTypeDef);
        RCC_ClkInitStruct = .{
            .ClockType = hal.c.RCC_CLOCKTYPE_HCLK | hal.c.RCC_CLOCKTYPE_SYSCLK | hal.c.RCC_CLOCKTYPE_PCLK1 | hal.c.RCC_CLOCKTYPE_PCLK2 | hal.c.RCC_CLOCKTYPE_PCLK4 | hal.c.RCC_CLOCKTYPE_PCLK5,
            .SYSCLKSource = hal.c.RCC_SYSCLKSOURCE_PLLCLK,
            .SYSCLKDivider = hal.c.RCC_SYSCLK_DIV1,
            .AHBCLKDivider = hal.c.RCC_HCLK_DIV2,
            .APB1CLKDivider = hal.c.RCC_APB1_DIV2,
            .APB2CLKDivider = hal.c.RCC_APB2_DIV2,
            .APB4CLKDivider = hal.c.RCC_APB4_DIV2,
            .APB5CLKDivider = hal.c.RCC_APB5_DIV2,
        };
        if (hal.c.HAL_RCC_ClockConfig(&RCC_ClkInitStruct, hal.c.FLASH_LATENCY_6) != hal.c.HAL_OK) {
            std.debug.panic("HAL_RCC_ClockConfig", .{});
        }
    }
};

// Please zig, do not garbage-collect these, we need to export C funcs, thx!!
comptime {
    _ = @import("hal_wrappers/msp/base.zig");
    _ = @import("hal_wrappers/msp/sd.zig");
    _ = @import("hal_wrappers/msp/xspi.zig");
    _ = @import("hal_wrappers/irq.zig");
}

pub const Active = enum {
    Low,
    High,
};

pub const BasePin = struct {
    const Self = @This();

    port: *hal.c.GPIO_TypeDef,
    pin: u16,

    pub fn __init(self: Self, mode: c_uint, pull: c_uint, speed: c_uint) void {
        clocks.enable_gpio(self.port);

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
