//! Import the C code used by the project, and do so a single time.
//! Also provide a function to get the HAL properly configured.

const std = @import("std");

const c = @cImport({
    @cInclude("stm32h7rsxx_hal.h");
    @cInclude("stm32h7rsxx_hal_conf.h");
});

pub usingnamespace c;

pub fn early_init() void {
    // Initialize MCU
    c.HAL_MPU_Disable();
    // hal.SCB_EnableICache(); // zig does not like :/
    // hal.SCB_EnableDCache(); // zig does not like :/
    c.SystemCoreClockUpdate();

    const ret = c.HAL_Init();
    if (ret != c.HAL_OK) {
        std.debug.panic("HAL initialization failed.", .{});
    }
}

/// This gets called by HAL_Init for board-specific init
export fn HAL_MspInit() callconv(.C) void {
    HAL_MspInit_Impl() catch std.log.err("HAL_MspInit_Impl failed.", .{});
}

export fn HAL_MspDeInit() callconv(.C) void {}

// Enable power on M and O ports
fn HAL_MspInit_Impl() !void {
    const ret = c.HAL_PWREx_EnableUSBVoltageDetector();
    if (ret != c.HAL_OK) {
        std.log.err("Could not enable USB voltage level detector", .{});
        return error.HalError;
    }

    c.HAL_PWREx_EnableXSPIM1();
}
