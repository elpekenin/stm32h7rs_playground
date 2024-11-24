//! Details about the Macronix MX66UW1G45G OctoSPI chip
//!
//! See: https://github.com/STMicroelectronics/stm32h7s78-dk-bsp/blob/main/stm32h7s78_discovery_xspi.c
//! See: https://github.com/STMicroelectronics/stm32-mx66uw1g45g/blob/main/mx66uw1g45g.c

const std = @import("std");
const logger = std.log.scoped(.mx66);

const hal = @import("hal");
const c = hal.c;

const Self = @This();

pub const BASE = 0x70000000;
pub const SIZE = 0x08000000;

// Adapted from STM header file

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

/// User-level configuration of the cycles
const DummyCyclesConfig = struct {
    const READ = 8;
    const READ_OCTAL = 6;
    const READ_OCTAL_DTR = 6;
    const REG_OCTAL = 4;
    const REG_OCTAL_DTR = 5;
};

const MAX_FREQ = switch (DummyCyclesConfig.READ_OCTAL) {
    20 => 200000000,
    18 => 173000000,
    16 => 166000000,
    14 => 155000000,
    12 => 133000000,
    10 => 104000000,
    8 => 84000000,
    6 => 66000000,
    else => @compileError("Invalid config."),
};

/// Dummy cycles needed for different operations
const dummy_cycles_array = [_]u8{ Registers.CR2.REG3.DC_6_CYCLES, Registers.CR2.REG3.DC_8_CYCLES, Registers.CR2.REG3.DC_10_CYCLES, Registers.CR2.REG3.DC_12_CYCLES, Registers.CR2.REG3.DC_14_CYCLES, Registers.CR2.REG3.DC_16_CYCLES, Registers.CR2.REG3.DC_18_CYCLES, Registers.CR2.REG3.DC_20_CYCLES };

/// MX66UW1G45G Commands
const Commands = struct {
    /// SPI-specific commands
    const SPI = struct {
        /// READ/WRITE MEMORY Operations with 3-Byte Address
        const ThreeBytes = struct {
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
        const FourBytes = struct {
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

        /// Setting commands
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
            /// Enter secured OTP
            const ENTER_SECURED_OTP = 0xB1;
            /// Exit secured OTP
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

    /// OPI-specific commands
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
            /// Octa Enter secured OTP
            const ENTER_SECURED_OTP = 0xB14E;
            /// Octa Exit secured OTP
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

/// Registers in the chip and their possible values
const Registers = struct {
    /// Status Register
    const Status = struct {
        /// Write in progress
        const WIP = 0x01;
        /// Write enable latch
        const WELL = 0x02;
        /// Block protected against program and erase operations
        const PB = 0x3C;
    };

    /// Configuration Register 1
    const CR1 = struct {
        /// Output driver strength
        const ODS = 0x07;
        /// Top / bottom  selected
        const TB = 0x08;
        /// Preamble bit enable
        const PBE = 0x10;
    };

    /// Configuration Register 2
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

/// Metadata about the flash chip
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

/// Protocol
const Protocol = enum {
    /// 1-1-1 commands, Power on H/W default setting
    SPI,
    /// 8-8-8 commands
    OPI,
};

/// Data rate
const Rate = enum {
    /// Single Transfer Rate
    STR,
    /// Double Transfer Rate
    DTR,
};

/// How big of a delete
const Erase = enum {
    /// 4K size Sector erase
    FourKb,
    /// 64K size Block erase
    SixtyFourKb,
    /// Whole bulk erase
    BULK,
};

/// Size of the address
const AddressWidth = enum {
    /// 3 Bytes address mode
    ThreeBytes,
    /// 4 Bytes address mode
    FourBytes,
};

/// Internal state of the memory
const State = struct {
    protocol: Protocol,
    rate: Rate,
};

hxspi: c.XSPI_HandleTypeDef,
state: State,

///    .SPI => 0,
///
///    .OPI =>
///
///        .STR => DummyCyclesConfig.REG_OCTAL,
///
///        .DTR => DummyCyclesConfig.REG_OCTAL_DTR,
fn dummy_cycles(protocol: Protocol, rate: Rate) u32 {
    return switch (protocol) {
        .SPI => 0,
        .OPI => switch (rate) {
            .STR => DummyCyclesConfig.REG_OCTAL,
            .DTR => DummyCyclesConfig.REG_OCTAL_DTR,
        },
    };
}

/// Assert that we don't try and use SPI + DTR
fn assert_spi_dtr(protocol: Protocol, rate: Rate) !void {
    if (protocol == .SPI and rate == .DTR) {
        return error.SpiAndDtr;
    }
}

/// Assert that we don't try and use OPI with 3byte address mode
fn assert_opi_3bytes(protocol: Protocol, addr_width: AddressWidth) !void {
    if (protocol == .OPI and addr_width == .ThreeBytes) {
        return error.OpiAnd3B;
    }
}

/// Assert that we don't try and write data longer than a page's size
fn assert_data_len(data: []const u8) !void {
    if (data.len > PAGE_SIZE) {
        return error.DataTooLong;
    }
}

fn init(self: *Self) !void {
    self.hxspi = .{
        .Instance = c.XSPI2,
        .Init = .{
            .FifoThresholdByte = 1,
            .MemorySize = c.HAL_XSPI_SIZE_1GB,
            .ChipSelectHighTimeCycle = 2, // 1 or 2 ??
            .FreeRunningClock = c.HAL_XSPI_FREERUNCLK_DISABLE,
            .ClockMode = c.HAL_XSPI_CLOCK_MODE_0,
            .DelayHoldQuarterCycle = c.HAL_XSPI_DHQC_DISABLE,
            .SampleShifting = c.HAL_XSPI_SAMPLE_SHIFT_NONE, // ??
            .ChipSelectBoundary = c.HAL_XSPI_BONDARYOF_NONE,
            .MemoryMode = c.HAL_XSPI_SINGLE_MEM,
            .WrapSize = c.HAL_XSPI_WRAP_NOT_SUPPORTED,
            .MemoryType = c.HAL_XSPI_MEMTYPE_MACRONIX,
            // .MemorySelect = c.HAL_XSPI_CSSEL_NCS1, // need or skip ??
        },
    };

    const xspi_clk = c.HAL_RCCEx_GetPeriphCLKFreq(c.RCC_PERIPHCLK_XSPI2);
    self.hxspi.Init.ClockPrescaler = xspi_clk / MAX_FREQ;
    if ((xspi_clk % MAX_FREQ) == 0) {
        self.hxspi.Init.ClockPrescaler -= 1;
    }

    try hal.zig.xspi.init(&self.hxspi);
}

fn reset_enable(self: *Self, protocol: Protocol, rate: Rate) !void {
    try assert_spi_dtr(protocol, rate);

    var command = std.mem.zeroes(c.XSPI_RegularCmdTypeDef);
    command = .{
        .OperationType = c.HAL_XSPI_OPTYPE_COMMON_CFG,
        .IOSelect = c.HAL_XSPI_SELECT_IO_3_0,
        .InstructionMode = switch (protocol) {
            .SPI => c.HAL_XSPI_INSTRUCTION_1_LINE,
            .OPI => c.HAL_XSPI_INSTRUCTION_8_LINES,
        },
        .InstructionDTRMode = switch (rate) {
            .STR => c.HAL_XSPI_INSTRUCTION_DTR_DISABLE,
            .DTR => c.HAL_XSPI_INSTRUCTION_DTR_ENABLE,
        },
        .InstructionWidth = switch (protocol) {
            .SPI => c.HAL_XSPI_INSTRUCTION_8_BITS,
            .OPI => c.HAL_XSPI_INSTRUCTION_16_BITS,
        },
        .Instruction = switch (protocol) {
            .SPI => Commands.SPI.Reset.RESET_ENABLE,
            .OPI => Commands.OPI.Reset.RESET_ENABLE,
        },
        .AddressMode = c.HAL_XSPI_ADDRESS_NONE,
        .AlternateBytesMode = c.HAL_XSPI_ALT_BYTES_NONE,
        .DataMode = c.HAL_XSPI_DATA_NONE,
        .DummyCycles = 0,
        .DQSMode = c.HAL_XSPI_DQS_DISABLE,
    };
    try hal.zig.xspi.send_command(&self.hxspi, &command);
}

fn reset_memory(self: *Self, protocol: Protocol, rate: Rate) !void {
    try assert_spi_dtr(protocol, rate);

    var command = std.mem.zeroes(c.XSPI_RegularCmdTypeDef);
    command = .{
        .OperationType = c.HAL_XSPI_OPTYPE_COMMON_CFG,
        .InstructionMode = switch (protocol) {
            .SPI => c.HAL_XSPI_INSTRUCTION_1_LINE,
            .OPI => c.HAL_XSPI_INSTRUCTION_8_LINES,
        },
        .InstructionDTRMode = switch (rate) {
            .STR => c.HAL_XSPI_INSTRUCTION_DTR_DISABLE,
            .DTR => c.HAL_XSPI_INSTRUCTION_DTR_ENABLE,
        },
        .InstructionWidth = switch (protocol) {
            .SPI => c.HAL_XSPI_INSTRUCTION_8_BITS,
            .OPI => c.HAL_XSPI_INSTRUCTION_16_BITS,
        },
        .Instruction = switch (protocol) {
            .SPI => Commands.SPI.Reset.RESET_MEMORY,
            .OPI => Commands.OPI.Reset.RESET_MEMORY,
        },
        .AddressMode = c.HAL_XSPI_ADDRESS_NONE,
        .AlternateBytesMode = c.HAL_XSPI_ALT_BYTES_NONE,
        .DataMode = c.HAL_XSPI_DATA_NONE,
        .DummyCycles = 0,
        .DQSMode = c.HAL_XSPI_DQS_DISABLE,
    };
    try hal.zig.xspi.send_command(&self.hxspi, &command);
}

fn auto_polling_ready(self: *Self, protocol: Protocol, rate: Rate) !void {
    try assert_spi_dtr(protocol, rate);

    var command = std.mem.zeroes(c.XSPI_RegularCmdTypeDef);
    command = .{
        .OperationType = c.HAL_XSPI_OPTYPE_COMMON_CFG,
        .InstructionMode = switch (protocol) {
            .SPI => c.HAL_XSPI_INSTRUCTION_1_LINE,
            .OPI => c.HAL_XSPI_INSTRUCTION_8_LINES,
        },
        .InstructionDTRMode = switch (rate) {
            .STR => c.HAL_XSPI_INSTRUCTION_DTR_DISABLE,
            .DTR => c.HAL_XSPI_INSTRUCTION_DTR_ENABLE,
        },
        .InstructionWidth = switch (protocol) {
            .SPI => c.HAL_XSPI_INSTRUCTION_8_BITS,
            .OPI => c.HAL_XSPI_INSTRUCTION_16_BITS,
        },
        .Instruction = switch (protocol) {
            .SPI => Commands.SPI.Register.READ_STATUS_REG,
            .OPI => Commands.OPI.Register.READ_STATUS_REG,
        },
        .AddressMode = switch (protocol) {
            .SPI => c.HAL_XSPI_ADDRESS_NONE,
            .OPI => c.HAL_XSPI_ADDRESS_8_LINES,
        },
        .AddressDTRMode = switch (rate) {
            .STR => c.HAL_XSPI_ADDRESS_DTR_DISABLE,
            .DTR => c.HAL_XSPI_ADDRESS_DTR_ENABLE,
        },
        .AddressWidth = c.HAL_XSPI_ADDRESS_32_BITS,
        .Address = 0,
        .AlternateBytesMode = c.HAL_XSPI_ALT_BYTES_NONE,
        .DataMode = switch (protocol) {
            .SPI => c.HAL_XSPI_DATA_1_LINE,
            .OPI => c.HAL_XSPI_DATA_8_LINES,
        },
        .DataDTRMode = switch (rate) {
            .STR => c.HAL_XSPI_DATA_DTR_DISABLE,
            .DTR => c.HAL_XSPI_DATA_DTR_ENABLE,
        },
        .DummyCycles = dummy_cycles(protocol, rate),
        .DataLength = switch (rate) {
            .STR => 1,
            .DTR => 2,
        },
        .DQSMode = switch (rate) {
            .STR => c.HAL_XSPI_DQS_DISABLE,
            .DTR => c.HAL_XSPI_DQS_ENABLE,
        },
    };
    try hal.zig.xspi.send_command(&self.hxspi, &command);

    var config = std.mem.zeroInit(
        c.XSPI_AutoPollingTypeDef,
        .{
            .MatchValue = 0,
            .MatchMask = Registers.Status.WIP,
            .MatchMode = c.HAL_XSPI_MATCH_MODE_AND,
            .IntervalTime = AUTOPOLLING_INTERVAL_TIME,
            .AutomaticStop = c.HAL_XSPI_AUTOMATIC_STOP_ENABLE,
        },
    );
    try hal.zig.xspi.auto_polling(&self.hxspi, &config);
}

fn write_enable(self: *Self, protocol: Protocol, rate: Rate) !void {
    try assert_spi_dtr(protocol, rate);

    var command = std.mem.zeroes(c.XSPI_RegularCmdTypeDef);
    command = .{
        .OperationType = c.HAL_XSPI_OPTYPE_COMMON_CFG,
        .InstructionMode = switch (protocol) {
            .SPI => c.HAL_XSPI_INSTRUCTION_1_LINE,
            .OPI => c.HAL_XSPI_INSTRUCTION_8_LINES,
        },
        .InstructionDTRMode = switch (rate) {
            .STR => c.HAL_XSPI_INSTRUCTION_DTR_DISABLE,
            .DTR => c.HAL_XSPI_INSTRUCTION_DTR_ENABLE,
        },
        .InstructionWidth = switch (protocol) {
            .SPI => c.HAL_XSPI_INSTRUCTION_8_BITS,
            .OPI => c.HAL_XSPI_INSTRUCTION_16_BITS,
        },
        .Instruction = switch (protocol) {
            .SPI => Commands.SPI.Settings.WRITE_ENABLE,
            .OPI => Commands.OPI.Settings.WRITE_ENABLE,
        },
        .AddressMode = c.HAL_XSPI_ADDRESS_NONE,
        .AlternateBytesMode = c.HAL_XSPI_ALT_BYTES_NONE,
        .DataMode = c.HAL_XSPI_DATA_NONE,
        .DummyCycles = 0,
        .DQSMode = c.HAL_XSPI_DQS_DISABLE,
    };
    try hal.zig.xspi.send_command(&self.hxspi, &command);

    command.Instruction = switch (protocol) {
        .SPI => Commands.SPI.Register.READ_STATUS_REG,
        .OPI => Commands.OPI.Register.READ_STATUS_REG,
    };
    command.AddressMode = switch (protocol) {
        .SPI => c.HAL_XSPI_ADDRESS_NONE,
        .OPI => c.HAL_XSPI_ADDRESS_8_LINES,
    };
    command.AddressDTRMode = switch (rate) {
        .STR => c.HAL_XSPI_ADDRESS_DTR_DISABLE,
        .DTR => c.HAL_XSPI_ADDRESS_DTR_ENABLE,
    };
    command.AddressWidth = c.HAL_XSPI_ADDRESS_32_BITS;
    command.Address = 0;
    command.DataMode = switch (protocol) {
        .SPI => c.HAL_XSPI_DATA_1_LINE,
        .OPI => c.HAL_XSPI_DATA_8_LINES,
    };
    command.DataDTRMode = switch (rate) {
        .STR => c.HAL_XSPI_DATA_DTR_DISABLE,
        .DTR => c.HAL_XSPI_DATA_DTR_ENABLE,
    };
    command.DummyCycles = dummy_cycles(protocol, rate);
    command.DataLength = switch (rate) {
        .STR => 1,
        .DTR => 2,
    };
    command.DQSMode = switch (rate) {
        .STR => c.HAL_XSPI_DQS_DISABLE,
        .DTR => c.HAL_XSPI_DQS_ENABLE,
    };
    try hal.zig.xspi.send_command(&self.hxspi, &command);

    var config = std.mem.zeroInit(
        c.XSPI_AutoPollingTypeDef,
        .{
            .MatchValue = 2,
            .MatchMask = 2,
            .MatchMode = c.HAL_XSPI_MATCH_MODE_AND,
            .IntervalTime = AUTOPOLLING_INTERVAL_TIME,
            .AutomaticStop = c.HAL_XSPI_AUTOMATIC_STOP_ENABLE,
        },
    );
    try hal.zig.xspi.auto_polling(&self.hxspi, &config);
}

fn write_cfg2(self: *Self, protocol: Protocol, rate: Rate, address: u32, value: u8) !void {
    try assert_spi_dtr(protocol, rate);

    var command = std.mem.zeroes(c.XSPI_RegularCmdTypeDef);
    command = .{
        .OperationType = c.HAL_XSPI_OPTYPE_COMMON_CFG,
        .InstructionMode = switch (protocol) {
            .SPI => c.HAL_XSPI_INSTRUCTION_1_LINE,
            .OPI => c.HAL_XSPI_INSTRUCTION_8_LINES,
        },
        .InstructionDTRMode = switch (rate) {
            .STR => c.HAL_XSPI_INSTRUCTION_DTR_DISABLE,
            .DTR => c.HAL_XSPI_INSTRUCTION_DTR_ENABLE,
        },
        .InstructionWidth = switch (protocol) {
            .SPI => c.HAL_XSPI_INSTRUCTION_8_BITS,
            .OPI => c.HAL_XSPI_INSTRUCTION_16_BITS,
        },
        .Instruction = switch (protocol) {
            .SPI => Commands.SPI.Register.WRITE_CFG_REG2,
            .OPI => Commands.OPI.Register.WRITE_CFG_REG2,
        },
        .AddressMode = switch (protocol) {
            .SPI => c.HAL_XSPI_ADDRESS_NONE,
            .OPI => c.HAL_XSPI_ADDRESS_8_LINES,
        },
        .AddressDTRMode = switch (rate) {
            .STR => c.HAL_XSPI_ADDRESS_DTR_DISABLE,
            .DTR => c.HAL_XSPI_ADDRESS_DTR_ENABLE,
        },
        .AddressWidth = c.HAL_XSPI_ADDRESS_32_BITS,
        .Address = address,
        .AlternateBytesMode = c.HAL_XSPI_ALT_BYTES_NONE,
        .DataMode = switch (protocol) {
            .SPI => c.HAL_XSPI_DATA_1_LINE,
            .OPI => c.HAL_XSPI_DATA_8_LINES,
        },
        .DataDTRMode = switch (rate) {
            .STR => c.HAL_XSPI_DATA_DTR_DISABLE,
            .DTR => c.HAL_XSPI_DATA_DTR_ENABLE,
        },
        .DummyCycles = 0,
        .DataLength = switch (rate) {
            .STR => 1,
            .DTR => 2,
        },
        .DQSMode = c.HAL_XSPI_DQS_DISABLE,
    };
    try hal.zig.xspi.send_command(&self.hxspi, &command);

    // zig does not like &value (it is `*const u8` instead of `[]const u8`)
    const temp = [_]u8{value};
    try hal.zig.xspi.transmit(&self.hxspi, &temp);
}

fn read_cfg2(self: *Self, protocol: Protocol, rate: Rate, address: u32) !u8 {
    try assert_spi_dtr(protocol, rate);

    var command = std.mem.zeroes(c.XSPI_RegularCmdTypeDef);
    command = .{
        .OperationType = c.HAL_XSPI_OPTYPE_COMMON_CFG,
        .InstructionMode = switch (protocol) {
            .SPI => c.HAL_XSPI_INSTRUCTION_1_LINE,
            .OPI => c.HAL_XSPI_INSTRUCTION_8_LINES,
        },
        .InstructionDTRMode = switch (rate) {
            .STR => c.HAL_XSPI_INSTRUCTION_DTR_DISABLE,
            .DTR => c.HAL_XSPI_INSTRUCTION_DTR_ENABLE,
        },
        .InstructionWidth = switch (protocol) {
            .SPI => c.HAL_XSPI_INSTRUCTION_8_BITS,
            .OPI => c.HAL_XSPI_INSTRUCTION_16_BITS,
        },
        .Instruction = switch (protocol) {
            .SPI => Commands.SPI.Register.READ_CFG_REG2,
            .OPI => Commands.OPI.Register.READ_CFG_REG2,
        },
        .AddressMode = switch (protocol) {
            .SPI => c.HAL_XSPI_ADDRESS_NONE,
            .OPI => c.HAL_XSPI_ADDRESS_8_LINES,
        },
        .AddressDTRMode = switch (rate) {
            .STR => c.HAL_XSPI_ADDRESS_DTR_DISABLE,
            .DTR => c.HAL_XSPI_ADDRESS_DTR_ENABLE,
        },
        .AddressWidth = c.HAL_XSPI_ADDRESS_32_BITS,
        .Address = address,
        .AlternateBytesMode = c.HAL_XSPI_ALT_BYTES_NONE,
        .DataMode = switch (protocol) {
            .SPI => c.HAL_XSPI_DATA_1_LINE,
            .OPI => c.HAL_XSPI_DATA_8_LINES,
        },
        .DataDTRMode = switch (rate) {
            .STR => c.HAL_XSPI_DATA_DTR_DISABLE,
            .DTR => c.HAL_XSPI_DATA_DTR_ENABLE,
        },
        .DummyCycles = dummy_cycles(protocol, rate),
        .DataLength = switch (rate) {
            .STR => 1,
            .DTR => 2,
        },
        .DQSMode = switch (rate) {
            .STR => c.HAL_XSPI_DQS_DISABLE,
            .DTR => c.HAL_XSPI_DQS_ENABLE,
        },
    };
    try hal.zig.xspi.send_command(&self.hxspi, &command);

    var value: [2]u8 = undefined;
    try hal.zig.xspi.receive(&self.hxspi, &value);

    return value[0];
}

fn exit_opi(self: *Self) !void {
    try self.write_enable(self.state.protocol, self.state.rate);

    try self.write_cfg2(self.state.protocol, self.state.rate, Registers.CR2.REG1.ADDR, 0);

    hal.zig.timer.sleep(WRITE_REG_MAX_TIME);

    if (self.state.rate == .DTR) {
        self.hxspi.Init.MemoryType = c.HAL_XSPI_MEMTYPE_MICRON;
        self.hxspi.Init.DelayHoldQuarterCycle = c.HAL_XSPI_DHQC_DISABLE;
        try hal.zig.xspi.init(&self.hxspi);
    }

    try self.auto_polling_ready(.SPI, .STR);

    const value = try self.read_cfg2(.SPI, .STR, Registers.CR2.REG1.ADDR);
    if (value != 0) {
        return error.DidNotExitOPI;
    }
}

fn enter_opi(self: *Self, rate: Rate) !void {
    try self.write_enable(self.state.protocol, self.state.rate);

    try self.write_cfg2(self.state.protocol, self.state.rate, Registers.CR2.REG3.ADDR, dummy_cycles_array[(DummyCyclesConfig.READ_OCTAL / 2) - 3]);

    try self.write_enable(self.state.protocol, self.state.rate);

    try self.write_cfg2(self.state.protocol, self.state.rate, Registers.CR2.REG1.ADDR, switch (rate) {
        .STR => Registers.CR2.REG1.SOPI,
        .DTR => Registers.CR2.REG1.DOPI,
    });

    hal.zig.timer.sleep(WRITE_REG_MAX_TIME);

    if (rate == .DTR) {
        self.hxspi.Init.MemoryType = c.HAL_XSPI_MEMTYPE_MACRONIX;
        self.hxspi.Init.DelayHoldQuarterCycle = c.HAL_XSPI_DHQC_ENABLE;
        try hal.zig.xspi.init(&self.hxspi);
    }

    try self.auto_polling_ready(.OPI, rate);

    const value = try self.read_cfg2(.OPI, rate, Registers.CR2.REG1.ADDR);
    switch (rate) {
        .STR => if (value != Registers.CR2.REG1.SOPI) {
            return error.DidNotEnterSOPI;
        },
        .DTR => if (value != Registers.CR2.REG1.DOPI) {
            return error.DidNotEnterDOPI;
        },
    }
}

/// Read data from the XSPI NOR Flash
/// Supports both SPI and OPI, but only in STR mode
fn page_read_str(self: *Self, read_address: u32, data: []u8) !void {
    const addr_width: AddressWidth = .FourBytes;

    try assert_opi_3bytes(self.state.protocol, addr_width);
    try assert_data_len(data);

    var command = std.mem.zeroes(c.XSPI_RegularCmdTypeDef);
    command = .{
        .OperationType = c.HAL_XSPI_OPTYPE_COMMON_CFG,
        .InstructionMode = switch (self.state.protocol) {
            .SPI => c.HAL_XSPI_INSTRUCTION_1_LINE,
            .OPI => c.HAL_XSPI_INSTRUCTION_8_LINES,
        },
        .InstructionDTRMode = c.HAL_XSPI_INSTRUCTION_DTR_DISABLE,
        .InstructionWidth = switch (self.state.protocol) {
            .SPI => c.HAL_XSPI_INSTRUCTION_8_BITS,
            .OPI => c.HAL_XSPI_INSTRUCTION_16_BITS,
        },
        .Instruction = switch (self.state.protocol) {
            .SPI => switch (addr_width) {
                .ThreeBytes => Commands.SPI.ThreeBytes.FAST_READ,
                .FourBytes => Commands.SPI.FourBytes.FAST_READ,
            },
            .OPI => Commands.OPI.Memory.READ,
        },
        .AddressMode = switch (self.state.protocol) {
            .SPI => c.HAL_XSPI_ADDRESS_1_LINE,
            .OPI => c.HAL_XSPI_ADDRESS_8_LINES,
        },
        .AddressDTRMode = c.HAL_XSPI_ADDRESS_DTR_DISABLE,
        .AddressWidth = switch (addr_width) {
            .ThreeBytes => c.HAL_XSPI_ADDRESS_24_BITS,
            .FourBytes => c.HAL_XSPI_ADDRESS_32_BITS,
        },
        .Address = read_address,
        .AlternateBytesMode = c.HAL_XSPI_ALT_BYTES_NONE,
        .DataMode = switch (self.state.protocol) {
            .SPI => c.HAL_XSPI_DATA_1_LINE,
            .OPI => c.HAL_XSPI_DATA_8_LINES,
        },
        .DataDTRMode = c.HAL_XSPI_DATA_DTR_DISABLE,
        .DummyCycles = switch (self.state.protocol) {
            .SPI => DummyCyclesConfig.READ,
            .OPI => DummyCyclesConfig.READ_OCTAL,
        },
        .DataLength = data.len,
        .DQSMode = c.HAL_XSPI_DQS_DISABLE,
    };
    try hal.zig.xspi.send_command(&self.hxspi, &command);

    try hal.zig.xspi.receive(&self.hxspi, data.ptr);
}

fn page_read_dtr(self: *Self, read_address: u32, data: []u8) !void {
    try assert_spi_dtr(self.state.protocol, self.state.rate);

    var command = std.mem.zeroes(c.XSPI_RegularCmdTypeDef);
    command = .{
        .OperationType = c.HAL_XSPI_OPTYPE_COMMON_CFG,
        .InstructionMode = c.HAL_XSPI_INSTRUCTION_8_LINES,
        .InstructionDTRMode = c.HAL_XSPI_INSTRUCTION_DTR_ENABLE,
        .InstructionWidth = c.HAL_XSPI_INSTRUCTION_16_BITS,
        .Instruction = Commands.OPI.Memory.READ_DTR,
        .AddressMode = c.HAL_XSPI_ADDRESS_8_LINES,
        .AddressDTRMode = c.HAL_XSPI_ADDRESS_DTR_ENABLE,
        .AddressWidth = c.HAL_XSPI_ADDRESS_32_BITS,
        .Address = read_address,
        .AlternateBytesMode = c.HAL_XSPI_ALT_BYTES_NONE,
        .DataMode = c.HAL_XSPI_DATA_8_LINES,
        .DataDTRMode = c.HAL_XSPI_DATA_DTR_ENABLE,
        .DummyCycles = DummyCyclesConfig.READ_OCTAL_DTR,
        .DataLength = data.len,
        .DQSMode = c.HAL_XSPI_DQS_ENABLE,
    };
    try hal.zig.xspi.send_command(&self.hxspi, &command);

    try hal.zig.xspi.receive(&self.hxspi, data.ptr);
}

/// Write data to the XSPI NOR Flash
/// len(data) <= PAGE_SIZE
fn page_write_str(self: *Self, write_address: u32, data: []const u8) !void {
    const addr_width: AddressWidth = .FourBytes;

    try assert_opi_3bytes(self.state.protocol, addr_width);
    try assert_data_len(data);

    var command = std.mem.zeroes(c.XSPI_RegularCmdTypeDef);
    command = .{
        .OperationType = c.HAL_XSPI_OPTYPE_COMMON_CFG,
        .InstructionMode = switch (self.state.protocol) {
            .SPI => c.HAL_XSPI_INSTRUCTION_1_LINE,
            .OPI => c.HAL_XSPI_INSTRUCTION_8_LINES,
        },
        .InstructionDTRMode = c.HAL_XSPI_INSTRUCTION_DTR_DISABLE,
        .InstructionWidth = switch (self.state.protocol) {
            .SPI => c.HAL_XSPI_INSTRUCTION_8_BITS,
            .OPI => c.HAL_XSPI_INSTRUCTION_16_BITS,
        },
        .Instruction = switch (self.state.protocol) {
            .SPI => switch (addr_width) {
                .ThreeBytes => Commands.SPI.ThreeBytes.PAGE_PROG,
                .FourBytes => Commands.SPI.FourBytes.PAGE_PROG,
            },
            .OPI => Commands.OPI.Memory.PAGE_PROG,
        },
        .AddressMode = switch (self.state.protocol) {
            .SPI => c.HAL_XSPI_ADDRESS_1_LINE,
            .OPI => c.HAL_XSPI_ADDRESS_8_LINES,
        },
        .AddressDTRMode = c.HAL_XSPI_ADDRESS_DTR_DISABLE,
        .AddressWidth = switch (addr_width) {
            .ThreeBytes => c.HAL_XSPI_ADDRESS_24_BITS,
            .FourBytes => c.HAL_XSPI_ADDRESS_32_BITS,
        },
        .Address = write_address,
        .AlternateBytesMode = c.HAL_XSPI_ALT_BYTES_NONE,
        .DataMode = switch (self.state.protocol) {
            .SPI => c.HAL_XSPI_DATA_1_LINE,
            .OPI => c.HAL_XSPI_DATA_8_LINES,
        },
        .DataDTRMode = c.HAL_XSPI_DATA_DTR_DISABLE,
        .DummyCycles = 0,
        .DataLength = data.len,
        .DQSMode = c.HAL_XSPI_DQS_DISABLE,
    };
    try hal.zig.xspi.send_command(&self.hxspi, &command);

    try hal.zig.xspi.transmit(&self.hxspi, data.ptr);
}

/// Write data to the XSPI NOR Flash
/// len(data) <= PAGE_SIZE
fn page_write_dtr(self: *Self, write_address: u32, data: []const u8) !void {
    try assert_spi_dtr(self.state.protocol, self.state.rate);
    try assert_data_len(data);

    var command = std.mem.zeroInit(
        c.XSPI_RegularCmdTypeDef,
        .{
            .OperationType = c.HAL_XSPI_OPTYPE_COMMON_CFG,
            .InstructionMode = c.HAL_XSPI_INSTRUCTION_8_LINES,
            .InstructionDTRMode = c.HAL_XSPI_INSTRUCTION_DTR_ENABLE,
            .InstructionWidth = c.HAL_XSPI_INSTRUCTION_16_BITS,
            .Instruction = Commands.OPI.Memory.PAGE_PROG,
            .AddressMode = c.HAL_XSPI_ADDRESS_8_LINES,
            .AddressDTRMode = c.HAL_XSPI_ADDRESS_DTR_ENABLE,
            .AddressWidth = c.HAL_XSPI_ADDRESS_32_BITS,
            .Address = write_address,
            .AlternateBytesMode = c.HAL_XSPI_ALT_BYTES_NONE,
            .DataMode = c.HAL_XSPI_DATA_8_LINES,
            .DataDTRMode = c.HAL_XSPI_DATA_DTR_ENABLE,
            .DummyCycles = 0,
            .DataLength = data.len,
            .DQSMode = c.HAL_XSPI_DQS_DISABLE,
        },
    );
    try hal.zig.xspi.send_command(&self.hxspi, &command);

    try hal.zig.xspi.transmit(&self.hxspi, data.ptr);
}

// Public API

/// Configure the device before using it
pub fn new(protocol: Protocol, rate: Rate) !Self {
    var self: Self = .{
        .hxspi = std.mem.zeroes(c.XSPI_HandleTypeDef),
        .state = .{
            .protocol = .SPI,
            .rate = .STR,
        },
    };

    try self.init();
    try self.reset();
    try self.auto_polling_ready(.SPI, .STR);
    try self.configure(protocol, rate);

    logger.debug("OSPI flash ready", .{});
    return self;
}

/// Get information about the chip
pub fn flashInfo(_: *const Self) Info {
    // TODO?: actually query
    return Info{
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

/// Reset the device
pub fn reset(self: *Self) !void {
    try self.reset_enable(.SPI, .STR);
    try self.reset_memory(.SPI, .STR);

    try self.reset_enable(.OPI, .STR);
    try self.reset_memory(.OPI, .STR);

    try self.reset_enable(.OPI, .DTR);
    try self.reset_memory(.OPI, .DTR);

    // Wait in case we sent message while deleting (or something like that)
    hal.zig.timer.sleep(RESET_MAX_TIME);
}

/// Change the protocol/rate used to talk to chip
pub fn configure(self: *Self, protocol: Protocol, rate: Rate) !void {
    // already in this state
    if (self.state.protocol == protocol and self.state.rate == rate) {
        return;
    }

    switch (self.state.protocol) {
        .SPI => switch (protocol) {
            // already SPI, it has no STR/DTR, nothing to do here
            .SPI => {},
            .OPI => try self.enter_opi(rate),
        },

        .OPI => {
            try self.exit_opi();

            switch (protocol) {
                // SPI has no STR/DTR, just exit OPI
                .SPI => {},
                .OPI => if (self.state.rate != rate) {
                    try self.enter_opi(rate);
                },
            }
        },
    }

    self.state.protocol = protocol;
    self.state.rate = rate;

    logger.debug("Configured {} {}", .{ protocol, rate });
}

/// Read from the flash
pub fn read(self: *Self, read_address: u32, data: []u8) !void {
    switch (self.state.rate) {
        .STR => try self.page_read_str(read_address, data),
        .DTR => try self.page_read_dtr(read_address, data),
    }

    logger.debug("read: {any}", .{data});
}

/// Write into the flash
pub fn write(self: *Self, write_address: u32, data: []const u8) !void {
    // TODO
    //   - (?) Support buffer.len > PAGE_SIZE
    //   - Check if we will ever need to use .ThreeBytes

    try self.auto_polling_ready(self.state.protocol, self.state.rate);
    try self.write_enable(self.state.protocol, self.state.rate);

    switch (self.state.rate) {
        .STR => try self.page_write_str(write_address, data),
        .DTR => try self.page_write_dtr(write_address, data),
    }
    logger.debug("wrote {any}", .{data});

    try self.auto_polling_ready(self.state.protocol, self.state.rate);
}

// TODO?
//  - MX66UW1G45G_EnableMemoryMappedModeSTR
//  - Some erase function
