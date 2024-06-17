// TODO: Double-check values here, XSPI is failing and **might** be some mis-config here

const std = @import("std");
const hal = @import("../../hal.zig");

const state = struct {
    var counter: u32 = 0;
};

export fn HAL_XSPI_MspInit(hxspi: *hal.c.XSPI_HandleTypeDef) callconv(.C) void {
    var periph_clk_init = std.mem.zeroes(hal.c.RCC_PeriphCLKInitTypeDef);
    periph_clk_init = switch (hxspi.Instance) {
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
    if (hal.c.HAL_RCCEx_PeriphCLKConfig(&periph_clk_init) != hal.c.HAL_OK) {
        std.debug.panic("HAL_RCCEx_PeriphCLKConfig", .{});
    }
    state.counter += 1;

    if (state.counter == 1) {
        hal.zig.clocks.XSPIM.enable();
    }

    switch (hxspi.Instance) {
        hal.c.XSPI1 => {
            hal.zig.clocks.XSPI1.enable();
            hal.zig.clocks.GPIOO.enable();
            hal.zig.clocks.GPIOP.enable();
        },
        hal.c.XSPI2 => {
            hal.zig.clocks.XSPI2.enable();
            hal.zig.clocks.GPION.enable();
        },
        else => unreachable,
    }

    var gpio_init = std.mem.zeroes(hal.c.GPIO_InitTypeDef);
    switch (hxspi.Instance) {
        hal.c.XSPI1 => {
            gpio_init = .{
                .Pin = hal.dk.HXSPI.DQS1.pin | hal.dk.HXSPI.DQS0.pin | hal.dk.HXSPI.CLK.pin,
                .Mode = hal.c.GPIO_MODE_AF_PP,
                .Pull = hal.c.GPIO_NOPULL,
                .Speed = hal.c.GPIO_SPEED_FREQ_VERY_HIGH,
                .Alternate = hal.c.GPIO_AF9_XSPIM_P1,
            };
            hal.c.HAL_GPIO_Init(hal.c.GPIOO, &gpio_init);

            gpio_init = .{
                .Pin = hal.dk.HXSPI.IO10.pin | hal.dk.HXSPI.IO12.pin | hal.dk.HXSPI.IO14.pin | hal.dk.HXSPI.IO2.pin | hal.dk.HXSPI.IO5.pin | hal.dk.HXSPI.IO1.pin | hal.dk.HXSPI.IO11.pin | hal.dk.HXSPI.IO15.pin | hal.dk.HXSPI.IO3.pin | hal.dk.HXSPI.IO0.pin | hal.dk.HXSPI.IO7.pin | hal.dk.HXSPI.IO8.pin | hal.dk.HXSPI.IO13.pin | hal.dk.HXSPI.IO4.pin | hal.dk.HXSPI.IO6.pin | hal.dk.HXSPI.IO9.pin,
                .Mode = hal.c.GPIO_MODE_AF_PP,
                .Pull = hal.c.GPIO_NOPULL,
                .Speed = hal.c.GPIO_SPEED_FREQ_VERY_HIGH,
                .Alternate = hal.c.GPIO_AF9_XSPIM_P1,
            };
            hal.c.HAL_GPIO_Init(hal.c.GPIOP, &gpio_init);
        },
        hal.c.XSPI2 => {
            gpio_init = .{
                .Pin = hal.dk.OSPI.IO1.pin | hal.dk.OSPI.DQS.pin | hal.dk.OSPI.IO7.pin | hal.dk.OSPI.IO6.pin | hal.dk.OSPI.IO5.pin | hal.dk.OSPI.IO0.pin | hal.dk.OSPI.CLK.pin | hal.dk.OSPI.IO4.pin | hal.dk.OSPI.IO2.pin | hal.dk.OSPI.IO3.pin,
                .Mode = hal.c.GPIO_MODE_AF_PP,
                .Pull = hal.c.GPIO_NOPULL,
                .Speed = hal.c.GPIO_SPEED_FREQ_VERY_HIGH,
                .Alternate = hal.c.GPIO_AF9_XSPIM_P2,
            };
            hal.c.HAL_GPIO_Init(hal.c.GPION, &gpio_init);
        },
        else => unreachable,
    }
}

export fn HAL_XSPI_MspDeInit(hxspi: *hal.c.XSPI_HandleTypeDef) callconv(.C) void {
    state.counter -= 1;
    if (state.counter == 0) {
        hal.zig.clocks.XSPIM.disable();
    }

    switch (hxspi.Instance) {
        hal.c.XSPI1 => {
            hal.zig.clocks.XSPI1.disable();

            hal.c.HAL_GPIO_DeInit(hal.c.GPIOO, hal.dk.HXSPI.DQS1.pin | hal.dk.HXSPI.DQS0.pin | hal.dk.HXSPI.CLK.pin);
            hal.c.HAL_GPIO_DeInit(hal.c.GPIOP, hal.dk.HXSPI.IO10.pin | hal.dk.HXSPI.IO12.pin | hal.dk.HXSPI.IO14.pin | hal.dk.HXSPI.IO2.pin | hal.dk.HXSPI.IO5.pin | hal.dk.HXSPI.IO1.pin | hal.dk.HXSPI.IO11.pin | hal.dk.HXSPI.IO15.pin | hal.dk.HXSPI.IO3.pin | hal.dk.HXSPI.IO0.pin | hal.dk.HXSPI.IO7.pin | hal.dk.HXSPI.IO8.pin | hal.dk.HXSPI.IO13.pin | hal.dk.HXSPI.IO4.pin | hal.dk.HXSPI.IO6.pin | hal.dk.HXSPI.IO9.pin);
        },
        hal.c.XSPI2 => {
            hal.zig.clocks.XSPI2.disable();

            hal.c.HAL_GPIO_DeInit(hal.c.GPION, hal.dk.OSPI.IO1.pin | hal.dk.OSPI.DQS.pin | hal.dk.OSPI.IO7.pin | hal.dk.OSPI.IO6.pin | hal.dk.OSPI.IO5.pin | hal.dk.OSPI.IO0.pin | hal.dk.OSPI.CLK.pin | hal.dk.OSPI.IO4.pin | hal.dk.OSPI.IO2.pin | hal.dk.OSPI.IO3.pin);
        },
        else => std.debug.panic("Unknown XSPI", .{}),
    }
}
