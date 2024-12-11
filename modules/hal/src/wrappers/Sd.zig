//! Use the SD/MMC peripheral

const std = @import("std");
const logger = std.log.scoped(.sd);

const hal = @import("../mod.zig");
const c = hal.c;
const bsp = hal.bsp;

const clocks = @import("rcc.zig");

const Self = @This();
const TIMEOUT = 500;

hsd: c.SD_HandleTypeDef,

/// Print the error code stored in hsd
fn printError(self: *const Self) void {
    logger.err("Error: 0b{b:0>32}", .{self.hsd.ErrorCode});
    logger.err("State: 0b{b:0>32}", .{self.hsd.Instance.*.STA});
}

/// Check if the card is inserter
pub fn connected(_: *const Self) bool {
    return hal.bsp.SD.DET.read();
}

/// Check if this instance has been initialized.
pub fn initialized(_: *const Self) bool {
    return true;
}

/// Check if the card is ready to receive a message.
pub fn ready(self: *const Self) bool {
    return c.HAL_SD_GetCardState(&self.hsd) == c.HAL_SD_CARD_TRANSFER;
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
pub fn new() !Self {
    var self: Self = .{
        .hsd = .{
            .Instance = c.SDMMC1,
            .Init = .{
                .ClockEdge = c.SDMMC_CLOCK_EDGE_FALLING,
                .ClockPowerSave = c.SDMMC_CLOCK_POWER_SAVE_DISABLE,
                .BusWide = c.SDMMC_BUS_WIDE_4B,
                .HardwareFlowControl = c.SDMMC_HARDWARE_FLOW_CONTROL_ENABLE,
                .ClockDiv = 2,
            },
        },
    };

    errdefer self.printError();

    const ret = c.HAL_SD_Init(&self.hsd);
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

    return self;
}

/// Read data from card.
pub fn read(self: *Self, data: [*]u8, first_block: u32, n_blocks: u32) !void {
    if (c.HAL_SD_ReadBlocks(&self.hsd, data, first_block, n_blocks, TIMEOUT) != c.HAL_OK) {
        logger.err("SD read", .{});
        return error.HalError;
    }

    while (c.HAL_SD_GetCardState(&self.hsd) != c.HAL_SD_CARD_TRANSFER) {}
}

/// Write data onto card.
pub fn write(self: *Self, data: [*]const u8, first_block: u32, n_blocks: u32) !void {
    if (c.HAL_SD_WriteBlocks(&self.hsd, data, first_block, n_blocks, TIMEOUT) != c.HAL_OK) {
        logger.err("SD write", .{});
        return error.HalError;
    }

    while (c.HAL_SD_GetCardState(&self.hsd) != c.HAL_SD_CARD_TRANSFER) {}
}

/// Get card's information.
pub fn info(self: *Self) !c.HAL_SD_CardInfoTypeDef {
    var card_info = std.mem.zeroes(c.HAL_SD_CardInfoTypeDef);
    if (c.HAL_SD_GetCardInfo(&self.hsd, &card_info) != c.HAL_OK) {
        return error.HalError;
    }

    return card_info;
}
