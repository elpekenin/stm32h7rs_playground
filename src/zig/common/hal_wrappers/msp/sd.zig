const std = @import("std");
const hal = @import("../../hal.zig");

export fn HAL_SD_MspInit(hsd: *hal.c.SD_HandleTypeDef) callconv(.C) void {
    if (hsd.Instance != hal.c.SDMMC1) {
        std.debug.panic("hsd != SDMMC1", .{});
    }

    var PeriphClkInit = std.mem.zeroes(hal.c.RCC_PeriphCLKInitTypeDef);
    PeriphClkInit = .{
        .PeriphClockSelection = hal.c.RCC_PERIPHCLK_SDMMC12,
        .Sdmmc12ClockSelection = hal.c.RCC_SDMMC12CLKSOURCE_PLL2S,
    };
    if (hal.c.HAL_RCCEx_PeriphCLKConfig(&PeriphClkInit) != hal.c.HAL_OK) {
        std.debug.panic("HAL_RCCEx_PeriphCLKConfig", .{});
    }

    hal.zig.clocks.SDMMC1.enable();
    hal.zig.clocks.GPIOC.enable();
    hal.zig.clocks.GPIOD.enable();

    var GPIO_InitStruct = std.mem.zeroes(hal.c.GPIO_InitTypeDef);
    GPIO_InitStruct = .{
        .Pin = hal.c.SD_CMD_Pin,
        .Mode = hal.c.GPIO_MODE_AF_PP,
        .Pull = hal.c.GPIO_NOPULL,
        .Speed = hal.c.GPIO_SPEED_FREQ_HIGH,
        .Alternate = hal.c.GPIO_AF11_SDMMC1,
    };
    hal.c.HAL_GPIO_Init(hal.c.SD_CMD_GPIO_Port, &GPIO_InitStruct);

    GPIO_InitStruct = .{
        .Pin = hal.c.SD_D2_Pin,
        .Mode = hal.c.GPIO_MODE_AF_PP,
        .Pull = hal.c.GPIO_NOPULL,
        .Speed = hal.c.GPIO_SPEED_FREQ_HIGH,
        .Alternate = hal.c.GPIO_AF12_SDMMC1,
    };
    hal.c.HAL_GPIO_Init(hal.c.SD_D2_GPIO_Port, &GPIO_InitStruct);

    GPIO_InitStruct = .{
        .Pin = hal.c.SD_D0_Pin | hal.c.SD_D1_Pin | hal.c.SD_D3_Pin | hal.c.SD_CK_Pin,
        .Mode = hal.c.GPIO_MODE_AF_PP,
        .Pull = hal.c.GPIO_NOPULL,
        .Speed = hal.c.GPIO_SPEED_FREQ_HIGH,
        .Alternate = hal.c.GPIO_AF11_SDMMC1,
    };
    hal.c.HAL_GPIO_Init(hal.c.GPIOC, &GPIO_InitStruct);
}

export fn HAL_SD_MspDeInit(hsd: *hal.c.SD_HandleTypeDef) callconv(.C) void {
    if (hsd.Instance != hal.c.SDMMC1) {
        std.debug.panic("hsd != SDMMC1", .{});
    }

    hal.zig.clocks.SDMMC1.disable();

    hal.c.HAL_GPIO_DeInit(hal.c.SD_CMD_GPIO_Port, hal.c.SD_CMD_Pin);
    hal.c.HAL_GPIO_DeInit(hal.c.GPIOC, hal.c.SD_D0_Pin | hal.c.SD_D1_Pin | hal.c.SD_D2_Pin | hal.c.SD_D3_Pin | hal.c.SD_CK_Pin);
}
