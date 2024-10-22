//! Functions reused across XSPI devices (flash and RAM)

const std = @import("std");
const logger = std.log.scoped(.xspi);

const hal = @import("../hal.zig");

pub fn init(hxspi: *hal.c.XSPI_HandleTypeDef) !void {
    if (hal.c.HAL_XSPI_Init(hxspi) != hal.c.HAL_OK) {
        logger.err("HAL_XSPI_Init", .{});
        return error.HalError;
    }
}

pub fn configure(hxspi: *hal.c.XSPI_HandleTypeDef, m_config: *hal.c.XSPIM_CfgTypeDef) !void {
    if (hal.c.HAL_XSPIM_Config(hxspi, m_config, hal.c.HAL_XSPI_TIMEOUT_DEFAULT_VALUE) != hal.c.HAL_OK) {
        logger.err("HAL_XSPIM_Config", .{});
        return error.HalError;
    }
}

pub fn send_command(hxspi: *hal.c.XSPI_HandleTypeDef, command: *hal.c.XSPI_RegularCmdTypeDef) !void {
    if (hal.c.HAL_XSPI_Command(hxspi, command, hal.c.HAL_XSPI_TIMEOUT_DEFAULT_VALUE) != hal.c.HAL_OK) {
        logger.err("HAL_XSPI_Command", .{});
        return error.HalError;
    }
}

pub fn auto_polling(hxspi: *hal.c.XSPI_HandleTypeDef, config: *hal.c.XSPI_AutoPollingTypeDef) !void {
    if (hal.c.HAL_XSPI_AutoPolling(hxspi, config, hal.c.HAL_XSPI_TIMEOUT_DEFAULT_VALUE) != hal.c.HAL_OK) {
        logger.err("HAL_XSPI_AutoPolling", .{});
        return error.HalError;
    }
}

pub fn transmit(hxspi: *hal.c.XSPI_HandleTypeDef, buffer: [*]const u8) !void {
    if (hal.c.HAL_XSPI_Transmit(hxspi, buffer, hal.c.HAL_XSPI_TIMEOUT_DEFAULT_VALUE) != hal.c.HAL_OK) {
        logger.err("HAL_XSPI_Transmit", .{});
        return error.HalError;
    }
}

pub fn receive(hxspi: *hal.c.XSPI_HandleTypeDef, buffer: [*]u8) !void {
    if (hal.c.HAL_XSPI_Receive(hxspi, buffer, hal.c.HAL_XSPI_TIMEOUT_DEFAULT_VALUE) != hal.c.HAL_OK) {
        logger.err("HAL_XSPI_Receive", .{});
        return error.HalError;
    }
}

pub fn print_error(hxspi: *hal.c.XSPI_HandleTypeDef) void {
    logger.err("Error: 0b{b:0>32}", .{hxspi.ErrorCode});
    logger.err("State: 0b{b:0>32}", .{hxspi.State});
}
