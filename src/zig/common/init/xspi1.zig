//! Initialize XSPI1

const std = @import("std");
const hal = @import("../hal.zig");

pub fn init() void {
    var hxspi1 = std.mem.zeroes(hal.c.XSPI_HandleTypeDef);
    hxspi1 = .{ .Instance = hal.c.XSPI1, .Init = .{
        .FifoThresholdByte = 2,
        .MemoryMode = hal.c.HAL_XSPI_SINGLE_MEM,
        .MemoryType = hal.c.HAL_XSPI_MEMTYPE_APMEM_16BITS,
        .MemorySize = hal.c.HAL_XSPI_SIZE_32GB,
        .ChipSelectHighTimeCycle = 1,
        .FreeRunningClock = hal.c.HAL_XSPI_FREERUNCLK_DISABLE,
        .ClockMode = hal.c.HAL_XSPI_CLOCK_MODE_0,
        .WrapSize = hal.c.HAL_XSPI_WRAP_32_BYTES,
        .ClockPrescaler = 0,
        .SampleShifting = hal.c.HAL_XSPI_SAMPLE_SHIFT_NONE,
        .DelayHoldQuarterCycle = hal.c.HAL_XSPI_DHQC_ENABLE,
        .ChipSelectBoundary = hal.c.HAL_XSPI_BONDARYOF_8KB,
        .MaxTran = 0,
        .Refresh = 0,
        .MemorySelect = hal.c.HAL_XSPI_CSSEL_NCS1,
    } };
    if (hal.c.HAL_XSPI_Init(&hxspi1) != hal.c.HAL_OK) {
        std.debug.panic("HAL_XSPI_Init(1)", .{});
    }

    var sXspiManagerCfg = std.mem.zeroes(hal.c.XSPIM_CfgTypeDef);
    sXspiManagerCfg = .{
        .nCSOverride = hal.c.HAL_XSPI_CSSEL_OVR_DISABLED,
        .IOPort = hal.c.HAL_XSPIM_IOPORT_1,
    };
    if (hal.c.HAL_XSPIM_Config(&hxspi1, &sXspiManagerCfg, hal.c.HAL_XSPI_TIMEOUT_DEFAULT_VALUE) != hal.c.HAL_OK) {
        std.debug.panic("HAL_XSPIM_Config(1)", .{});
    }
}
