//! Constants extracted from STM's header file

/// 1024 blocks of 64KBytes
pub const BLOCK_64K = 64 * 1024;
/// 16384 sectors of 4KBytes
pub const BLOCK_4K = 4 * 1024;
/// 1 Gbits => 128MBytes
pub const FLASH_SIZE = 1024 * 1024 * 1024 / 8;
/// 262144 pages of 256 Bytes
pub const PAGE_SIZE = 256;

pub const BULK_ERASE_MAX_TIME = 460000;
pub const BLOCK_ERASE_MAX_TIME = 1000;
pub const BLOCK_4K_ERASE_MAX_TIME = 400;
pub const WRITE_REG_MAX_TIME = 40;

/// when SWreset during erase operation
pub const RESET_MAX_TIME = 100;

pub const AUTOPOLLING_INTERVAL_TIME = 0x10;

pub const XSPI_ALTERNATE_BYTE_PATTERN = 0x00;

pub const DUMMY_CYCLES = [_]u8{
    Registers.CR2.REG3.DC_6_CYCLES,
    Registers.CR2.REG3.DC_8_CYCLES,
    Registers.CR2.REG3.DC_10_CYCLES,
    Registers.CR2.REG3.DC_12_CYCLES,
    Registers.CR2.REG3.DC_14_CYCLES,
    Registers.CR2.REG3.DC_16_CYCLES,
    Registers.CR2.REG3.DC_18_CYCLES,
    Registers.CR2.REG3.DC_20_CYCLES,
};

pub const Commands = @import("constants/Commands.zig");
pub const Registers = @import("constants/Registers.zig");
