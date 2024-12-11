const std = @import("std");
const hal = @import("../../mod.zig");
const c = hal.c;

export fn HAL_SD_MspInit(hsd: *c.SD_HandleTypeDef) void {
    if (hsd.Instance != c.SDMMC1) {
        std.debug.panic("hsd != SDMMC1", .{});
    }

    var PeriphClkInit = std.mem.zeroInit(
        c.RCC_PeriphCLKInitTypeDef,
        .{
            .PeriphClockSelection = c.RCC_PERIPHCLK_SDMMC12,
            .Sdmmc12ClockSelection = c.RCC_SDMMC12CLKSOURCE_PLL2S,
        },
    );
    if (c.HAL_RCCEx_PeriphCLKConfig(&PeriphClkInit) != c.HAL_OK) {
        std.debug.panic("HAL_RCCEx_PeriphCLKConfig", .{});
    }

    hal.zig.rcc.SDMMC1.enable();
    hal.zig.rcc.GPIOC.enable();
    hal.zig.rcc.GPIOD.enable();

    var gpio_init = std.mem.zeroInit(
        c.GPIO_InitTypeDef,
        .{
            .Pin = hal.bsp.SD.CMD.pin,
            .Mode = c.GPIO_MODE_AF_PP,
            .Pull = c.GPIO_NOPULL,
            .Speed = c.GPIO_SPEED_FREQ_HIGH,
            .Alternate = c.GPIO_AF11_SDMMC1,
        },
    );
    c.HAL_GPIO_Init(hal.bsp.SD.CMD.port, &gpio_init);

    gpio_init = .{
        .Pin = hal.bsp.SD.D2.pin,
        .Mode = c.GPIO_MODE_AF_PP,
        .Pull = c.GPIO_NOPULL,
        .Speed = c.GPIO_SPEED_FREQ_HIGH,
        .Alternate = c.GPIO_AF12_SDMMC1,
    };
    c.HAL_GPIO_Init(hal.bsp.SD.D2.port, &gpio_init);

    gpio_init = .{
        .Pin = hal.bsp.SD.D0.pin | hal.bsp.SD.D1.pin | hal.bsp.SD.D3.pin | hal.bsp.SD.CK.pin,
        .Mode = c.GPIO_MODE_AF_PP,
        .Pull = c.GPIO_NOPULL,
        .Speed = c.GPIO_SPEED_FREQ_HIGH,
        .Alternate = c.GPIO_AF11_SDMMC1,
    };
    c.HAL_GPIO_Init(c.GPIOC, &gpio_init);
}

export fn HAL_SD_MspDeInit(hsd: *c.SD_HandleTypeDef) void {
    if (hsd.Instance != c.SDMMC1) {
        std.debug.panic("hsd != SDMMC1", .{});
    }

    hal.zig.rcc.SDMMC1.disable();

    c.HAL_GPIO_DeInit(hal.bsp.SD.CMD.port, hal.bsp.SD.CMD.pin);
    c.HAL_GPIO_DeInit(c.GPIOC, hal.bsp.SD.D0.pin | hal.bsp.SD.D1.pin | hal.bsp.SD.D2.pin | hal.bsp.SD.D3.pin | hal.bsp.SD.CK.pin);
}
