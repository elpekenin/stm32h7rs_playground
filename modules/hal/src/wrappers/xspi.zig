//! Functions reused across XSPI devices (flash and RAM)

// TODO: Run some tests to validate if pointers are indeed NOT modified

const std = @import("std");
const logger = std.log.scoped(.xspi);

const hal = @import("../mod.zig");
const c = hal.c;

pub fn init(hxspi: *c.XSPI_HandleTypeDef) !void {
    if (c.HAL_XSPI_Init(hxspi) != c.HAL_OK) {
        logger.err("HAL_XSPI_Init", .{});
        return error.HalError;
    }
}

pub fn configure(hxspi: *c.XSPI_HandleTypeDef, config: *const c.XSPIM_CfgTypeDef) !void {
    if (c.HAL_XSPIM_Config(hxspi, @constCast(config), c.HAL_XSPI_TIMEOUT_DEFAULT_VALUE) != c.HAL_OK) {
        logger.err("HAL_XSPIM_Config", .{});
        return error.HalError;
    }
}

pub fn command(hxspi: *c.XSPI_HandleTypeDef, cmd: *const c.XSPI_RegularCmdTypeDef) !void {
    if (c.HAL_XSPI_Command(hxspi, @constCast(cmd), c.HAL_XSPI_TIMEOUT_DEFAULT_VALUE) != c.HAL_OK) {
        logger.err("HAL_XSPI_Command", .{});
        return error.HalError;
    }
}

pub fn polling(hxspi: *c.XSPI_HandleTypeDef, config: *const c.XSPI_AutoPollingTypeDef) !void {
    if (c.HAL_XSPI_AutoPolling(hxspi, @constCast(config), c.HAL_XSPI_TIMEOUT_DEFAULT_VALUE) != c.HAL_OK) {
        logger.err("HAL_XSPI_AutoPolling", .{});
        return error.HalError;
    }
}

pub fn transmit(hxspi: *c.XSPI_HandleTypeDef, buffer: [*]const u8) !void {
    if (c.HAL_XSPI_Transmit(hxspi, buffer, c.HAL_XSPI_TIMEOUT_DEFAULT_VALUE) != c.HAL_OK) {
        logger.err("HAL_XSPI_Transmit", .{});
        return error.HalError;
    }
}

pub fn receive(hxspi: *c.XSPI_HandleTypeDef, buffer: [*]u8) !void {
    if (c.HAL_XSPI_Receive(hxspi, buffer, c.HAL_XSPI_TIMEOUT_DEFAULT_VALUE) != c.HAL_OK) {
        logger.err("HAL_XSPI_Receive", .{});
        return error.HalError;
    }
}

pub fn printError(hxspi: *const c.XSPI_HandleTypeDef) void {
    logger.err("Error: 0b{b:0>32}", .{hxspi.ErrorCode});
    logger.err("State: 0b{b:0>32}", .{hxspi.State});
}
