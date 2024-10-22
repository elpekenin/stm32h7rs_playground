//! Use the SD/MMC peripheral

const std = @import("std");
const logger = std.log.scoped(.sd);

const hal = @import("../hal.zig");

const clocks = @import("rcc.zig");

const TIMEOUT = 500;

var hsd = std.mem.zeroes(hal.c.SD_HandleTypeDef);

const state = struct {
    var init = false;
};

/// Print the error code stored in hsd
fn print_error() void {
    logger.err("Error: 0b{b:0>32}", .{hsd.ErrorCode});
    logger.err("State: 0b{b:0>32}", .{hsd.Instance.*.STA});
}

/// Check if the card is inserter
pub fn is_connected() bool {
    return hal.dk.SD.DET.read();
}

/// Check if this instance has been initialized.
pub fn is_initialized() bool {
    return state.init;
}

/// Check if the card is ready to receive a message.
pub fn is_ready() bool {
    return hal.c.HAL_SD_GetCardState(&hsd) == hal.c.HAL_SD_CARD_TRANSFER;
}

/// Give the card some time to get ready, return whether it is.
fn wait_ready() bool {
    for (0..TIMEOUT) |_| {
        if (is_ready()) {
            return true;
        }
    }

    return false;
}

/// Initialize the hardware.
pub fn init() !void {
    if (is_initialized()) {
        return;
    }

    errdefer print_error();

    hsd = .{ .Instance = hal.c.SDMMC1, .Init = .{
        .ClockEdge = hal.c.SDMMC_CLOCK_EDGE_FALLING,
        .ClockPowerSave = hal.c.SDMMC_CLOCK_POWER_SAVE_DISABLE,
        .BusWide = hal.c.SDMMC_BUS_WIDE_4B,
        .HardwareFlowControl = hal.c.SDMMC_HARDWARE_FLOW_CONTROL_ENABLE,
        .ClockDiv = 2,
    } };

    const ret = hal.c.HAL_SD_Init(&hsd);
    if (ret != hal.c.HAL_OK) {
        return error.HalError;
    }

    // TODO?: Try and change to high speed mode. Does HAL_SD_Init already use
    //        fastest compatible mode?

    // Not needed?
    // if (!wait_ready()) {
    //     logger.err("Ready state", .{});
    //     return error.NotReady;
    // }

    state.init = true;
}

/// Read data from card.
pub fn read(data: [*]u8, first_block: u32, n_blocks: u32) !void {
    if (!is_initialized()) {
        return error.NotReady;
    }

    if (hal.c.HAL_SD_ReadBlocks(&hsd, data, first_block, n_blocks, TIMEOUT) != hal.c.HAL_OK) {
        logger.err("SD read", .{});
        return error.HalError;
    }

    while (hal.c.HAL_SD_GetCardState(&hsd) != hal.c.HAL_SD_CARD_TRANSFER) {}
}

/// Write data onto card.
pub fn write(data: [*]const u8, first_block: u32, n_blocks: u32) !void {
    if (!is_initialized()) {
        return error.NotReady;
    }

    if (hal.c.HAL_SD_WriteBlocks(&hsd, data, first_block, n_blocks, TIMEOUT) != hal.c.HAL_OK) {
        logger.err("SD write", .{});
        return error.HalError;
    }

    while (hal.c.HAL_SD_GetCardState(&hsd) != hal.c.HAL_SD_CARD_TRANSFER) {}
}

/// Get card's information.
pub fn card_info() !hal.c.HAL_SD_CardInfoTypeDef {
    if (!is_initialized()) {
        return error.NotReady;
    }

    var info = std.mem.zeroes(hal.c.HAL_SD_CardInfoTypeDef);
    if (hal.c.HAL_SD_GetCardInfo(&hsd, &info) != hal.c.HAL_OK) {
        return error.HalError;
    }

    return info;
}

/// Do not use, only public for vector_table.zig to access it
pub fn isr() callconv(.C) void {
    logger.debug("SDMMC1_IRQHandler", .{});
    hal.c.HAL_SD_IRQHandler(&hsd);
}
