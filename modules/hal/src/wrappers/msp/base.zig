const std = @import("std");
const hal = @import("../../mod.zig");
const c = hal.c;

export fn HAL_MspInit() void {
    if (c.HAL_PWREx_ConfigSupply(c.PWR_DIRECT_SMPS_SUPPLY) != c.HAL_OK) {
        std.debug.panic("HAL_PWREx_ConfigSupply", .{});
    }

    hal.zig.rcc.SBS.enable();

    c.HAL_PWREx_EnableXSPIM1();
    c.HAL_PWREx_EnableXSPIM2();

    var rcc_config = std.mem.zeroInit(
        c.RCC_OscInitTypeDef,
        .{
            .OscillatorType = c.RCC_OSCILLATORTYPE_CSI,
            .CSIState = c.RCC_CSI_ON,
        },
    );
    try hal.zig.rcc.config(&rcc_config);

    c.HAL_SBS_ConfigCompensationCell(c.SBS_IO_XSPI1_CELL, c.SBS_IO_CELL_CODE, 0, 0);
    c.HAL_SBS_ConfigCompensationCell(c.SBS_IO_XSPI2_CELL, c.SBS_IO_CELL_CODE, 0, 0);

    c.HAL_SBS_EnableCompensationCell(c.SBS_IO_XSPI1_CELL);
    c.HAL_SBS_EnableCompensationCell(c.SBS_IO_XSPI2_CELL);

    while (c.HAL_SBS_GetCompensationCellReadyStatus(c.SBS_IO_XSPI1_CELL_READY) != 1) {}
    while (c.HAL_SBS_GetCompensationCellReadyStatus(c.SBS_IO_XSPI2_CELL_READY) != 1) {}

    c.HAL_SBS_EnableIOSpeedOptimize(c.SBS_IO_XSPI1_HSLV);
    c.HAL_SBS_EnableIOSpeedOptimize(c.SBS_IO_XSPI2_HSLV);
}
