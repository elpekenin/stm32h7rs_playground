//! Use the SD/MMC peripheral

const std = @import("std");

const hal = @import("../hal.zig");
const digital = @import("digital.zig");

const clocks = @import("clocks.zig");

const TIMEOUT = 500;

pub const SDType = struct {
    const Self = @This();

    instance: *hal.SDMMC_TypeDef,
    detection: digital.BasePin,

    hsd: ?hal.SD_HandleTypeDef = null,

    /// Check if the card is inserter
    pub fn is_connected(self: *Self) bool {
        const in = self.detection.as_in(.High) orelse return false;
        return in.read();
    }

    /// Check if this instance has been initialized.
    pub fn is_initialized(self: *Self) bool {
        return self.hsd != null;
    }

    /// Check if the card is ready to receive a message.
    pub fn is_ready(self: *Self) bool {
        if (self.hsd) |*hsd| {
            return hal.HAL_SD_GetCardState(hsd) == hal.HAL_SD_CARD_TRANSFER;
        }

        return false;
    }

    /// Give the card some time to get ready, return whether it is.
    fn wait_ready(self: *Self) bool {
        for (0..TIMEOUT) |_| {
            if (self.is_ready()) {
                return true;
            }
        }

        return false;
    }

    /// Initialize the hardware.
    pub fn init(self: *Self) !void {
        if (self.is_initialized()) {
            return;
        }

        var hsd = std.mem.zeroes(hal.SD_HandleTypeDef);
        hsd = .{ .Instance = self.instance, .Init = .{
            .ClockEdge = hal.SDMMC_CLOCK_EDGE_FALLING,
            .ClockPowerSave = hal.SDMMC_CLOCK_POWER_SAVE_DISABLE,
            .BusWide = hal.SDMMC_BUS_WIDE_4B,
            .HardwareFlowControl = hal.SDMMC_HARDWARE_FLOW_CONTROL_ENABLE,
            .ClockDiv = 1,
        } };

        const ret = hal.HAL_SD_Init(&hsd);
        if (ret != hal.HAL_OK) {
            std.log.err("HAL_SD_Init failed. Error: 0x{X:>8}.", .{hsd.ErrorCode});
            return error.HalError;
        }

        // high speed (if supported)
        if (hal.HAL_SD_ConfigSpeedBusOperation(&hsd, hal.SDMMC_SPEED_MODE_HIGH) != hal.HAL_OK) {
            std.log.err("Trying to set high speed failed.", .{});
            return error.HalError;
        }

        if (self.wait_ready()) {
            self.hsd = hsd;
            return;
        }

        std.log.err("SD did not enter ready state.", .{});
        return error.SDNotReady;
    }

    /// Read data from card.
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

    /// Write data onto card.
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

    /// Get card's information.
    pub fn card_info(self: *Self) !hal.HAL_SD_CardInfoTypeDef {
        if (self.hsd) |*hsd| {
            var info = std.mem.zeroes(hal.HAL_SD_CardInfoTypeDef);
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

/// Low-level init used by HAL_SD_Init
pub export fn HAL_SD_MspInit(hsd: *hal.SD_HandleTypeDef) callconv(.C) void {
    HAL_SD_MspInit_Impl(hsd, false) catch return;
}

fn HAL_SD_MspInit_Impl(hsd: *hal.SD_HandleTypeDef, extra_init: bool) !void {
    if (hsd.Instance != hal.SDMMC1) {
        std.debug.panic("Unknown SD peripheral.", .{});
    }

    var PeriphClkInit = std.mem.zeroes(hal.RCC_PeriphCLKInitTypeDef);
    PeriphClkInit = .{
        .PeriphClockSelection = hal.RCC_PERIPHCLK_SDMMC12,
        .Sdmmc12ClockSelection = hal.RCC_SDMMC12CLKSOURCE_PLL2S,
    };
    if (hal.HAL_RCCEx_PeriphCLKConfig(&PeriphClkInit) != hal.HAL_OK) {
        std.log.err("HAL_RCCEx_PeriphCLKConfig: fail.", .{});
        return error.HalError;
    }

    clocks.enable.sdmmc1();
    try clocks.enable.gpio(hal.GPIOC);
    try clocks.enable.gpio(hal.GPIOD);

    var GPIO_InitStruct = std.mem.zeroes(hal.GPIO_InitTypeDef);

    GPIO_InitStruct = .{
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
        .Pin = hal.GPIO_PIN_8 | hal.GPIO_PIN_9 | hal.GPIO_PIN_11 | hal.GPIO_PIN_12,
        .Mode = hal.GPIO_MODE_AF_PP,
        .Pull = hal.GPIO_NOPULL,
        .Speed = hal.GPIO_SPEED_FREQ_HIGH,
        .Alternate = hal.GPIO_AF11_SDMMC1,
    };
    hal.HAL_GPIO_Init(hal.GPIOC, &GPIO_InitStruct);

    // ---- Is this needed?
    if (extra_init) {
        var RCC_OscInitStruct = std.mem.zeroes(hal.RCC_OscInitTypeDef);
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
            std.log.err("HAL_RCC_OscConfig on HAL_SD_MspInit_Impl", .{});
            return error.HalError;
        }

        var RCC_PeriphClkInit = std.mem.zeroes(hal.RCC_PeriphCLKInitTypeDef);
        RCC_PeriphClkInit = .{
            .PeriphClockSelection = hal.RCC_PERIPHCLK_SDMMC12,
            .Sdmmc12ClockSelection = hal.RCC_SDMMC12CLKSOURCE_PLL2S,
        };
        if (hal.HAL_RCCEx_PeriphCLKConfig(&RCC_PeriphClkInit) != hal.HAL_OK) {
            std.log.err("HAL_RCCEx_PeriphCLKConfig on HAL_SD_MspInit_Impl", .{});
            return error.HalError;
        }

        clocks.force_reset.sdmmc1();
        clocks.release_reset.sdmmc1();
    }
}
