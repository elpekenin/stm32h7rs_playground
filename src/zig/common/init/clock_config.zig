//! Initialize clocks

const std = @import("std");
const hal = @import("../hal.zig");

pub fn init() void {
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
