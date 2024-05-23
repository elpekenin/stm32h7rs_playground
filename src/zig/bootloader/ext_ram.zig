//! Helper for hexadeca-SPI external PSRAM (XSPI1)

const std = @import("std");
const hal = @import("../common/hal.zig");

const BASE = 0x90000000;
const SIZE = 0x02000000;

fn init_hw(hsxpi: *hal.c.XSPI_HandleTypeDef) void {
    hsxpi.* = .{ .Instance = hal.c.XSPI1, .Init = .{
        .FifoThresholdByte = 4,
        .MemoryMode = hal.c.HAL_XSPI_SINGLE_MEM,
        .MemoryType = hal.c.HAL_XSPI_MEMTYPE_APMEM_16BITS,
        .MemorySize = hal.c.HAL_XSPI_SIZE_256MB,
        .ChipSelectHighTimeCycle = 1,
        .FreeRunningClock = hal.c.HAL_XSPI_FREERUNCLK_DISABLE,
        .ClockMode = hal.c.HAL_XSPI_CLOCK_MODE_0,
        .WrapSize = hal.c.HAL_XSPI_WRAP_NOT_SUPPORTED,
        .ClockPrescaler = 1,
        .SampleShifting = hal.c.HAL_XSPI_SAMPLE_SHIFT_NONE,
        .DelayHoldQuarterCycle = hal.c.HAL_XSPI_DHQC_DISABLE,
        .ChipSelectBoundary = hal.c.HAL_XSPI_BONDARYOF_NONE,
        .MaxTran = 0,
        .Refresh = 0,
        .MemorySelect = hal.c.HAL_XSPI_CSSEL_NCS1,
    } };
    if (hal.c.HAL_XSPI_Init(hsxpi) != hal.c.HAL_OK) {
        std.debug.panic("HAL_XSPI_Init(1)", .{});
    }

    var sXspiManagerCfg = std.mem.zeroes(hal.c.XSPIM_CfgTypeDef);
    sXspiManagerCfg = .{
        .nCSOverride = hal.c.HAL_XSPI_CSSEL_OVR_NCS1,
        .IOPort = hal.c.HAL_XSPIM_IOPORT_1,
    };
    if (hal.c.HAL_XSPIM_Config(hsxpi, &sXspiManagerCfg, hal.c.HAL_XSPI_TIMEOUT_DEFAULT_VALUE) != hal.c.HAL_OK) {
        std.debug.panic("HAL_XSPIM_Config(1)", .{});
    }
}

pub fn init() void {
    var hxspi = std.mem.zeroes(hal.c.XSPI_HandleTypeDef);

    init_hw(&hxspi);
}
