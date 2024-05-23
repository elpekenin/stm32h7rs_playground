//! Helper for octo-SPI external flash (XSPI2)
//! 
//! NOT WORKING: Check full procedure on
//! <https://github.com/STMicroelectronics/STM32CubeH7RS/blob/e3ade7eff03aae69c3be76221bef0c3611f60c6e/Projects/STM32H7S78-DK/Examples/XSPI/XSPIM_SwappedMode/Boot/Src/main.c>

const std = @import("std");
const hal = @import("../common/hal.zig");

// Hardware-specific commands (?)
const Specs = struct {
    const Commands = struct {
        const OCTAL_IO_READ = 0xEC13;
        const OCTAL_IO_DTR_READ = 0xEE11;
        const OCTAL_PAGE_PROG = 0x12ED;
        const OCTAL_READ_STATUS_REG = 0x05FA;
        const OCTAL_SECTOR_ERASE = 0x21DE;
        const OCTAL_WRITE_ENABLE = 0x06F9;
        const READ_STATUS_REG = 0x05;
        const WRITE_CFG_REG_2 = 0x72;
        const WRITE_ENABLE = 0x06;
        const RESET = 0xFF;
    };
    const Registers = struct {
        const MR0 = 0x00000000;
        const MR1 = 0x00000001;
        const MR2 = 0x00000002;
        const MR3 = 0x00000003;
        const MR4 = 0x00000004;
        const MR8 = 0x00000008;
    };
    const AutoPolling = struct {
        const WRITE_ENABLE_MATCH_VALUE = 0x02;
        const WRITE_ENABLE_MASK_VALUE = 0x02;
    };
    const DummyClockCycles = struct {
        const WRITE = 0;
        const READ = 6;
    };
};

pub const BASE = 0x70000000;
pub const SIZE = 0x08000000;

var hxspi = std.mem.zeroes(hal.c.XSPI_HandleTypeDef);

/// Print the error code stored in hxspi
pub fn print_error() void {
    std.log.err("Error: 0b{b:0>32}", .{hxspi.ErrorCode});
    std.log.err("State: 0b{b:0>32}", .{hxspi.State});
}

/// Send a command to the chip.
fn send_command(command: *hal.c.XSPI_RegularCmdTypeDef) !void {
    if (hal.c.HAL_XSPI_Command(&hxspi, command, hal.c.HAL_XSPI_TIMEOUT_DEFAULT_VALUE) != hal.c.HAL_OK) {
        std.log.err("HAL_XSPI_Command", .{});
        return error.HalError;
    }
}

/// Set polling. This waits for chip to be available, i think...
fn auto_polling(config: *hal.c.XSPI_AutoPollingTypeDef) !void {
    if (hal.c.HAL_XSPI_AutoPolling(&hxspi, config, hal.c.HAL_XSPI_TIMEOUT_DEFAULT_VALUE) != hal.c.HAL_OK) {
        std.log.err("HAL_XSPI_AutoPolling", .{});
        return error.HalError;
    }
}

fn auto_polling_mem_ready() !void {
    var sCommand = std.mem.zeroes(hal.c.XSPI_RegularCmdTypeDef);
    sCommand = .{
        .OperationType = hal.c.HAL_XSPI_OPTYPE_COMMON_CFG,
        .Instruction = Specs.Commands.OCTAL_READ_STATUS_REG,
        .InstructionMode = hal.c.HAL_XSPI_INSTRUCTION_8_LINES,
        .InstructionWidth = hal.c.HAL_XSPI_INSTRUCTION_16_BITS,
        .InstructionDTRMode = hal.c.HAL_XSPI_INSTRUCTION_DTR_ENABLE,
        .Address = 0x0,
        .AddressMode = hal.c.HAL_XSPI_ADDRESS_8_LINES,
        .AddressWidth = hal.c.HAL_XSPI_ADDRESS_32_BITS,
        .AddressDTRMode = hal.c.HAL_XSPI_ADDRESS_DTR_ENABLE,
        .AlternateBytesMode = hal.c.HAL_XSPI_ALT_BYTES_NONE,
        .DataMode = hal.c.HAL_XSPI_DATA_8_LINES,
        .DataDTRMode = hal.c.HAL_XSPI_DATA_DTR_ENABLE,
        .DataLength = 2,
        .DummyCycles = Specs.DummyClockCycles.READ,
        .DQSMode = hal.c.HAL_XSPI_DQS_ENABLE,
    };

    // there is no do-while, lets duplicate logic
    var reg = [_]u8{ 0, 0 };
    try send_command(&sCommand);
    try receive(&reg);
    while ((reg[0] & Specs.AutoPolling.WRITE_ENABLE_MASK_VALUE) != Specs.AutoPolling.WRITE_ENABLE_MATCH_VALUE) {
        try send_command(&sCommand);
        try receive(&reg);
    }
}

/// Receive data from the chip
fn receive(reg: []u8) !void {
    if (hal.c.HAL_XSPI_Receive(&hxspi, reg.ptr, hal.c.HAL_XSPI_TIMEOUT_DEFAULT_VALUE) != hal.c.HAL_OK) {
        std.log.err("HAL_XSPI_Receive", .{});
        return error.HalError;
    }
}

/// Initialize the XSPI peripheral
fn init_hw() !void {
    hxspi = .{ .Instance = hal.c.XSPI2, .Init = .{
        .FifoThresholdByte = 1,
        .MemoryMode = hal.c.HAL_XSPI_SINGLE_MEM,
        .MemoryType = hal.c.HAL_XSPI_MEMTYPE_MACRONIX,
        .MemorySize = hal.c.HAL_XSPI_SIZE_1GB,
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
    if (hal.c.HAL_XSPI_Init(&hxspi) != hal.c.HAL_OK) {
        std.log.err("HAL_XSPI_Init(2)", .{});
        return error.HalError;
    }

    var sXspiManagerCfg = std.mem.zeroes(hal.c.XSPIM_CfgTypeDef);
    sXspiManagerCfg = .{
        .nCSOverride = hal.c.HAL_XSPI_CSSEL_OVR_NCS1,
        .IOPort = hal.c.HAL_XSPIM_IOPORT_2,
    };
    if (hal.c.HAL_XSPIM_Config(&hxspi, &sXspiManagerCfg, hal.c.HAL_XSPI_TIMEOUT_DEFAULT_VALUE) != hal.c.HAL_OK) {
        std.log.err("HAL_XSPIM_Config(2)", .{});
        return error.HalError;
    }
}

/// Set the chip on octal DTR mode
fn octal_dtr() !void {
    var sCommand = std.mem.zeroes(hal.c.XSPI_RegularCmdTypeDef);

    // enable write operations
    sCommand = .{
        .OperationType = hal.c.HAL_XSPI_OPTYPE_COMMON_CFG,
        .InstructionMode = hal.c.HAL_XSPI_INSTRUCTION_1_LINE,
        .InstructionWidth = hal.c.HAL_XSPI_INSTRUCTION_8_BITS,
        .InstructionDTRMode = hal.c.HAL_XSPI_INSTRUCTION_DTR_DISABLE,
        .AddressDTRMode = hal.c.HAL_XSPI_ADDRESS_DTR_DISABLE,
        .AlternateBytesMode = hal.c.HAL_XSPI_ALT_BYTES_NONE,
        .DataDTRMode = hal.c.HAL_XSPI_DATA_DTR_DISABLE,
        .DummyCycles = 0,
        .DQSMode = hal.c.HAL_XSPI_DQS_DISABLE,
        .Instruction = Specs.Commands.WRITE_ENABLE,
        .DataMode = hal.c.HAL_XSPI_DATA_NONE,
        .AddressMode = hal.c.HAL_XSPI_ADDRESS_NONE,
    };
    try send_command(&sCommand);

    // reconfigure to automatic-polling mode
    sCommand.Instruction = Specs.Commands.READ_STATUS_REG;
    sCommand.DataMode = hal.c.HAL_XSPI_DATA_1_LINE;
    sCommand.DataLength = 1;
    try send_command(&sCommand);

    var sConfig = std.mem.zeroes(hal.c.XSPI_AutoPollingTypeDef);
    sConfig = .{
        .MatchMode = hal.c.HAL_XSPI_MATCH_MODE_AND,
        .AutomaticStop = hal.c.HAL_XSPI_AUTOMATIC_STOP_ENABLE,
        .IntervalTime = 0x10,
        .MatchMask = 0x02,
        .MatchValue = 0x02,
    };
    try auto_polling(&sConfig);

    // write configuration register 2
    sCommand.Instruction = Specs.Commands.WRITE_CFG_REG_2;
    sCommand.AddressMode = hal.c.HAL_XSPI_ADDRESS_1_LINE;
    sCommand.AddressWidth = hal.c.HAL_XSPI_ADDRESS_32_BITS;
    sCommand.Address = 0;
    try send_command(&sCommand);

    var reg: u8 = 0x2;
    if (hal.c.HAL_XSPI_Transmit(&hxspi, &reg, hal.c.HAL_XSPI_TIMEOUT_DEFAULT_VALUE) != hal.c.HAL_OK) {
        std.log.err("HAL_XSPI_Transmit", .{});
        return error.HalError;
    }

    sCommand.Instruction = Specs.Commands.READ_STATUS_REG;
    sCommand.DataMode = hal.c.HAL_XSPI_DATA_1_LINE;
    sCommand.DataLength = 1;
    try send_command(&sCommand);
    try auto_polling(&sConfig);
}

/// Enable writing (does this mean data? commands? both?)
fn write_enable() !void {
    var sCommand = std.mem.zeroes(hal.c.XSPI_RegularCmdTypeDef);

    sCommand = .{
        .OperationType = hal.c.HAL_XSPI_OPTYPE_COMMON_CFG,
        .Instruction = Specs.Commands.OCTAL_WRITE_ENABLE,
        .InstructionMode = hal.c.HAL_XSPI_INSTRUCTION_8_LINES,
        .InstructionWidth = hal.c.HAL_XSPI_INSTRUCTION_16_BITS,
        .InstructionDTRMode = hal.c.HAL_XSPI_INSTRUCTION_DTR_ENABLE,
        .AddressMode = hal.c.HAL_XSPI_ADDRESS_NONE,
        .AlternateBytesMode = hal.c.HAL_XSPI_ALT_BYTES_NONE,
        .DataMode = hal.c.HAL_XSPI_DATA_NONE,
        .DummyCycles = 0,
        .DQSMode = hal.c.HAL_XSPI_DQS_DISABLE,
    };
    try send_command(&sCommand);

    sCommand.Instruction = Specs.Commands.OCTAL_READ_STATUS_REG;
    sCommand.Address = 0;
    sCommand.AddressMode = hal.c.HAL_XSPI_ADDRESS_8_LINES;
    sCommand.AddressWidth = hal.c.HAL_XSPI_ADDRESS_32_BITS;
    sCommand.AddressDTRMode = hal.c.HAL_XSPI_ADDRESS_DTR_ENABLE;
    sCommand.DataMode = hal.c.HAL_XSPI_DATA_8_LINES;
    sCommand.DataDTRMode = hal.c.HAL_XSPI_DATA_DTR_ENABLE;
    sCommand.DataLength = 2;
    sCommand.DummyCycles = Specs.DummyClockCycles.READ;
    sCommand.DQSMode = hal.c.HAL_XSPI_DQS_ENABLE;

    // there is no do-while, lets duplicate logic
    var reg = [_]u8{ 0, 0 };
    try send_command(&sCommand);
    try receive(&reg);
    while ((reg[0] & Specs.AutoPolling.WRITE_ENABLE_MASK_VALUE) != Specs.AutoPolling.WRITE_ENABLE_MATCH_VALUE) {
        try send_command(&sCommand);
        try receive(&reg);
    }
}

// Public API

pub fn init() !void {
    try init_hw();
    try octal_dtr();

    std.log.debug("external flash ready", .{});
}

pub fn write(pos: usize, data: []const u8) !void {
    try auto_polling_mem_ready();

    try write_enable();

    var sCommand = std.mem.zeroes(hal.c.XSPI_RegularCmdTypeDef);
    sCommand = .{
        .Instruction = Specs.Commands.OCTAL_PAGE_PROG,
        .DataMode = hal.c.HAL_XSPI_DATA_8_LINES,
        .DataLength = data.len,
        .Address = pos,
    };
    try send_command(&sCommand);

    if (hal.c.HAL_XSPI_Transmit(&hxspi, data.ptr, hal.c.HAL_XSPI_TIMEOUT_DEFAULT_VALUE) != hal.c.HAL_OK) {
        std.log.err("HAL_XSPI_Transmit", .{});
        return error.HalError;
    }

    try auto_polling_mem_ready();
}

pub fn read(pos: usize, data: []u8) !void {
    var sCommand = std.mem.zeroes(hal.c.XSPI_RegularCmdTypeDef);
    sCommand = .{
        .Instruction = Specs.Commands.OCTAL_IO_DTR_READ,
        .DummyCycles = Specs.DummyClockCycles.READ,
        .Address = pos,
        .DataLength = data.len,
    };
    try send_command(&sCommand);

    try receive(data);
}
