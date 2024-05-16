// Constants for DK board peripherals
const std = @import("std");

const hal = @import("hal.zig");

const TIMEOUT = 500;

pub const Error = error{
    HalError,
    SDNotReady,
};

pub const Active = enum {
    Low,
    High,
};

var RCC = @as(*hal.RCC_TypeDef, @ptrFromInt(hal.RCC_BASE));
var _tmpreg: u32 = 0;
const tmpreg: *volatile u32 = &_tmpreg;

/// Enable a port, this is:
///   - Enable its clock
///   - Give it power (only ports O and M implemented yet)
fn gpio_clk_enable(port: *hal.GPIO_TypeDef) !void {
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

        hal.GPIOM => {
            const ret = hal.HAL_PWREx_EnableUSBVoltageDetector();
            if (ret != hal.HAL_OK) {
                std.log.err("Could not enable USB voltage level detector", .{});
                return error.HalError;
            }
            RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIOMEN;
        },

        hal.GPION => RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIONEN,

        hal.GPIOO => {
            hal.HAL_PWREx_EnableXSPIM1();
            RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIOOEN;
        },

        hal.GPIOP => RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIOPEN,

        else => std.debug.panic("Unknown GPIO port.", .{}),
    }

    tmpreg.* = RCC.AHB4ENR;
}

fn sd1_clk_enable() void {
    RCC.AHB5ENR |= hal.RCC_AHB5ENR_SDMMC1EN;
    tmpreg.* = RCC.AHB5ENR;
}

fn sd1_force_reset() void {
    RCC.AHB5RSTR |= hal.RCC_AHB5RSTR_SDMMC1RST;
}

fn sd1_release_reset() void {
    RCC.AHB5RSTR &= ~hal.RCC_AHB5RSTR_SDMMC1RST;
}

pub const BasePin = struct {
    const Self = @This();

    port: *hal.GPIO_TypeDef,
    pin: u16,

    fn init(self: Self, mode: c_uint, pull: c_uint, speed: c_uint) !void {
        try gpio_clk_enable(self.port);

        const GPIO_InitStruct: hal.GPIO_InitTypeDef = hal.GPIO_InitTypeDef{
            .Pin = self.pin,
            .Mode = mode,
            .Pull = pull,
            .Speed = speed,
        };

        hal.HAL_GPIO_Init(self.port, &GPIO_InitStruct);
    }

    /// Initialize a pin as output
    pub fn as_out(self: Self, active: Active) !OutPin {
        const ret = OutPin{
            .base = self,
            .active = active,
        };

        try ret.init();

        return ret;
    }

    pub fn as_in(self: Self, active: Active) !InPin {
        const ret = InPin{
            .base = self,
            .active = active,
        };

        try ret.init();

        return ret;
    }
};

pub const OutPin = struct {
    const Self = @This();

    base: BasePin,
    active: Active,

    /// Configure the pin and set it at "off" state
    fn init(self: Self) !void {
        // TODO?: Something based on `self.active`
        try self.base.init(hal.GPIO_MODE_OUTPUT_PP, hal.GPIO_PULLUP, hal.GPIO_SPEED_FREQ_VERY_HIGH);
    }

    /// Set the **logical** output level (according to active-ness)
    pub fn set(self: Self, value: bool) void {
        const output = switch (self.active) {
            .Low => !value,
            .High => value,
        };

        const hal_out: c_uint = if (output) hal.GPIO_PIN_SET else hal.GPIO_PIN_RESET;

        hal.HAL_GPIO_WritePin(self.base.port, self.base.pin, hal_out);
    }

    /// Toggle the output voltage
    pub fn toggle(self: Self) void {
        hal.HAL_GPIO_TogglePin(self.base.port, self.base.pin);
    }
};

pub const InPin = struct {
    const Self = @This();

    base: BasePin,
    active: Active,

    /// Configure the pin
    fn init(self: Self) !void {
        const hal_pull = switch (self.active) {
            .Low => std.debug.panic("Unimplemented.", .{}),
            .High => hal.GPIO_PULLDOWN,
        };

        try self.base.init(hal.GPIO_MODE_INPUT, hal_pull, hal.GPIO_SPEED_FREQ_LOW);
    }

    /// Read input, takin into account the pull, to return "is button pressed"
    pub fn read(self: Self) bool {
        return switch (self.active) {
            .Low => std.debug.panic("Unimplemented.", .{}),
            .High => hal.HAL_GPIO_ReadPin(self.base.port, self.base.pin) == hal.GPIO_PIN_SET,
        };
    }
};

pub const SDType = struct {
    const Self = @This();

    instance: *hal.SDMMC_TypeDef,
    hsd: ?hal.SD_HandleTypeDef = null,

    pub fn ready(self: *Self) bool {
        if (self.hsd) |*hsd| {
            if (hal.HAL_SD_GetCardState(hsd) == hal.HAL_SD_CARD_TRANSFER) {
                return true;
            }
        }

        return false;
    }

    pub fn init(self: *Self) !void {
        // dont init again
        if (self.hsd != null) {
            return;
        }

        var hsd: hal.SD_HandleTypeDef = .{ .Instance = self.instance, .Init = .{
            .ClockEdge = hal.SDMMC_CLOCK_EDGE_FALLING,
            .ClockPowerSave = hal.SDMMC_CLOCK_POWER_SAVE_DISABLE,
            .BusWide = hal.SDMMC_BUS_WIDE_4B,
            .HardwareFlowControl = hal.SDMMC_HARDWARE_FLOW_CONTROL_DISABLE,
            .ClockDiv = 1,
        } };

        if (hal.HAL_SD_Init(&hsd) != hal.HAL_OK) {
            std.log.err("Could not initialize SD.", .{});
            return error.HalError;
        }

        // high speed (if supported)
        if (hal.HAL_SD_ConfigSpeedBusOperation(&hsd, hal.SDMMC_SPEED_MODE_HIGH) != hal.HAL_OK) {
            std.log.err("Trying to set high speed failed.", .{});
            return error.HalError;
        }

        for (0..500) |_| {
            if (hal.HAL_SD_GetCardState(&hsd) == hal.HAL_SD_CARD_TRANSFER) {
                self.hsd = hsd;
                return;
            }
        }

        std.log.err("SD did not enter ready state.", .{});
        return error.SDNotReady;
    }

    pub fn read(self: *Self, data: [*]u8, first_block: u32, n_blocks: u32) !void {
        if (self.hsd) |*hsd| {
            if (hal.HAL_SD_ReadBlocks(hsd, data, first_block, n_blocks, TIMEOUT) != hal.HAL_OK) {
                std.log.err("Failed reading.", .{});
                return error.HalError;
            }

            while (hal.HAL_SD_GetCardState(hsd) != hal.HAL_SD_CARD_TRANSFER) {}
        } else {
            std.log.err("SD was not ready.", .{});
            return error.SDNotReady;
        }
    }

    pub fn write(self: *Self, data: [*]const u8, first_block: u32, n_blocks: u32) !void {
        if (self.hsd) |*hsd| {
            if (hal.HAL_SD_WriteBlocks(hsd, data, first_block, n_blocks, TIMEOUT) != hal.HAL_OK) {
                std.log.err("Failed reading.", .{});
                return error.HalError;
            }

            while (hal.HAL_SD_GetCardState(hsd) != hal.HAL_SD_CARD_TRANSFER) {}
        } else {
            std.log.err("SD was not ready.", .{});
            return error.SDNotReady;
        }
    }

    pub fn card_info(self: *Self) !hal.HAL_SD_CardInfoTypeDef {
        if (self.hsd) |*hsd| {
            var info: hal.HAL_SD_CardInfoTypeDef = undefined;
            if (hal.HAL_SD_GetCardInfo(hsd, &info) != hal.HAL_OK) {
                return error.HalError;
            }
            return info;
        } else {
            std.log.err("SD was not ready.", .{});
            return error.SDNotReady;
        }
    }
};

pub export fn HAL_SD_MspInit(hsd: *hal.SD_HandleTypeDef) callconv(.C) void {
    HAL_SD_MspInit_Impl(hsd) catch std.log.err("Could not initialize SD.", .{});
}

fn HAL_SD_MspInit_Impl(hsd: *hal.SD_HandleTypeDef) !void {
    if (hsd.Instance != hal.SDMMC1) {
        std.debug.panic("Unknown SD peripheral.", .{});
    }

    var PeriphClkInit: hal.RCC_PeriphCLKInitTypeDef = .{
        .PeriphClockSelection = hal.RCC_PERIPHCLK_SDMMC12,
        .Sdmmc12ClockSelection = hal.RCC_SDMMC12CLKSOURCE_PLL2S,
    };
    if (hal.HAL_RCCEx_PeriphCLKConfig(&PeriphClkInit) != hal.HAL_OK) {
        std.log.err("Could not configure SD clock.", .{});
        return error.HalError;
    }

    sd1_clk_enable();
    try gpio_clk_enable(hal.GPIOC);
    try gpio_clk_enable(hal.GPIOD);

    var GPIO_InitStruct: hal.GPIO_InitTypeDef = .{
        .Pin = hal.GPIO_PIN_2,
        .Mode = hal.GPIO_MODE_AF_PP,
        .Pull = hal.GPIO_NOPULL,
        .Speed = hal.GPIO_SPEED_FREQ_HIGH,
        .Alternate = hal.GPIO_AF11_SDMMC1,
    };
    hal.HAL_GPIO_Init(hal.GPIOD, &GPIO_InitStruct);

    GPIO_InitStruct = .{
        .Pin = hal.GPIO_PIN_10,
        .Mode = hal.GPIO_MODE_AF_PP,
        .Pull = hal.GPIO_NOPULL,
        .Speed = hal.GPIO_SPEED_FREQ_HIGH,
        .Alternate = hal.GPIO_AF12_SDMMC1,
    };
    hal.HAL_GPIO_Init(hal.GPIOC, &GPIO_InitStruct);

    GPIO_InitStruct = .{
        .Pin = hal.GPIO_PIN_11 | hal.GPIO_PIN_12 | hal.GPIO_PIN_8 | hal.GPIO_PIN_9,
        .Mode = hal.GPIO_MODE_AF_PP,
        .Pull = hal.GPIO_NOPULL,
        .Speed = hal.GPIO_SPEED_FREQ_HIGH,
        .Alternate = hal.GPIO_AF11_SDMMC1,
    };
    hal.HAL_GPIO_Init(hal.GPIOC, &GPIO_InitStruct);

    var RCC_OscInitStruct: hal.RCC_OscInitTypeDef = undefined;
    RCC_OscInitStruct = .{
        .OscillatorType = hal.RCC_OSCILLATORTYPE_HSI,
        .HSIState = hal.RCC_HSI_ON,
        .HSIDiv = hal.RCC_HSI_DIV1,
        .HSICalibrationValue = hal.RCC_HSICALIBRATION_DEFAULT,
        .PLL1 = .{
            .PLLState = hal.RCC_PLL_ON,
            .PLLSource = hal.RCC_PLLSOURCE_HSI,
            .PLLM = 16,
            .PLLN = 275,
            .PLLP = 2,
            .PLLQ = 2,
            .PLLR = 2,
            .PLLS = 2,
            .PLLT = 2,
            .PLLFractional = 0,
        },
        .PLL2 = .{ .PLLState = hal.RCC_PLL_NONE },
        .PLL3 = .{ .PLLState = hal.RCC_PLL_NONE },
    };
    if (hal.HAL_RCC_OscConfig(&RCC_OscInitStruct) != hal.HAL_OK) {
        return error.HalError;
    }

    var RCC_PeriphClkInit: hal.RCC_PeriphCLKInitTypeDef = undefined;
    RCC_PeriphClkInit = .{
        .PeriphClockSelection = hal.RCC_PERIPHCLK_SDMMC12,
        .Sdmmc12ClockSelection = hal.RCC_SDMMC12CLKSOURCE_PLL2S,
    };
    if (hal.HAL_RCCEx_PeriphCLKConfig(&RCC_PeriphClkInit) != hal.HAL_OK) {
        return error.HalError;
    }

    sd1_force_reset();
    sd1_release_reset();
}

// ^ Types
// -------
// v Names

// Button
pub const USER = BasePin{
    .port = hal.GPIOC,
    .pin = hal.GPIO_PIN_13,
};

// LEDs
pub const LD1 = BasePin{
    .port = hal.GPIOO,
    .pin = hal.GPIO_PIN_1,
};

pub const LD2 = BasePin{
    .port = hal.GPIOO,
    .pin = hal.GPIO_PIN_5,
};

pub const LD3 = BasePin{
    .port = hal.GPIOM,
    .pin = hal.GPIO_PIN_2,
};

pub const LD4 = BasePin{
    .port = hal.GPIOM,
    .pin = hal.GPIO_PIN_3,
};

pub const LEDS = .{ LD1, LD2, LD3, LD4 };

// SD
pub const SD = SDType{
    .instance = hal.SDMMC1,
};
