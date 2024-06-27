//! "Tiny" zig wrappers on top of STM HAL

const std = @import("std");
const hal = @import("hal.zig");

pub const cache = @import("hal_wrappers/cache.zig");
pub const clocks = @import("hal_wrappers/clocks.zig");
pub const sd = @import("hal_wrappers/sd.zig");
pub const usb = @import("hal_wrappers/usb.zig");
pub const xspi = @import("hal_wrappers/xspi.zig");

fn init_hal() void {
    const ret = hal.c.HAL_Init();
    if (ret != hal.c.HAL_OK) {
        std.debug.panic("HAL_Init", .{});
    }
}

fn init_power() void {
    if (hal.c.HAL_PWREx_ControlVoltageScaling(hal.c.PWR_REGULATOR_VOLTAGE_SCALE0) != hal.c.HAL_OK) {
        std.debug.panic("HAL_PWREx_ControlVoltageScaling", .{});
    }
}

fn init_clocks() void {
    var rcc_init = std.mem.zeroInit(hal.c.RCC_OscInitTypeDef, .{
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
    });
    if (hal.c.HAL_RCC_OscConfig(&rcc_init) != hal.c.HAL_OK) {
        std.debug.panic("HAL_RCC_OscConfig", .{});
    }

    var rcc_clk = std.mem.zeroInit(hal.c.RCC_ClkInitTypeDef, .{
        .ClockType = hal.c.RCC_CLOCKTYPE_HCLK | hal.c.RCC_CLOCKTYPE_SYSCLK | hal.c.RCC_CLOCKTYPE_PCLK1 | hal.c.RCC_CLOCKTYPE_PCLK2 | hal.c.RCC_CLOCKTYPE_PCLK4 | hal.c.RCC_CLOCKTYPE_PCLK5,
        .SYSCLKSource = hal.c.RCC_SYSCLKSOURCE_PLLCLK,
        .SYSCLKDivider = hal.c.RCC_SYSCLK_DIV1,
        .AHBCLKDivider = hal.c.RCC_HCLK_DIV2,
        .APB1CLKDivider = hal.c.RCC_APB1_DIV2,
        .APB2CLKDivider = hal.c.RCC_APB2_DIV2,
        .APB4CLKDivider = hal.c.RCC_APB4_DIV2,
        .APB5CLKDivider = hal.c.RCC_APB5_DIV2,
    });
    if (hal.c.HAL_RCC_ClockConfig(&rcc_clk, hal.c.FLASH_LATENCY_6) != hal.c.HAL_OK) {
        std.debug.panic("HAL_RCC_ClockConfig", .{});
    }
}

/// Initialize HAL and clocks
pub fn init() void {
    init_hal();
    init_power();
    init_clocks();
    hal.c.SystemCoreClockUpdate();
    hal.dk.init();
}

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

/// Mostly meant to store pin+port combo, but also tiny wrappers for HAL
pub const Pin = struct {
    const Self = @This();

    port: *hal.c.GPIO_TypeDef,
    pin: u16,

    pub fn init(pin: Self, mode: c_uint, pull: c_uint, speed: c_uint) void {
        clocks.enable_gpio(pin.port);

        var gpio_init = std.mem.zeroInit(hal.c.GPIO_InitTypeDef, .{
            .Pin = pin.pin,
            .Mode = mode,
            .Pull = pull,
            .Speed = speed,
        });
        hal.c.HAL_GPIO_Init(pin.port, &gpio_init);
    }
};

/// Store the configuration for an input pin (eg button)
pub const DigitalIn = struct {
    const Self = @This();

    base: hal.zig.Pin,
    active: hal.zig.Active,

    /// Configure the pin
    pub fn init(self: Self) void {
        const hal_pull = switch (self.active) {
            .Low => hal.c.GPIO_PULLUP,
            .High => hal.c.GPIO_PULLDOWN,
        };

        self.base.init(hal.c.GPIO_MODE_INPUT, hal_pull, hal.c.GPIO_SPEED_FREQ_LOW);
    }

    /// Read input, takin into account the pull, to return "is button pressed"
    pub fn read(self: Self) bool {
        const check = switch (self.active) {
            .Low => hal.c.GPIO_PIN_RESET,
            .High => hal.c.GPIO_PIN_SET,
        };

        return hal.c.HAL_GPIO_ReadPin(self.base.port, self.base.pin) == check;
    }
};

/// Store the configuration for an output pin (eg LED)
pub const DigitalOut = struct {
    const Self = @This();

    base: hal.zig.Pin,
    active: hal.zig.Active,

    /// Configure the pin and set it at "off" state
    pub fn init(self: Self) void {
        // TODO?: Something based on `self.active`
        self.base.init(hal.c.GPIO_MODE_OUTPUT_PP, hal.c.GPIO_PULLUP, hal.c.GPIO_SPEED_FREQ_VERY_HIGH);
    }

    /// Set the **logical** output level (according to active-ness)
    pub fn set(self: Self, value: bool) void {
        const output = switch (self.active) {
            .Low => !value,
            .High => value,
        };

        const hal_out: c_uint = if (output) hal.c.GPIO_PIN_SET else hal.c.GPIO_PIN_RESET;

        hal.c.HAL_GPIO_WritePin(self.base.port, self.base.pin, hal_out);
    }

    /// Toggle the output voltage
    pub fn toggle(self: Self) void {
        hal.c.HAL_GPIO_TogglePin(self.base.port, self.base.pin);
    }
};
