//! Use the SD/MMC peripheral

const std = @import("std");
const hal = @import("../hal.zig");

const digital = hal.zig.digital;

const clocks = @import("clocks.zig");

const TIMEOUT = 500;

pub const SDType = struct {
    const Self = @This();

    instance: *hal.c.SDMMC_TypeDef,
    hsd: hal.c.SD_HandleTypeDef,
    detection: hal.zig.BasePin,
    __init: bool,

    /// Print the error code stored in hsd
    pub fn print_error(self: Self) void {
        std.log.err("Code: 0b{b:0>32}", .{self.hsd.ErrorCode});
        std.log.err(" ARG: 0b{b:0>32}", .{self.instance.ARG});
        std.log.err(" CMD: 0b{b:0>32}", .{self.instance.CMD});
        std.log.err(" STA: 0b{b:0>32}", .{self.instance.STA});
    }

    /// Check if the card is inserter
    pub fn is_connected(self: Self) bool {
        return self.detection.as_in(.Low).read();
    }

    /// Check if this instance has been initialized.
    pub fn is_initialized(self: Self) bool {
        return self.__init;
    }

    /// Check if the card is ready to receive a message.
    pub fn is_ready(self: *Self) bool {
        return hal.c.HAL_SD_GetCardState(&self.hsd) == hal.c.HAL_SD_CARD_TRANSFER;
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

    /// Create an instance of this class
    pub fn new(instance: *hal.c.SDMMC_TypeDef, detection: hal.zig.BasePin) Self {
        return Self{ .instance = instance, .hsd = std.mem.zeroes(hal.c.SD_HandleTypeDef), .detection = detection, .__init = false };
    }

    /// Initialize the hardware.
    pub fn init(self: *Self) !void {
        if (self.is_initialized()) {
            return;
        }

        errdefer self.print_error();

        // force init of detection pin
        if (!self.is_connected()) {
            std.log.err("No card", .{});
            return error.SDNotReady;
        }

        self.hsd = .{ .Instance = self.instance, .Init = .{
            .ClockEdge = hal.c.SDMMC_CLOCK_EDGE_FALLING,
            .ClockPowerSave = hal.c.SDMMC_CLOCK_POWER_SAVE_DISABLE,
            .BusWide = hal.c.SDMMC_BUS_WIDE_4B,
            .HardwareFlowControl = hal.c.SDMMC_HARDWARE_FLOW_CONTROL_ENABLE,
            .ClockDiv = 2,
        } };

        const ret = hal.c.HAL_SD_Init(&self.hsd);
        if (ret != hal.c.HAL_OK) {
            return error.HalError;
        }

        // if (!self.wait_ready()) {
        //     std.log.err("Ready state", .{});
        //     return error.SDNotReady;
        // }

        self.__init = true;
    }

    /// Read data from card.
    pub fn read(self: *Self, data: [*]u8, first_block: u32, n_blocks: u32) !void {
        if (!self.is_initialized()) {
            return error.SDNotReady;
        }

        if (hal.c.HAL_SD_ReadBlocks(&self.hsd, data, first_block, n_blocks, TIMEOUT) != hal.c.HAL_OK) {
            std.log.err("SD read", .{});
            return error.HalError;
        }

        while (hal.c.HAL_SD_GetCardState(&self.hsd) != hal.c.HAL_SD_CARD_TRANSFER) {}
    }

    /// Write data onto card.
    pub fn write(self: *Self, data: [*]const u8, first_block: u32, n_blocks: u32) !void {
        if (!self.is_initialized()) {
            return error.SDNotReady;
        }

        if (hal.c.HAL_SD_WriteBlocks(&self.hsd, data, first_block, n_blocks, TIMEOUT) != hal.c.HAL_OK) {
            std.log.err("SD write", .{});
            return error.HalError;
        }

        while (hal.c.HAL_SD_GetCardState(&self.hsd) != hal.c.HAL_SD_CARD_TRANSFER) {}
    }

    /// Get card's information.
    pub fn card_info(self: *Self) !hal.c.HAL_SD_CardInfoTypeDef {
        if (!self.is_initialized()) {
            return error.SDNotReady;
        }

        var info = std.mem.zeroes(hal.c.HAL_SD_CardInfoTypeDef);
        if (hal.c.HAL_SD_GetCardInfo(&self.hsd, &info) != hal.c.HAL_OK) {
            return error.HalError;
        }

        return info;
    }
};
