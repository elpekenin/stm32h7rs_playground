const std = @import("std");
const hal = @import("../hal.zig");

export fn HAL_MspInit() callconv(.C) void {
    if (hal.c.HAL_PWREx_ConfigSupply(hal.c.PWR_DIRECT_SMPS_SUPPLY) != hal.c.HAL_OK) {
        std.debug.panic("HAL_PWREx_ConfigSupply", .{});
    }

    hal.zig.clocks.enable.sbs();

    hal.c.HAL_PWREx_EnableXSPIM1();
    hal.c.HAL_PWREx_EnableXSPIM2();

    hal.c.HAL_SBS_EnableIOSpeedOptimize(hal.c.SBS_IO_XSPI1_HSLV);
    hal.c.HAL_SBS_EnableIOSpeedOptimize(hal.c.SBS_IO_XSPI2_HSLV);
}
