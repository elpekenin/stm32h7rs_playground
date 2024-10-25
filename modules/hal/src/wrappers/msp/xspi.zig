// TODO: Double-check values here, XSPI is failing and **might** be some mis-config here

const std = @import("std");
const hal = @import("../../hal.zig");
const c = hal.c;

const state = struct {
    var counter: u32 = 0;
};

export fn HAL_XSPI_MspInit(hxspi: *c.XSPI_HandleTypeDef) callconv(.C) void {
    var periph_clk_init = std.mem.zeroes(c.RCC_PeriphCLKInitTypeDef);
    periph_clk_init = switch (hxspi.Instance) {
        c.XSPI1 => .{
            .PeriphClockSelection = c.RCC_PERIPHCLK_XSPI1,
            .Xspi1ClockSelection = c.RCC_XSPI1CLKSOURCE_PLL2S,
        },
        c.XSPI2 => .{
            .PeriphClockSelection = c.RCC_PERIPHCLK_XSPI2,
            .Xspi2ClockSelection = c.RCC_XSPI2CLKSOURCE_PLL2S,
        },
        else => std.debug.panic("Unknown XSPI", .{}),
    };
    if (c.HAL_RCCEx_PeriphCLKConfig(&periph_clk_init) != c.HAL_OK) {
        std.debug.panic("HAL_RCCEx_PeriphCLKConfig", .{});
    }
    state.counter += 1;

    if (state.counter == 1) {
        hal.zig.rcc.XSPIM.enable();
    }

    switch (hxspi.Instance) {
        c.XSPI1 => {
            hal.zig.rcc.XSPI1.enable();
            hal.zig.rcc.GPIOO.enable();
            hal.zig.rcc.GPIOP.enable();
        },
        c.XSPI2 => {
            hal.zig.rcc.XSPI2.enable();
            hal.zig.rcc.GPION.enable();
        },
        else => unreachable,
    }

    var gpio_init = std.mem.zeroes(c.GPIO_InitTypeDef);
    switch (hxspi.Instance) {
        c.XSPI1 => {
            gpio_init = .{
                .Pin = hal.dk.HXSPI.DQS1.pin | hal.dk.HXSPI.DQS0.pin | hal.dk.HXSPI.CLK.pin,
                .Mode = c.GPIO_MODE_AF_PP,
                .Pull = c.GPIO_NOPULL,
                .Speed = c.GPIO_SPEED_FREQ_VERY_HIGH,
                .Alternate = c.GPIO_AF9_XSPIM_P1,
            };
            c.HAL_GPIO_Init(c.GPIOO, &gpio_init);

            gpio_init = .{
                .Pin = hal.dk.HXSPI.IO10.pin | hal.dk.HXSPI.IO12.pin | hal.dk.HXSPI.IO14.pin | hal.dk.HXSPI.IO2.pin | hal.dk.HXSPI.IO5.pin | hal.dk.HXSPI.IO1.pin | hal.dk.HXSPI.IO11.pin | hal.dk.HXSPI.IO15.pin | hal.dk.HXSPI.IO3.pin | hal.dk.HXSPI.IO0.pin | hal.dk.HXSPI.IO7.pin | hal.dk.HXSPI.IO8.pin | hal.dk.HXSPI.IO13.pin | hal.dk.HXSPI.IO4.pin | hal.dk.HXSPI.IO6.pin | hal.dk.HXSPI.IO9.pin,
                .Mode = c.GPIO_MODE_AF_PP,
                .Pull = c.GPIO_NOPULL,
                .Speed = c.GPIO_SPEED_FREQ_VERY_HIGH,
                .Alternate = c.GPIO_AF9_XSPIM_P1,
            };
            c.HAL_GPIO_Init(c.GPIOP, &gpio_init);
        },
        c.XSPI2 => {
            gpio_init = .{
                .Pin = hal.dk.OSPI.IO1.pin | hal.dk.OSPI.DQS.pin | hal.dk.OSPI.IO7.pin | hal.dk.OSPI.IO6.pin | hal.dk.OSPI.IO5.pin | hal.dk.OSPI.IO0.pin | hal.dk.OSPI.CLK.pin | hal.dk.OSPI.IO4.pin | hal.dk.OSPI.IO2.pin | hal.dk.OSPI.IO3.pin,
                .Mode = c.GPIO_MODE_AF_PP,
                .Pull = c.GPIO_NOPULL,
                .Speed = c.GPIO_SPEED_FREQ_VERY_HIGH,
                .Alternate = c.GPIO_AF9_XSPIM_P2,
            };
            c.HAL_GPIO_Init(c.GPION, &gpio_init);
        },
        else => unreachable,
    }
}

export fn HAL_XSPI_MspDeInit(hxspi: *c.XSPI_HandleTypeDef) callconv(.C) void {
    state.counter -= 1;
    if (state.counter == 0) {
        hal.zig.rcc.XSPIM.disable();
    }

    switch (hxspi.Instance) {
        c.XSPI1 => {
            hal.zig.rcc.XSPI1.disable();

            c.HAL_GPIO_DeInit(c.GPIOO, hal.dk.HXSPI.DQS1.pin | hal.dk.HXSPI.DQS0.pin | hal.dk.HXSPI.CLK.pin);
            c.HAL_GPIO_DeInit(c.GPIOP, hal.dk.HXSPI.IO10.pin | hal.dk.HXSPI.IO12.pin | hal.dk.HXSPI.IO14.pin | hal.dk.HXSPI.IO2.pin | hal.dk.HXSPI.IO5.pin | hal.dk.HXSPI.IO1.pin | hal.dk.HXSPI.IO11.pin | hal.dk.HXSPI.IO15.pin | hal.dk.HXSPI.IO3.pin | hal.dk.HXSPI.IO0.pin | hal.dk.HXSPI.IO7.pin | hal.dk.HXSPI.IO8.pin | hal.dk.HXSPI.IO13.pin | hal.dk.HXSPI.IO4.pin | hal.dk.HXSPI.IO6.pin | hal.dk.HXSPI.IO9.pin);
        },
        c.XSPI2 => {
            hal.zig.rcc.XSPI2.disable();

            c.HAL_GPIO_DeInit(c.GPION, hal.dk.OSPI.IO1.pin | hal.dk.OSPI.DQS.pin | hal.dk.OSPI.IO7.pin | hal.dk.OSPI.IO6.pin | hal.dk.OSPI.IO5.pin | hal.dk.OSPI.IO0.pin | hal.dk.OSPI.CLK.pin | hal.dk.OSPI.IO4.pin | hal.dk.OSPI.IO2.pin | hal.dk.OSPI.IO3.pin);
        },
        else => std.debug.panic("Unknown XSPI", .{}),
    }
}
