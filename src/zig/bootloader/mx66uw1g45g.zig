//! Details about the Macronix MX66UW1G45G OctoSPI chip
//!
//! See: https://github.com/STMicroelectronics/stm32-mx66uw1g45g/blob/main/mx66uw1g45g.c

const std = @import("std");
const hal = @import("../common/hal.zig");

pub const BASE = 0x70000000;
pub const SIZE = 0x08000000;

var hxspi = std.mem.zeroes(hal.c.XSPI_HandleTypeDef);

/// 1024 blocks of 64KBytes
const BLOCK_64K = 64 * 1024;
/// 16384 sectors of 4KBytes
const BLOCK_4K = 4 * 1024;
/// 1 Gbits => 128MBytes
const FLASH_SIZE = 1024 * 1024 * 1024 / 8;
/// 262144 pages of 256 Bytes
const PAGE_SIZE = 256;

const BULK_ERASE_MAX_TIME = 460000;
const BLOCK_ERASE_MAX_TIME = 1000;
const BLOCK_4K_ERASE_MAX_TIME = 400;
const WRITE_REG_MAX_TIME = 40;

/// when SWreset during erase operation
const RESET_MAX_TIME = 100;

const AUTOPOLLING_INTERVAL_TIME = 0x10;

const XSPI_ALTERNATE_BYTE_PATTERN = 0x00;

const DummyCyclesConfig = struct {
    const READ = 8;
    const READ_OCTAL = 6;
    const READ_OCTAL_DTR = 6;
    const REG_OCTAL = 4;
    const REG_OCTAL_DTR = 5;
};

const dummy_cycles_array = [_]u8{ Registers.CR2.REG3.DC_6_CYCLES, Registers.CR2.REG3.DC_8_CYCLES, Registers.CR2.REG3.DC_10_CYCLES, Registers.CR2.REG3.DC_12_CYCLES, Registers.CR2.REG3.DC_14_CYCLES, Registers.CR2.REG3.DC_16_CYCLES, Registers.CR2.REG3.DC_18_CYCLES, Registers.CR2.REG3.DC_20_CYCLES };

/// MX66UW1G45G Commands
const Commands = struct {
    const SPI = struct {
        /// READ/WRITE MEMORY Operations with 3-Byte Address
        const _3Bytes = struct {
            /// Normal Read 3 Byte Address
            const READ = 0x03;
            /// Fast Read 3 Byte Address
            const FAST_READ = 0x0B;
            /// Page Program 3 Byte Address
            const PAGE_PROG = 0x02;
            /// SubSector Erase 4KB 3 Byte Address
            const SECTOR_ERASE_4K = 0x20;
            /// Sector Erase 64KB 3 Byte Address
            const BLOCK_ERASE_64K = 0xD8;
            /// Bulk Erase
            const BULK_ERASE = 0x60;
        };

        /// READ/WRITE MEMORY Operations with 4-Byte Address
        const _4Bytes = struct {
            /// Normal Read 4 Byte address
            const READ = 0x13;
            /// Fast Read 4 Byte address
            const FAST_READ = 0x0C;
            /// Page Program 4 Byte Address
            const PAGE_PROG = 0x12;
            /// SubSector Erase 4KB 4 Byte Address
            const SECTOR_ERASE_4K = 0x21;
            /// Sector Erase 64KB 4 Byte Address
            const BLOCK_ERASE_64K = 0xDC;
        };

        // Setting commands
        const Settings = struct {
            /// Write Enable
            const WRITE_ENABLE = 0x06;
            /// Write Disable
            const WRITE_DISABLE = 0x04;
            /// Program/Erase suspend
            const PROG_ERASE_SUSPEND = 0xB0;
            /// Program/Erase resume
            const PROG_ERASE_RESUME = 0x30;
            /// Enter deep power down
            const ENTER_DEEP_POWER_DOWN = 0xB9;
            /// Release from deep power down
            const RELEASE_DEEP_POWER_DOWN = 0xAB;
            /// Set burst length
            const SET_BURST_LENGTH = 0xC0;
            /// Enter secured OTP)
            const ENTER_SECURED_OTP = 0xB1;
            /// Exit secured OTP)
            const EXIT_SECURED_OTP = 0xC1;
        };

        /// RESET commands
        const Reset = struct {
            /// No operation
            const NOP = 0x00;
            /// Reset Enable
            const RESET_ENABLE = 0x66;
            /// Reset Memory
            const RESET_MEMORY = 0x99;
        };

        /// Register Commands (SPI)
        const Register = struct {
            /// Read IDentification
            const READ_ID = 0x9F;
            /// Read Serial Flash Discoverable Parameter
            const READ_SERIAL_FLASH_DISCO_PARAM = 0x5A;
            /// Read Status Register
            const READ_STATUS_REG = 0x05;
            /// Read configuration Register
            const READ_CFG_REG = 0x15;
            /// Write Status Register
            const WRITE_STATUS_REG = 0x01;
            /// Read configuration Register2
            const READ_CFG_REG2 = 0x71;
            /// Write configuration Register2
            const WRITE_CFG_REG2 = 0x72;
            /// Read fast boot Register
            const READ_FAST_BOOT_REG = 0x16;
            /// Write fast boot Register
            const WRITE_FAST_BOOT_REG = 0x17;
            /// Erase fast boot Register
            const ERASE_FAST_BOOT_REG = 0x18;
            /// Read security Register
            const READ_SECURITY_REG = 0x2B;
            /// Write security Register
            const WRITE_SECURITY_REG = 0x2F;
            /// Read lock Register
            const READ_LOCK_REG = 0x2D;
            /// Write lock Register
            const WRITE_LOCK_REG = 0x2C;
            /// Read DPB register
            const READ_DPB_REG = 0xE0;
            /// Write DPB register
            const WRITE_DPB_REG = 0xE1;
            /// Read SPB status
            const READ_SPB_STATUS = 0xE2;
            /// SPB bit program
            const WRITE_SPB_BIT = 0xE3;
            /// Erase all SPB bit
            const ERASE_ALL_SPB = 0xE4;
            /// Write Protect selection
            const WRITE_PROTECT_SEL = 0x68;
            /// Gang block lock: whole chip write protect
            const GANG_BLOCK_LOCK = 0x7E;
            /// Gang block unlock: whole chip write unprotect
            const GANG_BLOCK_UNLOCK = 0x98;
            /// Read Password
            const READ_PASSWORD_REGISTER = 0x27;
            /// Write Password
            const WRITE_PASSWORD_REGISTER = 0x28;
            /// Unlock Password
            const PASSWORD_UNLOCK = 0x29;
        };
    };

    const OPI = struct {
        /// READ/WRITE MEMORY Operations
        const Memory = struct {
            /// Octa IO Read
            const READ = 0xEC13;
            /// Octa IO Read DTR
            const READ_DTR = 0xEE11;
            /// Octa Page Program
            const PAGE_PROG = 0x12ED;
            /// Octa SubSector Erase 4KB
            const SECTOR_ERASE_4K = 0x21DE;
            /// Octa Sector Erase 64KB 3
            const BLOCK_ERASE_64K = 0xDC23;
            /// Octa Bulk Erase
            const BULK_ERASE = 0x609F;
        };

        /// Setting commands
        const Settings = struct {
            /// Octa Write Enable
            const WRITE_ENABLE = 0x06F9;
            /// Octa Write Disable
            const WRITE_DISABLE = 0x04FB;
            /// Octa Program/Erase suspend
            const PROG_ERASE_SUSPEND = 0xB04F;
            /// Octa Program/Erase resume
            const PROG_ERASE_RESUME = 0x30CF;
            /// Octa Enter deep power down
            const ENTER_DEEP_POWER_DOWN = 0xB946;
            /// Octa Release from deep power down
            const RELEASE_DEEP_POWER_DOWN = 0xAB54;
            /// Octa Set burst length
            const SET_BURST_LENGTH = 0xC03F;
            /// Octa Enter secured OTP)
            const ENTER_SECURED_OTP = 0xB14E;
            /// Octa Exit secured OTP)
            const EXIT_SECURED_OTP = 0xC13E;
        };

        /// RESET commands
        const Reset = struct {
            /// Octa No operation
            const NOP = 0x00FF;
            /// Octa Reset Enable
            const RESET_ENABLE = 0x6699;
            /// Octa Reset Memory
            const RESET_MEMORY = 0x9966;
        };

        /// Register Commands (OPI)
        const Register = struct {
            /// Octa Read IDentification
            const READ_ID = 0x9F60;
            /// Octa Read Serial Flash Discoverable Parameter
            const READ_SERIAL_FLASH_DISCO_PARAM = 0x5AA5;
            /// Octa Read Status Register
            const READ_STATUS_REG = 0x05FA;
            /// Octa Read configuration Register
            const READ_CFG_REG = 0x15EA;
            /// Octa Write Status Register
            const WRITE_STATUS_REG = 0x01FE;
            /// Octa Read configuration Register2
            const READ_CFG_REG2 = 0x718E;
            /// Octa Write configuration Register2
            const WRITE_CFG_REG2 = 0x728D;
            /// Octa Read fast boot Register
            const READ_FAST_BOOT_REG = 0x16E9;
            /// Octa Write fast boot Register
            const WRITE_FAST_BOOT_REG = 0x17E8;
            /// Octa Erase fast boot Register
            const ERASE_FAST_BOOT_REG = 0x18E7;
            /// Octa Read security Register
            const READ_SECURITY_REG = 0x2BD4;
            /// Octa Write security Register
            const WRITE_SECURITY_REG = 0x2FD0;
            /// Octa Read lock Register
            const READ_LOCK_REG = 0x2DD2;
            /// Octa Write lock Register
            const WRITE_LOCK_REG = 0x2CD3;
            /// Octa Read DPB register
            const READ_DPB_REG = 0xE01F;
            /// Octa Write DPB register
            const WRITE_DPB_REG = 0xE11E;
            /// Octa Read SPB status
            const READ_SPB_STATUS = 0xE21D;
            /// Octa SPB bit program
            const WRITE_SPB_BIT = 0xE31C;
            /// Octa Erase all SPB bit
            const ERASE_ALL_SPB = 0xE41B;
            /// Octa Write Protect selection
            const WRITE_PROTECT_SEL = 0x6897;
            /// Octa Gang block lock: whole chip write protect
            const GANG_BLOCK_LOCK = 0x7E81;
            /// Octa Gang block unlock: whole chip write unprote
            const GANG_BLOCK_UNLOCK = 0x9867;
            /// Octa Read Password
            const READ_PASSWORD_REGISTER = 0x27D8;
            /// Octa Write Password
            const WRITE_PASSWORD_REGISTER = 0x28D7;
            /// Octa Unlock Password
            const PASSWORD_UNLOCK = 0x29D6;
        };
    };
};

const Registers = struct {
    /// Status Register
    const Status = struct {
        /// Write in progress
        const SR_WIP = 0x01;
        /// Write enable latch
        const SR_WEL = 0x02;
        /// Block protected against program and erase operations
        const SR_PB = 0x3C;
    };

    // Configuration Register 1
    const CR1 = struct {
        /// Output driver strength
        const ODS = 0x07;
        /// Top / bottom  selected
        const TB = 0x08;
        /// Preamble bit enable
        const PBE = 0x10;
    };

    // Configuration Register 2
    const CR2 = struct {
        /// CR2 register address 0x00000000
        const REG1 = struct {
            const ADDR = 0x00000000;
            /// STR OPI Enable
            const SOPI = 0x01;
            /// DTR OPI Enable
            const DOPI = 0x02;
        };

        /// CR2 register address 0x00000200
        const REG2 = struct {
            const ADDR = 0x00000200;
            /// DTR DQS pre-cycle
            const DQSPRC = 0x01;
            /// DQS on STR mode
            const DOS = 0x02;
        };

        /// CR2 register address 0x00000300
        const REG3 = struct {
            const ADDR = 0x00000300;
            /// Dummy cycle
            const DC = 0x07;
            /// 20 Dummy cycles
            const DC_20_CYCLES = 0x00;
            /// 18 Dummy cycles
            const DC_18_CYCLES = 0x01;
            /// 16 Dummy cycles
            const DC_16_CYCLES = 0x02;
            /// 14 Dummy cycles
            const DC_14_CYCLES = 0x03;
            /// 12 Dummy cycles
            const DC_12_CYCLES = 0x04;
            /// 10 Dummy cycles
            const DC_10_CYCLES = 0x05;
            /// 8 Dummy cycles
            const DC_8_CYCLES = 0x06;
            /// 6 Dummy cycles
            const DC_6_CYCLES = 0x07;
        };

        /// CR2 register address 0x00000500
        const REG4 = struct {
            const ADDR = 0x00000500;
            /// Preamble pattern selection
            const PPTSEL = 0x01;
        };

        /// CR2 register address 0x40000000
        const REG5 = struct {
            const ADDR = 0x40000000;
            /// Enable SOPI after power on reset
            const DEFSOPI = 0x01;
            /// Enable DOPI after power on reset
            const DEFDOPI = 0x02;
        };
    };

    // Security Register
    const Security = struct {
        /// Secured OTP indicator
        const SECR_SOI = 0x01;
        /// Lock-down secured OTP
        const SECR_LDSO = 0x02;
        /// Program suspend bit
        const SECR_PSB = 0x04;
        /// Erase suspend bit
        const SECR_ESB = 0x08;
        /// Program fail flag
        const SECR_P_FAIL = 0x20;
        /// Erase fail flag
        const SECR_E_FAIL = 0x40;
        /// Write protection selection
        const SECR_WPSEL = 0x80;
    };
};

const Info = struct {
    /// Size of the flash
    FlashSize: u32,
    /// Size of sectors for the erase operation
    EraseSectorSize: u32,
    /// Number of sectors for the erase operation
    EraseSectorsNumber: u32,
    /// Size of subsector for the erase operation
    EraseSubSectorSize: u32,
    /// Number of subsector for the erase operation
    EraseSubSectorNumber: u32,
    /// Size of subsector 1 for the erase operation
    EraseSubSector1Size: u32,
    /// Number of subsector 1 for the erase operation
    EraseSubSector1Number: u32,
    /// Size of pages for the program operation
    ProgPageSize: u32,
    /// Number of pages for the program operation
    ProgPagesNumber: u32,
};

const Protocol = enum {
    // 1-1-1 commands, Power on H/W default setting
    SPI,
    // 8-8-8 commands
    OPI,
};

const Rate = enum {
    /// Single Transfer Rate
    STR,
    /// Double Transfer Rate
    DTR,
};

/// How big of a delete
const Erase = enum {
    /// 4K size Sector erase
    _4K,
    /// 64K size Block erase
    _64K,
    /// Whole bulk erase
    BULK,
};

/// Size of the address
const AddressWidth = enum {
    /// 3 Bytes address mode
    _3B,
    /// 4 Bytes address mode
    _4B,
};

// *** End of STM adapted header ***
// *********************************

// Some helpers, for configuration depending on protocol and transfer rate

inline fn instruction_mode(protocol: Protocol) u32 {
    return switch (protocol) {
        .SPI => hal.c.HAL_XSPI_INSTRUCTION_1_LINE,
        .OPI => hal.c.HAL_XSPI_INSTRUCTION_8_LINES,
    };
}

inline fn instruction_dtr_mode(rate: Rate) u32 {
    return switch (rate) {
        .STR => hal.c.HAL_XSPI_INSTRUCTION_DTR_DISABLE,
        .DTR => hal.c.HAL_XSPI_INSTRUCTION_DTR_ENABLE,
    };
}

inline fn instruction_width(protocol: Protocol) u32 {
    return switch (protocol) {
        .SPI => hal.c.HAL_XSPI_INSTRUCTION_8_BITS,
        .OPI => hal.c.HAL_XSPI_INSTRUCTION_16_BITS,
    };
}

inline fn address_mode(protocol: Protocol) u32 {
    return switch (protocol) {
        .SPI => hal.c.HAL_XSPI_ADDRESS_NONE,
        .OPI => hal.c.HAL_XSPI_ADDRESS_8_LINES,
    };
}

inline fn address_dtr_mode(rate: Rate) u32 {
    return switch (rate) {
        .STR => hal.c.HAL_XSPI_ADDRESS_DTR_DISABLE,
        .DTR => hal.c.HAL_XSPI_ADDRESS_DTR_ENABLE,
    };
}

inline fn data_mode(protocol: Protocol) u32 {
    return switch (protocol) {
        .SPI => hal.c.HAL_XSPI_DATA_1_LINE,
        .OPI => hal.c.HAL_XSPI_DATA_8_LINES,
    };
}

inline fn data_dtr_mode(rate: Rate) u32 {
    return switch (rate) {
        .STR => hal.c.HAL_XSPI_DATA_DTR_DISABLE,
        .DTR => hal.c.HAL_XSPI_DATA_DTR_ENABLE,
    };
}

inline fn dummy_cycles(protocol: Protocol, rate: Rate) u32 {
    return switch (protocol) {
        .SPI => 0,
        .OPI => switch (rate) {
            .STR => DummyCyclesConfig.REG_OCTAL,
            .DTR => DummyCyclesConfig.REG_OCTAL_DTR,
        },
    };
}

inline fn data_length(rate: Rate) u32 {
    return switch (rate) {
        .STR => 1,
        .DTR => 2,
    };
}

inline fn dqs_mode(rate: Rate) u32 {
    return switch (rate) {
        .STR => hal.c.HAL_XSPI_DQS_DISABLE,
        .DTR => hal.c.HAL_XSPI_DQS_ENABLE,
    };
}

inline fn address_width(addr_width: AddressWidth) u32 {
    return switch (addr_width) {
        ._3B => hal.c.HAL_XSPI_ADDRESS_24_BITS,
        ._4B => hal.c.HAL_XSPI_ADDRESS_32_BITS,
    };
}

// Helpers to validate wrong input
fn assert_init() !void {
    if (!state.init) {
        std.log.err("external flash not ready", .{});
        return error.NotReady;
    }
}

inline fn assert_spi_dtr(protocol: Protocol, rate: Rate) !void {
    if (protocol == .SPI and rate == .DTR) {
        std.log.err("Cant use SPI & DTR", .{});
        return error.InvalidParams;
    }
}

inline fn assert_opi_3bytes(protocol: Protocol, addr_width: AddressWidth) !void {
    if (protocol == .OPI and addr_width == ._3B) {
        std.log.err("Cant use OPI & 3byte address", .{});
        return error.InvalidParams;
    }
}

fn hxspi_init() !void {
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
    try hal.zig.xspi.init(&hxspi);

    var xspi_cfg = std.mem.zeroes(hal.c.XSPIM_CfgTypeDef);
    xspi_cfg = .{
        .nCSOverride = hal.c.HAL_XSPI_CSSEL_OVR_NCS1,
        .IOPort = hal.c.HAL_XSPIM_IOPORT_2,
        // STM code did not set this (ie: initialized to 0), but that
        // causes an assert error because it is supposed to be 1-256
        .Req2AckTime = 1,
    };
    try hal.zig.xspi.configure(&hxspi, &xspi_cfg);
}

fn reset_enable(protocol: Protocol, rate: Rate) !void {
    try assert_spi_dtr(protocol, rate);

    const instruction: u32 = switch (protocol) {
        .SPI => Commands.SPI.Reset.RESET_ENABLE,
        .OPI => Commands.OPI.Reset.RESET_ENABLE,
    };

    var command = std.mem.zeroes(hal.c.XSPI_RegularCmdTypeDef);
    command = .{
        .OperationType = hal.c.HAL_XSPI_OPTYPE_COMMON_CFG,
        .IOSelect = hal.c.HAL_XSPI_SELECT_IO_3_0,
        .InstructionMode = instruction_mode(protocol),
        .InstructionDTRMode = instruction_dtr_mode(rate),
        .InstructionWidth = instruction_width(protocol),
        .Instruction = instruction,
        .AddressMode = hal.c.HAL_XSPI_ADDRESS_NONE,
        .AlternateBytesMode = hal.c.HAL_XSPI_ALT_BYTES_NONE,
        .DataMode = hal.c.HAL_XSPI_DATA_NONE,
        .DummyCycles = 0,
        .DQSMode = hal.c.HAL_XSPI_DQS_DISABLE,
    };
    try hal.zig.xspi.send_command(&hxspi, &command);
}

fn reset_memory(protocol: Protocol, rate: Rate) !void {
    try assert_spi_dtr(protocol, rate);

    const instruction: u32 = switch (protocol) {
        .SPI => Commands.SPI.Reset.RESET_MEMORY,
        .OPI => Commands.OPI.Reset.RESET_MEMORY,
    };

    var command = std.mem.zeroes(hal.c.XSPI_RegularCmdTypeDef);
    command = .{
        .OperationType = hal.c.HAL_XSPI_OPTYPE_COMMON_CFG,
        .InstructionMode = instruction_mode(protocol),
        .InstructionDTRMode = instruction_dtr_mode(rate),
        .InstructionWidth = instruction_width(protocol),
        .Instruction = instruction,
        .AddressMode = hal.c.HAL_XSPI_ADDRESS_NONE,
        .AlternateBytesMode = hal.c.HAL_XSPI_ALT_BYTES_NONE,
        .DataMode = hal.c.HAL_XSPI_DATA_NONE,
        .DummyCycles = 0,
        .DQSMode = hal.c.HAL_XSPI_DQS_DISABLE,
    };
    try hal.zig.xspi.send_command(&hxspi, &command);
}

fn auto_polling_ready_impl(protocol: Protocol, rate: Rate, match_value: u32, match_mask: u32) !void {
    try assert_spi_dtr(protocol, rate);

    const instruction: u32 = switch (protocol) {
        .SPI => Commands.SPI.Register.READ_STATUS_REG,
        .OPI => Commands.OPI.Register.READ_STATUS_REG,
    };

    var command = std.mem.zeroes(hal.c.XSPI_RegularCmdTypeDef);
    command = .{
        .OperationType = hal.c.HAL_XSPI_OPTYPE_COMMON_CFG,
        .InstructionMode = instruction_mode(protocol),
        .InstructionDTRMode = instruction_dtr_mode(rate),
        .InstructionWidth = instruction_width(protocol),
        .Instruction = instruction,
        .AddressMode = address_mode(protocol),
        .AddressDTRMode = address_dtr_mode(rate),
        .AddressWidth = hal.c.HAL_XSPI_ADDRESS_32_BITS,
        .Address = 0,
        .AlternateBytesMode = hal.c.HAL_XSPI_ALT_BYTES_NONE,
        .DataMode = data_mode(protocol),
        .DataDTRMode = data_dtr_mode(rate),
        .DummyCycles = dummy_cycles(protocol, rate),
        .DataLength = data_length(rate),
        .DQSMode = dqs_mode(rate),
    };
    try hal.zig.xspi.send_command(&hxspi, &command);

    var config = std.mem.zeroes(hal.c.XSPI_AutoPollingTypeDef);
    config = .{
        .MatchValue = match_value,
        .MatchMask = match_mask,
        .MatchMode = hal.c.HAL_XSPI_MATCH_MODE_AND,
        .IntervalTime = AUTOPOLLING_INTERVAL_TIME,
        .AutomaticStop = hal.c.HAL_XSPI_AUTOMATIC_STOP_ENABLE,
    };
    try hal.zig.xspi.auto_polling(&hxspi, &config);
}

inline fn auto_polling_ready(protocol: Protocol, rate: Rate) !void {
    return auto_polling_ready_impl(protocol, rate, 0, Registers.Status.SR_WIP);
}

fn write_enable(protocol: Protocol, rate: Rate) !void {
    try assert_spi_dtr(protocol, rate);

    const instruction: u32 = switch (protocol) {
        .SPI => Commands.SPI.Settings.WRITE_ENABLE,
        .OPI => Commands.OPI.Settings.WRITE_ENABLE,
    };

    var command = std.mem.zeroes(hal.c.XSPI_RegularCmdTypeDef);
    command = .{
        .OperationType = hal.c.HAL_XSPI_OPTYPE_COMMON_CFG,
        .InstructionMode = instruction_mode(protocol),
        .InstructionDTRMode = instruction_dtr_mode(rate),
        .InstructionWidth = instruction_width(protocol),
        .Instruction = instruction,
        .AddressMode = hal.c.HAL_XSPI_ADDRESS_NONE,
        .AlternateBytesMode = hal.c.HAL_XSPI_ALT_BYTES_NONE,
        .DataMode = hal.c.HAL_XSPI_DATA_NONE,
        .DummyCycles = 0,
        .DQSMode = hal.c.HAL_XSPI_DQS_DISABLE,
    };
    try hal.zig.xspi.send_command(&hxspi, &command);

    return auto_polling_ready_impl(protocol, rate, 2, 2);
}

fn write_cfg2(protocol: Protocol, rate: Rate, address: u32, value: u8) !void {
    try assert_spi_dtr(protocol, rate);

    const instruction: u32 = switch (protocol) {
        .SPI => Commands.SPI.Register.WRITE_CFG_REG2,
        .OPI => Commands.OPI.Register.WRITE_CFG_REG2,
    };

    var command = std.mem.zeroes(hal.c.XSPI_RegularCmdTypeDef);
    command = .{
        .OperationType = hal.c.HAL_XSPI_OPTYPE_COMMON_CFG,
        .InstructionMode = instruction_mode(protocol),
        .InstructionDTRMode = instruction_dtr_mode(rate),
        .InstructionWidth = instruction_width(protocol),
        .Instruction = instruction,
        .AddressMode = address_mode(protocol),
        .AddressDTRMode = address_dtr_mode(rate),
        .AddressWidth = hal.c.HAL_XSPI_ADDRESS_32_BITS,
        .Address = address,
        .AlternateBytesMode = hal.c.HAL_XSPI_ALT_BYTES_NONE,
        .DataMode = data_mode(protocol),
        .DataDTRMode = data_dtr_mode(rate),
        .DummyCycles = 0,
        .DataLength = data_length(rate),
        .DQSMode = hal.c.HAL_XSPI_DQS_DISABLE,
    };
    try hal.zig.xspi.send_command(&hxspi, &command);

    // zig does not like &value (it is `*const u8` instead of `[]const u8`)
    const temp = [_]u8{value};
    try hal.zig.xspi.transmit(&hxspi, &temp);
}

fn read_cfg2(protocol: Protocol, rate: Rate, address: u32) !u8 {
    try assert_spi_dtr(protocol, rate);

    const instruction: u32 = switch (protocol) {
        .SPI => Commands.SPI.Register.READ_CFG_REG2,
        .OPI => Commands.OPI.Register.READ_CFG_REG2,
    };

    var command = std.mem.zeroes(hal.c.XSPI_RegularCmdTypeDef);
    command = .{
        .OperationType = hal.c.HAL_XSPI_OPTYPE_COMMON_CFG,
        .InstructionMode = instruction_mode(protocol),
        .InstructionDTRMode = instruction_dtr_mode(rate),
        .InstructionWidth = instruction_width(protocol),
        .Instruction = instruction,
        .AddressMode = address_mode(protocol),
        .AddressDTRMode = address_dtr_mode(rate),
        .AddressWidth = hal.c.HAL_XSPI_ADDRESS_32_BITS,
        .Address = address,
        .AlternateBytesMode = hal.c.HAL_XSPI_ALT_BYTES_NONE,
        .DataMode = data_mode(protocol),
        .DataDTRMode = data_dtr_mode(rate),
        .DummyCycles = dummy_cycles(protocol, rate),
        .DataLength = data_length(rate),
        .DQSMode = dqs_mode(rate),
    };
    try hal.zig.xspi.send_command(&hxspi, &command);

    var value: [2]u8 = undefined;
    try hal.zig.xspi.receive(&hxspi, &value);

    return value[0];
}

fn exit_opi_mode() !void {
    try write_enable(state.protocol, state.rate);

    try write_cfg2(state.protocol, state.rate, Registers.CR2.REG1.ADDR, 0);

    hal.c.HAL_Delay(WRITE_REG_MAX_TIME);

    if (state.rate == .DTR) {
        std.debug.panic("Unimplemented OPI", .{});
    }

    try auto_polling_ready(state.protocol, state.rate);

    const value = try read_cfg2(state.protocol, state.rate, Registers.CR2.REG1.ADDR);

    if (value != 0) {
        std.debug.panic("Failed to exit OPI", .{});
    }
}

fn enter_opi_impl(rate: Rate) !void {
    const index = (DummyCyclesConfig.READ_OCTAL / 2) - 3;
    const reg3_value = dummy_cycles_array[index];
    try write_enable(state.protocol, state.rate);
    try write_cfg2(state.protocol, state.rate, Registers.CR2.REG3.ADDR, reg3_value);

    const reg1_value: u8 = switch (rate) {
        .STR => Registers.CR2.REG1.SOPI,
        .DTR => Registers.CR2.REG1.DOPI,
    };
    try write_enable(state.protocol, state.rate);
    try write_cfg2(state.protocol, state.rate, Registers.CR2.REG1.ADDR, reg1_value);

    hal.c.HAL_Delay(WRITE_REG_MAX_TIME);

    // TODO: some re- init/config for DOPI

    try auto_polling_ready(.OPI, rate);
    const val = try read_cfg2(.OPI, rate, Registers.CR2.REG1.ADDR);

    switch (rate) {
        .STR => if (val != Registers.CR2.REG1.SOPI) {
            return error.NotUpdated;
        },
        .DTR => if (val != Registers.CR2.REG1.DOPI) {
            return error.NotUpdated;
        },
    }
}

inline fn enter_sopi() !void {
    return enter_opi_impl(.STR);
}

fn enter_dopi() !void {
    return enter_opi_impl(.DTR);
}

/// Read data from the XSPI NOR Flash
/// Supports both SPI and OPI, but only in STR mode
fn page_read_str(protocol: Protocol, addr_width: AddressWidth, read_address: u32, data: []u8) !void {
    try assert_opi_3bytes(protocol, addr_width);

    const instruction: u32 = switch (protocol) {
        .SPI => switch (addr_width) {
            ._3B => Commands.SPI._3Bytes.FAST_READ,
            ._4B => Commands.SPI._4Bytes.FAST_READ,
        },
        .OPI => Commands.OPI.Memory.READ,
    };

    var command = std.mem.zeroes(hal.c.XSPI_RegularCmdTypeDef);
    command = .{
        .OperationType = hal.c.HAL_XSPI_OPTYPE_COMMON_CFG,
        .InstructionMode = instruction_mode(protocol),
        .InstructionDTRMode = hal.c.HAL_XSPI_INSTRUCTION_DTR_DISABLE,
        .InstructionWidth = instruction_width(protocol),
        .Instruction = instruction,
        .AddressMode = switch (protocol) {
            .SPI => hal.c.HAL_XSPI_ADDRESS_1_LINE,
            .OPI => hal.c.HAL_XSPI_ADDRESS_8_LINES,
        },
        .AddressDTRMode = hal.c.HAL_XSPI_ADDRESS_DTR_DISABLE,
        .AddressWidth = address_width(addr_width),
        .Address = read_address,
        .AlternateBytesMode = hal.c.HAL_XSPI_ALT_BYTES_NONE,
        .DataMode = data_mode(protocol),
        .DataDTRMode = hal.c.HAL_XSPI_DATA_DTR_DISABLE,
        .DummyCycles = switch (protocol) { // ???
            .SPI => DummyCyclesConfig.READ,
            .OPI => DummyCyclesConfig.READ_OCTAL,
        },
        .DataLength = data.len,
        .DQSMode = hal.c.HAL_XSPI_DQS_DISABLE,
    };
    try hal.zig.xspi.send_command(&hxspi, &command);

    try hal.zig.xspi.receive(&hxspi, data.ptr);
}

/// Write data to the XSPI NOR Flash
/// Supports both SPI and OPI, but only in STR mode
/// len(data) <= PAGE_SIZE
fn page_write_str(protocol: Protocol, addr_width: AddressWidth, write_address: u32, data: []const u8) !void {
    try assert_opi_3bytes(protocol, addr_width);

    if (data.len > PAGE_SIZE) {
        std.log.err("Size bigger than a page", .{});
        return error.InvalidParams;
    }

    const instruction: u32 = switch (protocol) {
        .SPI => switch (addr_width) {
            ._3B => Commands.SPI._3Bytes.PAGE_PROG,
            ._4B => Commands.SPI._4Bytes.PAGE_PROG,
        },
        .OPI => Commands.OPI.Memory.PAGE_PROG,
    };

    var command = std.mem.zeroes(hal.c.XSPI_RegularCmdTypeDef);
    command = .{
        .OperationType = hal.c.HAL_XSPI_OPTYPE_COMMON_CFG,
        .InstructionMode = instruction_mode(protocol),
        .InstructionDTRMode = hal.c.HAL_XSPI_INSTRUCTION_DTR_DISABLE,
        .InstructionWidth = instruction_width(protocol),
        .Instruction = instruction,
        .AddressMode = switch (protocol) {
            .SPI => hal.c.HAL_XSPI_ADDRESS_1_LINE,
            .OPI => hal.c.HAL_XSPI_ADDRESS_8_LINES,
        },
        .AddressDTRMode = hal.c.HAL_XSPI_ADDRESS_DTR_DISABLE,
        .AddressWidth = address_width(addr_width),
        .Address = write_address,
        .AlternateBytesMode = hal.c.HAL_XSPI_ALT_BYTES_NONE,
        .DataMode = data_mode(protocol),
        .DataDTRMode = hal.c.HAL_XSPI_DATA_DTR_DISABLE,
        .DummyCycles = 0,
        .DataLength = data.len,
        .DQSMode = hal.c.HAL_XSPI_DQS_DISABLE,
    };
    try hal.zig.xspi.send_command(&hxspi, &command);

    try hal.zig.xspi.transmit(&hxspi, data.ptr);
}

const state = struct {
    var init = false;
    var protocol: Protocol = .SPI;
    var rate: Rate = .STR;
};

fn get_file_stem(comptime file_path: []const u8) []const u8 {
    var path_iterator = std.mem.split(u8, file_path, "/");

    var filename: []const u8 = undefined;
    while (path_iterator.next()) |part| {
        filename = part;
    }

    var name_iterator = std.mem.split(u8, filename, ".zig");
    return name_iterator.first();
}

fn log_error(comptime src: std.builtin.SourceLocation) void {
    std.log.err("{s}.{s}() failed", .{ get_file_stem(src.file), src.fn_name });
    hal.zig.xspi.print_error(&hxspi);
}

pub fn init() !void {
    if (state.init) {
        std.log.warn("external flash was already init", .{});
        return error.AlreadyInit;
    }

    errdefer log_error(@src());

    try hxspi_init();
    try reset();
    try configure(.SPI, .STR);

    state.init = true;
    std.log.debug("OSPI flash ready", .{});
}

pub fn flash_info() Info {
    return .{
        .FlashSize = FLASH_SIZE,
        .EraseSectorSize = BLOCK_64K,
        .EraseSectorsNumber = FLASH_SIZE / BLOCK_64K,
        .EraseSubSectorSize = BLOCK_4K,
        .EraseSubSectorNumber = FLASH_SIZE / BLOCK_4K,
        .EraseSubSector1Size = BLOCK_4K,
        .EraseSubSector1Number = FLASH_SIZE / BLOCK_4K,
        .ProgPageSize = PAGE_SIZE,
        .ProgPagesNumber = FLASH_SIZE / PAGE_SIZE,
    };
}

pub fn reset() !void {
    errdefer log_error(@src());

    try reset_enable(.SPI, .STR);
    try reset_memory(.SPI, .STR);

    try reset_enable(.OPI, .STR);
    try reset_memory(.OPI, .STR);

    try reset_enable(.OPI, .DTR);
    try reset_memory(.OPI, .DTR);

    // Wait in case we sent message while deleting (or something like that)
    hal.c.HAL_Delay(RESET_MAX_TIME);

    try auto_polling_ready(.SPI, .STR);
}

pub fn configure(protocol: Protocol, rate: Rate) !void {
    if (protocol == state.protocol and rate == state.rate) {
        std.log.info("Already in {s} & {s}", .{ @tagName(state.protocol), @tagName(state.rate) });
        return;
    }

    errdefer log_error(@src());

    switch (state.protocol) {
        .SPI => {
            if (protocol == .SPI) {
                std.log.info("Already SPI, and it does not support STR/DTR", .{});
                return;
            }

            switch (state.rate) {
                .STR => try enter_sopi(),
                .DTR => try enter_dopi(),
            }
        },
        .OPI => {
            try exit_opi_mode();

            if (protocol == .SPI) {
                std.log.info("SPI has no STR/DTR", .{});
                return;
            }

            switch (rate) {
                .STR => try enter_sopi(),
                .DTR => try enter_dopi(),
            }
        },
    }

    state.protocol = protocol;
    state.rate = rate;
}

pub inline fn read(read_address: u32, data: []u8) !void {
    errdefer log_error(@src());

    return page_read_str(state.protocol, ._4B, read_address, data);
}

pub inline fn write(write_address: u32, data: []const u8) !void {
    // TODO
    //   - Conditional logic for STR/DTR (write_dtr unimplemented)
    //   - (?) Support buffer.len > PAGE_SIZE
    //   - Check if we will ever need to use ._3B

    errdefer log_error(@src());

    try auto_polling_ready(state.protocol, state.rate);
    std.log.debug("Polled", .{});

    try write_enable(state.protocol, state.rate);
    std.log.debug("write enabled", .{});

    switch (state.rate) {
        .STR => try page_write_str(state.protocol, ._4B, write_address, data),
        .DTR => std.debug.panic("DTR write unimplemented", .{}),
    }
    std.log.debug("wrote", .{});

    try auto_polling_ready(state.protocol, state.rate);
}

// TODO?
//  - MX66UW1G45G_EnableMemoryMappedModeSTR
//  - Some erase function
//  - MX66UW1G45G_PageProgramDTR