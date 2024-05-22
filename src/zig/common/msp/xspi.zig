const std = @import("std");
const hal = @import("../hal.zig");

const state = struct {
    var counter: u32 = 0;
};

export fn HAL_XSPI_MspInit(hxspi: *hal.c.XSPI_HandleTypeDef) callconv(.C) void {
    var PeriphClkInit = std.mem.zeroes(hal.c.RCC_PeriphCLKInitTypeDef);
    PeriphClkInit = switch (hxspi.Instance) {
        hal.c.XSPI1 => .{
            .PeriphClockSelection = hal.c.RCC_PERIPHCLK_XSPI1,
            .Xspi1ClockSelection = hal.c.RCC_XSPI1CLKSOURCE_PLL2S,
        },
        hal.c.XSPI2 => .{
            .PeriphClockSelection = hal.c.RCC_PERIPHCLK_XSPI2,
            .Xspi2ClockSelection = hal.c.RCC_XSPI2CLKSOURCE_PLL2S,
        },
        else => std.debug.panic("Unknown XSPI", .{}),
    };
    if (hal.c.HAL_RCCEx_PeriphCLKConfig(&PeriphClkInit) != hal.c.HAL_OK) {
        std.debug.panic("HAL_RCCEx_PeriphCLKConfig", .{});
    }
    state.counter += 1;

    if (state.counter == 1) {
        hal.zig.clocks.enable.xspim();
    }

    switch (hxspi.Instance) {
        hal.c.XSPI1 => {
            hal.zig.clocks.enable.xspi1();
            hal.zig.clocks.enable.gpio(hal.c.GPIOO);
            hal.zig.clocks.enable.gpio(hal.c.GPIOP);
        },
        hal.c.XSPI2 => {
            hal.zig.clocks.enable.xspi2();
            hal.zig.clocks.enable.gpio(hal.c.GPION);
        },
        else => unreachable,
    }

    var GPIO_InitStruct = std.mem.zeroes(hal.c.GPIO_InitTypeDef);
    switch (hxspi.Instance) {
        hal.c.XSPI1 => {
            GPIO_InitStruct = .{
                .Pin = hal.c.HEXASPI_DQS1_Pin | hal.c.HEXASPI_DQS0_Pin | hal.c.HEXASPI_CLK_Pin,
                .Mode = hal.c.GPIO_MODE_AF_PP,
                .Pull = hal.c.GPIO_NOPULL,
                .Speed = hal.c.GPIO_SPEED_FREQ_VERY_HIGH,
                .Alternate = hal.c.GPIO_AF9_XSPIM_P1,
            };
            hal.c.HAL_GPIO_Init(hal.c.GPIOO, &GPIO_InitStruct);

            GPIO_InitStruct = .{
                .Pin = hal.c.HEXASPI_IO10_Pin | hal.c.HEXASPI_IO12_Pin | hal.c.HEXASPI_IO14_Pin | hal.c.HEXASPI_IO2_Pin | hal.c.HEXASPI_IO5_Pin | hal.c.HEXASPI_IO1_Pin | hal.c.HEXASPI_IO11_Pin | hal.c.HEXASPI_IO15_Pin | hal.c.HEXASPI_IO3_Pin | hal.c.HEXASPI_IO0_Pin | hal.c.HEXASPI_IO7_Pin | hal.c.HEXASPI_IO8_Pin | hal.c.HEXASPI_IO13_Pin | hal.c.HEXASPI_IO4_Pin | hal.c.HEXASPI_IO6_Pin | hal.c.HEXASPI_IO9_Pin,
                .Mode = hal.c.GPIO_MODE_AF_PP,
                .Pull = hal.c.GPIO_NOPULL,
                .Speed = hal.c.GPIO_SPEED_FREQ_VERY_HIGH,
                .Alternate = hal.c.GPIO_AF9_XSPIM_P1,
            };
            hal.c.HAL_GPIO_Init(hal.c.GPIOP, &GPIO_InitStruct);
        },
        hal.c.XSPI2 => {
            GPIO_InitStruct = .{
                .Pin = hal.c.OCTOSPI_IO1_Pin | hal.c.OCTOSPI_DQS_Pin | hal.c.OCTOSPI_IO7_Pin | hal.c.OCTOSPI_IO6_Pin | hal.c.OCTOSPI_IO5_Pin | hal.c.OCTOSPI_IO0_Pin | hal.c.OCTOSPI_CLK_Pin | hal.c.OCTOSPI_IO4_Pin | hal.c.OCTOSPI_IO2_Pin | hal.c.OCTOSPI_IO3_Pin,
                .Mode = hal.c.GPIO_MODE_AF_PP,
                .Pull = hal.c.GPIO_NOPULL,
                .Speed = hal.c.GPIO_SPEED_FREQ_VERY_HIGH,
                .Alternate = hal.c.GPIO_AF9_XSPIM_P2,
            };
            hal.c.HAL_GPIO_Init(hal.c.GPION, &GPIO_InitStruct);
        },
        else => unreachable,
    }
}

export fn HAL_XSPI_MspDeInit(hxspi: *hal.c.XSPI_HandleTypeDef) callconv(.C) void {
    state.counter -= 1;
    if (state.counter == 0) {
        hal.zig.clocks.disable.xspim();
    }

    switch (hxspi.Instance) {
        hal.c.XSPI1 => {
            hal.zig.clocks.disable.xspi1();

            hal.c.HAL_GPIO_DeInit(hal.c.GPIOO, hal.c.HEXASPI_DQS1_Pin | hal.c.HEXASPI_DQS0_Pin | hal.c.HEXASPI_CLK_Pin);
            hal.c.HAL_GPIO_DeInit(hal.c.GPIOP, hal.c.HEXASPI_IO10_Pin | hal.c.HEXASPI_IO12_Pin | hal.c.HEXASPI_IO14_Pin | hal.c.HEXASPI_IO2_Pin | hal.c.HEXASPI_IO5_Pin | hal.c.HEXASPI_IO1_Pin | hal.c.HEXASPI_IO11_Pin | hal.c.HEXASPI_IO15_Pin | hal.c.HEXASPI_IO3_Pin | hal.c.HEXASPI_IO0_Pin | hal.c.HEXASPI_IO7_Pin | hal.c.HEXASPI_IO8_Pin | hal.c.HEXASPI_IO13_Pin | hal.c.HEXASPI_IO4_Pin | hal.c.HEXASPI_IO6_Pin | hal.c.HEXASPI_IO9_Pin);
        },
        hal.c.XSPI2 => {
            hal.zig.clocks.disable.xspi2();

            hal.c.HAL_GPIO_DeInit(hal.c.GPION, hal.c.OCTOSPI_IO1_Pin | hal.c.OCTOSPI_DQS_Pin | hal.c.OCTOSPI_IO7_Pin | hal.c.OCTOSPI_IO6_Pin | hal.c.OCTOSPI_IO5_Pin | hal.c.OCTOSPI_IO0_Pin | hal.c.OCTOSPI_CLK_Pin | hal.c.OCTOSPI_IO4_Pin | hal.c.OCTOSPI_IO2_Pin | hal.c.OCTOSPI_IO3_Pin);
        },
        else => std.debug.panic("Unknown XSPI", .{}),
    }
}
