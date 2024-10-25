//! Functions reused across XSPI devices (flash and RAM)

const std = @import("std");
const logger = std.log.scoped(.xspi);

const hal = @import("../hal.zig");
const c = hal.c;

pub fn init(hxspi: *c.XSPI_HandleTypeDef) !void {
    if (c.HAL_XSPI_Init(hxspi) != c.HAL_OK) {
        logger.err("HAL_XSPI_Init", .{});
        return error.HalError;
    }
}

pub fn configure(hxspi: *c.XSPI_HandleTypeDef, m_config: *c.XSPIM_CfgTypeDef) !void {
    if (c.HAL_XSPIM_Config(hxspi, m_config, c.HAL_XSPI_TIMEOUT_DEFAULT_VALUE) != c.HAL_OK) {
        logger.err("HAL_XSPIM_Config", .{});
        return error.HalError;
    }
}

pub fn send_command(hxspi: *c.XSPI_HandleTypeDef, command: *c.XSPI_RegularCmdTypeDef) !void {
    if (c.HAL_XSPI_Command(hxspi, command, c.HAL_XSPI_TIMEOUT_DEFAULT_VALUE) != c.HAL_OK) {
        logger.err("HAL_XSPI_Command", .{});
        return error.HalError;
    }
}

pub fn auto_polling(hxspi: *c.XSPI_HandleTypeDef, config: *c.XSPI_AutoPollingTypeDef) !void {
    if (c.HAL_XSPI_AutoPolling(hxspi, config, c.HAL_XSPI_TIMEOUT_DEFAULT_VALUE) != c.HAL_OK) {
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

pub fn print_error(hxspi: *c.XSPI_HandleTypeDef) void {
    logger.err("Error: 0b{b:0>32}", .{hxspi.ErrorCode});
    logger.err("State: 0b{b:0>32}", .{hxspi.State});
}
