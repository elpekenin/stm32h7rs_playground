//! Enum/structs used within the driver

const std = @import("std");

pub const AddressWidth = enum {
    /// 3 Bytes address mode
    ThreeBytes,
    /// 4 Bytes address mode
    FourBytes,
};

pub const BusConfiguration = struct {
    protocol: Protocol,
    rate: Rate,
};

pub const DummyCyclesConfiguration = struct {
    const Self = @This();

    READ: u32,
    READ_OCTAL: u32,
    READ_OCTAL_DTR: u32,
    REG_OCTAL: u32,
    REG_OCTAL_DTR: u32,

    pub fn maxFreq(comptime self: *const Self) u32 {
        return switch (self.READ_OCTAL) {
            20 => 200000000,
            18 => 173000000,
            16 => 166000000,
            14 => 155000000,
            12 => 133000000,
            10 => 104000000,
            8 => 84000000,
            6 => 66000000,
            else => @compileError("Invalid dummy cycles configuration"),
        };
    }
};

pub const Protocol = enum {
    /// 1-1-1 commands, Power on H/W default setting
    SPI,
    /// 8-8-8 commands
    OPI,
};

pub const Rate = enum {
    /// Single Transfer Rate
    STR,
    /// Double Transfer Rate
    DTR,
};

pub const Info = struct {
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

/// How big of a delete
pub const Erase = enum {
    /// 4K size Sector erase
    FourKb,
    /// 64K size Block erase
    SixtyFourKb,
    /// Whole bulk erase
    BULK,
};
