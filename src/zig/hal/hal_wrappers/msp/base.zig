const std = @import("std");
const hal = @import("../../hal.zig");

export fn HAL_MspInit() callconv(.C) void {
    if (hal.c.HAL_PWREx_ConfigSupply(hal.c.PWR_DIRECT_SMPS_SUPPLY) != hal.c.HAL_OK) {
        std.debug.panic("HAL_PWREx_ConfigSupply", .{});
    }

    hal.zig.rcc.SBS.enable();

    hal.c.HAL_PWREx_EnableXSPIM1();
    hal.c.HAL_PWREx_EnableXSPIM2();

    var rcc_config = std.mem.zeroInit(
        hal.c.RCC_OscInitTypeDef,
        .{
            .OscillatorType = hal.c.RCC_OSCILLATORTYPE_CSI,
            .CSIState = hal.c.RCC_CSI_ON,
        },
    );
    try hal.zig.rcc.config(&rcc_config);

    hal.c.HAL_SBS_ConfigCompensationCell(hal.c.SBS_IO_XSPI1_CELL, hal.c.SBS_IO_CELL_CODE, 0, 0);
    hal.c.HAL_SBS_ConfigCompensationCell(hal.c.SBS_IO_XSPI2_CELL, hal.c.SBS_IO_CELL_CODE, 0, 0);

    hal.c.HAL_SBS_EnableCompensationCell(hal.c.SBS_IO_XSPI1_CELL);
    hal.c.HAL_SBS_EnableCompensationCell(hal.c.SBS_IO_XSPI2_CELL);

    while (hal.c.HAL_SBS_GetCompensationCellReadyStatus(hal.c.SBS_IO_XSPI1_CELL_READY) != 1) {}
    while (hal.c.HAL_SBS_GetCompensationCellReadyStatus(hal.c.SBS_IO_XSPI2_CELL_READY) != 1) {}

    hal.c.HAL_SBS_EnableIOSpeedOptimize(hal.c.SBS_IO_XSPI1_HSLV);
    hal.c.HAL_SBS_EnableIOSpeedOptimize(hal.c.SBS_IO_XSPI2_HSLV);
}
