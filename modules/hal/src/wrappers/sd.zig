//! Use the SD/MMC peripheral

const std = @import("std");
const logger = std.log.scoped(.sd);

const hal = @import("../hal.zig");
const c = hal.c;

const clocks = @import("rcc.zig");

const TIMEOUT = 500;

var hsd = std.mem.zeroes(c.SD_HandleTypeDef);

const state = struct {
    var initialized = false;
};

/// Print the error code stored in hsd
fn printError() void {
    logger.err("Error: 0b{b:0>32}", .{hsd.ErrorCode});
    logger.err("State: 0b{b:0>32}", .{hsd.Instance.*.STA});
}

/// Check if the card is inserter
pub fn connected() bool {
    return hal.bsp.SD.DET.read();
}

/// Check if this instance has been initialized.
pub fn initialized() bool {
    return state.initialized;
}

/// Check if the card is ready to receive a message.
pub fn ready() bool {
    return c.HAL_SD_GetCardState(&hsd) == c.HAL_SD_CARD_TRANSFER;
}

/// Give the card some time to get ready, return whether it is.
fn wait() bool {
    for (0..TIMEOUT) |_| {
        if (ready()) {
            return true;
        }
    }

    return false;
}

/// Initialize the hardware.
pub fn init() !void {
    if (initialized()) {
        return;
    }

    errdefer printError();

    hsd = .{ .Instance = c.SDMMC1, .Init = .{
        .ClockEdge = c.SDMMC_CLOCK_EDGE_FALLING,
        .ClockPowerSave = c.SDMMC_CLOCK_POWER_SAVE_DISABLE,
        .BusWide = c.SDMMC_BUS_WIDE_4B,
        .HardwareFlowControl = c.SDMMC_HARDWARE_FLOW_CONTROL_ENABLE,
        .ClockDiv = 2,
    } };

    const ret = c.HAL_SD_Init(&hsd);
    if (ret != c.HAL_OK) {
        return error.HalError;
    }

    // TODO?: Try and change to high speed mode. Does HAL_SD_Init already use
    //        fastest compatible mode?

    // Not needed?
    // if (!wait_ready()) {
    //     logger.err("Ready state", .{});
    //     return error.NotReady;
    // }

    state.initialized = true;
}

/// Read data from card.
pub fn read(data: [*]u8, first_block: u32, n_blocks: u32) !void {
    if (!initialized()) {
        return error.NotReady;
    }

    if (c.HAL_SD_ReadBlocks(&hsd, data, first_block, n_blocks, TIMEOUT) != c.HAL_OK) {
        logger.err("SD read", .{});
        return error.HalError;
    }

    while (c.HAL_SD_GetCardState(&hsd) != c.HAL_SD_CARD_TRANSFER) {}
}

/// Write data onto card.
pub fn write(data: [*]const u8, first_block: u32, n_blocks: u32) !void {
    if (!initialized()) {
        return error.NotReady;
    }

    if (c.HAL_SD_WriteBlocks(&hsd, data, first_block, n_blocks, TIMEOUT) != c.HAL_OK) {
        logger.err("SD write", .{});
        return error.HalError;
    }

    while (c.HAL_SD_GetCardState(&hsd) != c.HAL_SD_CARD_TRANSFER) {}
}

/// Get card's information.
pub fn info() !c.HAL_SD_CardInfoTypeDef {
    if (!initialized()) {
        return error.NotReady;
    }

    var card_info = std.mem.zeroes(c.HAL_SD_CardInfoTypeDef);
    if (c.HAL_SD_GetCardInfo(&hsd, &card_info) != c.HAL_OK) {
        return error.HalError;
    }

    return card_info;
}

/// Do not use, only public for vector_table.zig to access it
pub fn isr() callconv(.C) void {
    logger.debug("SDMMC1_IRQHandler", .{});
    c.HAL_SD_IRQHandler(&hsd);
}
