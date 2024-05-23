//! Interrupt handlers

const std = @import("std");
const hal = @import("../hal.zig");

export fn SDMMC1_IRQHandler() callconv(.C) void {
    std.log.info("SDMMC1_IRQHandler", .{});
    hal.c.HAL_SD_IRQHandler(&hal.zig.sd.hsd);
}
