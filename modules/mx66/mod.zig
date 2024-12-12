//! Details about the Macronix MX66UW1G45G OctoSPI chip
//!
//! See: https://github.com/STMicroelectronics/stm32h7s78-dk-bsp/blob/main/stm32h7s78_discovery_xspi.c
//! See: https://github.com/STMicroelectronics/stm32-mx66uw1g45g/blob/main/mx66uw1g45g.c

const std = @import("std");
const logger = std.log.scoped(.mx66);

const hal = @import("hal");
const c = hal.c;

const root = @import("root");

const constants = @import("constants.zig");
const Commands = constants.Commands;
const Registers = constants.Registers;

const types = @import("types.zig");
const AddressWidth = types.AddressWidth;
const BusConfiguration = types.BusConfiguration;
pub const DummyCyclesConfiguration = types.DummyCyclesConfiguration;
const Protocol = types.Protocol;
const Rate = types.Rate;

const Self = @This();

fn assertSpiDtr(bus_config: BusConfiguration) !void {
    if (bus_config.protocol == .SPI and bus_config.rate == .DTR) {
        return error.SpiAndDtr;
    }
}

fn assertOpiThreeBytes(protocol: Protocol, addr_width: AddressWidth) !void {
    if (protocol == .OPI and addr_width == .ThreeBytes) {
        return error.OpiAnd3B;
    }
}

fn assertDataLength(data: []const u8) !void {
    if (data.len > constants.PAGE_SIZE) {
        return error.DataTooLong;
    }
}

const Config: DummyCyclesConfiguration = root.dummy_cycles_config;

hxspi: c.XSPI_HandleTypeDef,
bus_config: BusConfiguration,

// TODO?
//  - MX66UW1G45G_EnableMemoryMappedModeSTR
//  - Some erase function
pub const read = Read.read;
pub const write = Write.write;

pub fn new(bus_config: BusConfiguration) !Self {
    var self: Self = .{
        .hxspi = std.mem.zeroes(c.XSPI_HandleTypeDef),
        .bus_config = bus_config,
    };

    errdefer hal.zig.xspi.printError(&self.hxspi);

    try self.init(bus_config.rate);
    try self.reset();
    // first poll is always .SPI + .STR
    try self.pollReady(.{
        .protocol = .SPI,
        .rate = .STR,
    });
    try self.configure(bus_config);

    logger.info("Flash ready", .{});
    return self;
}

pub fn info(_: *const Self) types.Info {
    // TODO?: actually query
    return types.Info{
        .FlashSize = constants.FLASH_SIZE,
        .EraseSectorSize = constants.BLOCK_64K,
        .EraseSectorsNumber = constants.FLASH_SIZE / constants.BLOCK_64K,
        .EraseSubSectorSize = constants.BLOCK_4K,
        .EraseSubSectorNumber = constants.FLASH_SIZE / constants.BLOCK_4K,
        .EraseSubSector1Size = constants.BLOCK_4K,
        .EraseSubSector1Number = constants.FLASH_SIZE / constants.BLOCK_4K,
        .ProgPageSize = constants.PAGE_SIZE,
        .ProgPagesNumber = constants.FLASH_SIZE / constants.PAGE_SIZE,
    };
}

pub fn reset(self: *Self) !void {
    try self.resetEnable(.{
        .protocol = .SPI,
        .rate = .STR,
    });
    try self.resetMemory(.{
        .protocol = .SPI,
        .rate = .STR,
    });

    try self.resetEnable(.{
        .protocol = .OPI,
        .rate = .STR,
    });
    try self.resetMemory(.{
        .protocol = .OPI,
        .rate = .STR,
    });

    try self.resetEnable(.{
        .protocol = .OPI,
        .rate = .DTR,
    });
    try self.resetMemory(.{
        .protocol = .OPI,
        .rate = .DTR,
    });

    // Wait in case we sent message while deleting (or something like that)
    hal.zig.timer.sleep(.{ .milliseconds = constants.RESET_MAX_TIME });
}

pub fn configure(self: *Self, bus_config: BusConfiguration) !void {
    // already in this state
    if (bus_config.protocol == self.bus_config.protocol and bus_config.rate == self.bus_config.rate) {
        return;
    }

    switch (self.bus_config.protocol) {
        .SPI => switch (bus_config.protocol) {
            // already SPI, it has no STR/DTR, nothing to do here
            .SPI => {},
            .OPI => try Opi.enter(self, bus_config.rate),
        },

        .OPI => {
            try Opi.exit(self);

            switch (bus_config.protocol) {
                // SPI has no STR/DTR, just exit OPI
                .SPI => {},
                .OPI => if (bus_config.rate != self.bus_config.rate) {
                    try Opi.enter(self, bus_config.rate);
                },
            }
        },
    }

    self.bus_config = bus_config;

    logger.info("Configured {}", .{bus_config});
}

fn init(self: *Self, rate: Rate) !void {
    const flash_info = self.info();

    self.hxspi = .{
        .Instance = c.XSPI2,
        .Init = .{
            .FifoThresholdByte = 1,
            // is this requivalent to POSITION_VAL??
            .MemorySize = @clz(@bitReverse(flash_info.FlashSize)),
            .ChipSelectHighTimeCycle = 2, // 1 or 2 ??
            .FreeRunningClock = c.HAL_XSPI_FREERUNCLK_DISABLE,
            .ClockMode = c.HAL_XSPI_CLOCK_MODE_0,
            // not using self.bus_config because it is not set yet
            // it will be set after initialization, thus we receive
            // here the desired state
            .DelayHoldQuarterCycle = switch (rate) {
                .STR => c.HAL_XSPI_DHQC_DISABLE,
                .DTR => c.HAL_XSPI_DHQC_ENABLE,
            },
            .SampleShifting = c.HAL_XSPI_SAMPLE_SHIFT_NONE,
            .ChipSelectBoundary = c.HAL_XSPI_BONDARYOF_NONE,
            .MemoryMode = c.HAL_XSPI_SINGLE_MEM,
            .WrapSize = c.HAL_XSPI_WRAP_NOT_SUPPORTED,
            .MemoryType = c.HAL_XSPI_MEMTYPE_MACRONIX,
        },
    };

    const xspi_clk = c.HAL_RCCEx_GetPeriphCLKFreq(c.RCC_PERIPHCLK_XSPI2);
    const max_freq = Config.maxFreq();
    self.hxspi.Init.ClockPrescaler = xspi_clk / max_freq;
    if ((xspi_clk % max_freq) == 0) {
        self.hxspi.Init.ClockPrescaler -= 1;
    }

    try hal.zig.xspi.init(&self.hxspi);
}

fn resetEnable(self: *Self, bus_config: BusConfiguration) !void {
    try assertSpiDtr(bus_config);

    const command: c.XSPI_RegularCmdTypeDef = .{
        .OperationType = c.HAL_XSPI_OPTYPE_COMMON_CFG,
        .IOSelect = c.HAL_XSPI_SELECT_IO_3_0,
        .InstructionMode = switch (bus_config.protocol) {
            .SPI => c.HAL_XSPI_INSTRUCTION_1_LINE,
            .OPI => c.HAL_XSPI_INSTRUCTION_8_LINES,
        },
        .InstructionDTRMode = switch (bus_config.rate) {
            .STR => c.HAL_XSPI_INSTRUCTION_DTR_DISABLE,
            .DTR => c.HAL_XSPI_INSTRUCTION_DTR_ENABLE,
        },
        .InstructionWidth = switch (bus_config.protocol) {
            .SPI => c.HAL_XSPI_INSTRUCTION_8_BITS,
            .OPI => c.HAL_XSPI_INSTRUCTION_16_BITS,
        },
        .Instruction = switch (bus_config.protocol) {
            .SPI => Commands.SPI.Reset.RESET_ENABLE,
            .OPI => Commands.OPI.Reset.RESET_ENABLE,
        },
        .AddressMode = c.HAL_XSPI_ADDRESS_NONE,
        .AlternateBytesMode = c.HAL_XSPI_ALT_BYTES_NONE,
        .DataMode = c.HAL_XSPI_DATA_NONE,
        .DummyCycles = 0,
        .DQSMode = c.HAL_XSPI_DQS_DISABLE,
    };
    try hal.zig.xspi.command(&self.hxspi, &command);
}

fn resetMemory(self: *Self, bus_config: BusConfiguration) !void {
    try assertSpiDtr(bus_config);

    const command: c.XSPI_RegularCmdTypeDef = .{
        .OperationType = c.HAL_XSPI_OPTYPE_COMMON_CFG,
        .InstructionMode = switch (bus_config.protocol) {
            .SPI => c.HAL_XSPI_INSTRUCTION_1_LINE,
            .OPI => c.HAL_XSPI_INSTRUCTION_8_LINES,
        },
        .InstructionDTRMode = switch (bus_config.rate) {
            .STR => c.HAL_XSPI_INSTRUCTION_DTR_DISABLE,
            .DTR => c.HAL_XSPI_INSTRUCTION_DTR_ENABLE,
        },
        .InstructionWidth = switch (bus_config.protocol) {
            .SPI => c.HAL_XSPI_INSTRUCTION_8_BITS,
            .OPI => c.HAL_XSPI_INSTRUCTION_16_BITS,
        },
        .Instruction = switch (bus_config.protocol) {
            .SPI => Commands.SPI.Reset.RESET_MEMORY,
            .OPI => Commands.OPI.Reset.RESET_MEMORY,
        },
        .AddressMode = c.HAL_XSPI_ADDRESS_NONE,
        .AlternateBytesMode = c.HAL_XSPI_ALT_BYTES_NONE,
        .DataMode = c.HAL_XSPI_DATA_NONE,
        .DummyCycles = 0,
        .DQSMode = c.HAL_XSPI_DQS_DISABLE,
    };
    try hal.zig.xspi.command(&self.hxspi, &command);
}

fn pollReady(self: *Self, bus_config: BusConfiguration) !void {
    try assertSpiDtr(bus_config);

    const command: c.XSPI_RegularCmdTypeDef = .{
        .OperationType = c.HAL_XSPI_OPTYPE_COMMON_CFG,
        .InstructionMode = switch (bus_config.protocol) {
            .SPI => c.HAL_XSPI_INSTRUCTION_1_LINE,
            .OPI => c.HAL_XSPI_INSTRUCTION_8_LINES,
        },
        .InstructionDTRMode = switch (bus_config.rate) {
            .STR => c.HAL_XSPI_INSTRUCTION_DTR_DISABLE,
            .DTR => c.HAL_XSPI_INSTRUCTION_DTR_ENABLE,
        },
        .InstructionWidth = switch (bus_config.protocol) {
            .SPI => c.HAL_XSPI_INSTRUCTION_8_BITS,
            .OPI => c.HAL_XSPI_INSTRUCTION_16_BITS,
        },
        .Instruction = switch (bus_config.protocol) {
            .SPI => Commands.SPI.Register.READ_STATUS_REG,
            .OPI => Commands.OPI.Register.READ_STATUS_REG,
        },
        .AddressMode = switch (bus_config.protocol) {
            .SPI => c.HAL_XSPI_ADDRESS_NONE,
            .OPI => c.HAL_XSPI_ADDRESS_8_LINES,
        },
        .AddressDTRMode = switch (bus_config.rate) {
            .STR => c.HAL_XSPI_ADDRESS_DTR_DISABLE,
            .DTR => c.HAL_XSPI_ADDRESS_DTR_ENABLE,
        },
        .AddressWidth = c.HAL_XSPI_ADDRESS_32_BITS,
        .Address = 0,
        .AlternateBytesMode = c.HAL_XSPI_ALT_BYTES_NONE,
        .DataMode = switch (bus_config.protocol) {
            .SPI => c.HAL_XSPI_DATA_1_LINE,
            .OPI => c.HAL_XSPI_DATA_8_LINES,
        },
        .DataDTRMode = switch (bus_config.rate) {
            .STR => c.HAL_XSPI_DATA_DTR_DISABLE,
            .DTR => c.HAL_XSPI_DATA_DTR_ENABLE,
        },
        .DummyCycles = switch (bus_config.protocol) {
            .SPI => 0,
            .OPI => switch (bus_config.rate) {
                .STR => Config.REG_OCTAL,
                .DTR => Config.REG_OCTAL_DTR,
            },
        },
        .DataLength = switch (bus_config.rate) {
            .STR => 1,
            .DTR => 2,
        },
        .DQSMode = switch (bus_config.rate) {
            .STR => c.HAL_XSPI_DQS_DISABLE,
            .DTR => c.HAL_XSPI_DQS_ENABLE,
        },
    };
    try hal.zig.xspi.command(&self.hxspi, &command);

    const config: c.XSPI_AutoPollingTypeDef = .{
        .MatchValue = 0,
        .MatchMask = Registers.Status.WIP,
        .MatchMode = c.HAL_XSPI_MATCH_MODE_AND,
        .IntervalTime = constants.AUTOPOLLING_INTERVAL_TIME,
        .AutomaticStop = c.HAL_XSPI_AUTOMATIC_STOP_ENABLE,
    };
    try hal.zig.xspi.polling(&self.hxspi, &config);
}

fn writeEnable(self: *Self, bus_config: BusConfiguration) !void {
    try assertSpiDtr(bus_config);

    const write_enable_command: c.XSPI_RegularCmdTypeDef = .{
        .OperationType = c.HAL_XSPI_OPTYPE_COMMON_CFG,
        .InstructionMode = switch (bus_config.protocol) {
            .SPI => c.HAL_XSPI_INSTRUCTION_1_LINE,
            .OPI => c.HAL_XSPI_INSTRUCTION_8_LINES,
        },
        .InstructionDTRMode = switch (bus_config.rate) {
            .STR => c.HAL_XSPI_INSTRUCTION_DTR_DISABLE,
            .DTR => c.HAL_XSPI_INSTRUCTION_DTR_ENABLE,
        },
        .InstructionWidth = switch (bus_config.protocol) {
            .SPI => c.HAL_XSPI_INSTRUCTION_8_BITS,
            .OPI => c.HAL_XSPI_INSTRUCTION_16_BITS,
        },
        .Instruction = switch (bus_config.protocol) {
            .SPI => Commands.SPI.Settings.WRITE_ENABLE,
            .OPI => Commands.OPI.Settings.WRITE_ENABLE,
        },
        .AddressMode = c.HAL_XSPI_ADDRESS_NONE,
        .AlternateBytesMode = c.HAL_XSPI_ALT_BYTES_NONE,
        .DataMode = c.HAL_XSPI_DATA_NONE,
        .DummyCycles = 0,
        .DQSMode = c.HAL_XSPI_DQS_DISABLE,
    };
    try hal.zig.xspi.command(&self.hxspi, &write_enable_command);

    var read_status_command: c.XSPI_RegularCmdTypeDef = write_enable_command;
    // v specific for this command v
    read_status_command.AddressDTRMode = switch (bus_config.rate) {
        .STR => c.HAL_XSPI_ADDRESS_DTR_DISABLE,
        .DTR => c.HAL_XSPI_ADDRESS_DTR_ENABLE,
    };
    read_status_command.AddressWidth = c.HAL_XSPI_ADDRESS_32_BITS;
    read_status_command.Address = 0;
    read_status_command.DataDTRMode = switch (bus_config.rate) {
        .STR => c.HAL_XSPI_DATA_DTR_DISABLE,
        .DTR => c.HAL_XSPI_DATA_DTR_ENABLE,
    };
    read_status_command.DataLength = switch (bus_config.rate) {
        .STR => 1,
        .DTR => 2,
    };

    try hal.zig.xspi.command(&self.hxspi, &read_status_command);

    const config: c.XSPI_AutoPollingTypeDef = .{
        .MatchValue = 2,
        .MatchMask = 2,
        .MatchMode = c.HAL_XSPI_MATCH_MODE_AND,
        .IntervalTime = constants.AUTOPOLLING_INTERVAL_TIME,
        .AutomaticStop = c.HAL_XSPI_AUTOMATIC_STOP_ENABLE,
    };
    try hal.zig.xspi.polling(&self.hxspi, &config);
}

// Namespaces for convenience

const Cfg2 = struct {
    fn write(self: *Self, bus_config: BusConfiguration, address: u32, value: u8) !void {
        try assertSpiDtr(bus_config);

        const command: c.XSPI_RegularCmdTypeDef = .{
            .OperationType = c.HAL_XSPI_OPTYPE_COMMON_CFG,
            .InstructionMode = switch (bus_config.protocol) {
                .SPI => c.HAL_XSPI_INSTRUCTION_1_LINE,
                .OPI => c.HAL_XSPI_INSTRUCTION_8_LINES,
            },
            .InstructionDTRMode = switch (bus_config.rate) {
                .STR => c.HAL_XSPI_INSTRUCTION_DTR_DISABLE,
                .DTR => c.HAL_XSPI_INSTRUCTION_DTR_ENABLE,
            },
            .InstructionWidth = switch (bus_config.protocol) {
                .SPI => c.HAL_XSPI_INSTRUCTION_8_BITS,
                .OPI => c.HAL_XSPI_INSTRUCTION_16_BITS,
            },
            .Instruction = switch (bus_config.protocol) {
                .SPI => Commands.SPI.Register.WRITE_CFG_REG2,
                .OPI => Commands.OPI.Register.WRITE_CFG_REG2,
            },
            .AddressMode = switch (bus_config.protocol) {
                .SPI => c.HAL_XSPI_ADDRESS_NONE,
                .OPI => c.HAL_XSPI_ADDRESS_8_LINES,
            },
            .AddressDTRMode = switch (bus_config.rate) {
                .STR => c.HAL_XSPI_ADDRESS_DTR_DISABLE,
                .DTR => c.HAL_XSPI_ADDRESS_DTR_ENABLE,
            },
            .AddressWidth = c.HAL_XSPI_ADDRESS_32_BITS,
            .Address = address,
            .AlternateBytesMode = c.HAL_XSPI_ALT_BYTES_NONE,
            .DataMode = switch (bus_config.protocol) {
                .SPI => c.HAL_XSPI_DATA_1_LINE,
                .OPI => c.HAL_XSPI_DATA_8_LINES,
            },
            .DataDTRMode = switch (bus_config.rate) {
                .STR => c.HAL_XSPI_DATA_DTR_DISABLE,
                .DTR => c.HAL_XSPI_DATA_DTR_ENABLE,
            },
            .DummyCycles = 0,
            .DataLength = switch (bus_config.rate) {
                .STR => 1,
                .DTR => 2,
            },
            .DQSMode = c.HAL_XSPI_DQS_DISABLE,
        };
        try hal.zig.xspi.command(&self.hxspi, &command);

        // zig does not like &value (it is `*const u8` instead of `[]const u8`)
        const temp = [_]u8{value};
        try hal.zig.xspi.transmit(&self.hxspi, &temp);
    }

    fn read(self: *Self, bus_config: BusConfiguration, address: u32) !u8 {
        try assertSpiDtr(bus_config);

        const command: c.XSPI_RegularCmdTypeDef = .{
            .OperationType = c.HAL_XSPI_OPTYPE_COMMON_CFG,
            .InstructionMode = switch (bus_config.protocol) {
                .SPI => c.HAL_XSPI_INSTRUCTION_1_LINE,
                .OPI => c.HAL_XSPI_INSTRUCTION_8_LINES,
            },
            .InstructionDTRMode = switch (bus_config.rate) {
                .STR => c.HAL_XSPI_INSTRUCTION_DTR_DISABLE,
                .DTR => c.HAL_XSPI_INSTRUCTION_DTR_ENABLE,
            },
            .InstructionWidth = switch (bus_config.protocol) {
                .SPI => c.HAL_XSPI_INSTRUCTION_8_BITS,
                .OPI => c.HAL_XSPI_INSTRUCTION_16_BITS,
            },
            .Instruction = switch (bus_config.protocol) {
                .SPI => Commands.SPI.Register.READ_CFG_REG2,
                .OPI => Commands.OPI.Register.READ_CFG_REG2,
            },
            .AddressMode = switch (bus_config.protocol) {
                .SPI => c.HAL_XSPI_ADDRESS_1_LINE,
                .OPI => c.HAL_XSPI_ADDRESS_8_LINES,
            },
            .AddressDTRMode = switch (bus_config.rate) {
                .STR => c.HAL_XSPI_ADDRESS_DTR_DISABLE,
                .DTR => c.HAL_XSPI_ADDRESS_DTR_ENABLE,
            },
            .AddressWidth = c.HAL_XSPI_ADDRESS_32_BITS,
            .Address = address,
            .AlternateBytesMode = c.HAL_XSPI_ALT_BYTES_NONE,
            .DataMode = switch (bus_config.protocol) {
                .SPI => c.HAL_XSPI_DATA_1_LINE,
                .OPI => c.HAL_XSPI_DATA_8_LINES,
            },
            .DataDTRMode = switch (bus_config.rate) {
                .STR => c.HAL_XSPI_DATA_DTR_DISABLE,
                .DTR => c.HAL_XSPI_DATA_DTR_ENABLE,
            },
            .DummyCycles = switch (bus_config.protocol) {
                .SPI => 0,
                .OPI => switch (bus_config.rate) {
                    .STR => Config.REG_OCTAL,
                    .DTR => Config.REG_OCTAL_DTR,
                },
            },
            .DataLength = switch (bus_config.rate) {
                .STR => 1,
                .DTR => 2,
            },
            .DQSMode = switch (bus_config.rate) {
                .STR => c.HAL_XSPI_DQS_DISABLE,
                .DTR => c.HAL_XSPI_DQS_ENABLE,
            },
        };
        try hal.zig.xspi.command(&self.hxspi, &command);

        var value = [_]u8{ 0, 0 };
        try hal.zig.xspi.receive(&self.hxspi, &value);

        return value[0];
    }
};

const Opi = struct {
    fn enter(self: *Self, rate: Rate) !void {
        try self.writeEnable(self.bus_config);

        const cycles = constants.DUMMY_CYCLES[(Config.READ_OCTAL / 2) - 3];
        try Cfg2.write(
            self,
            self.bus_config,
            Registers.CR2.REG3.ADDR,
            cycles,
        );

        try self.writeEnable(self.bus_config);

        try Cfg2.write(
            self,
            self.bus_config,
            Registers.CR2.REG1.ADDR,
            switch (rate) {
                .STR => Registers.CR2.REG1.SOPI,
                .DTR => Registers.CR2.REG1.DOPI,
            },
        );

        hal.zig.timer.sleep(.{ .milliseconds = constants.WRITE_REG_MAX_TIME });

        if (rate == .DTR) {
            self.hxspi.Init.DelayHoldQuarterCycle = c.HAL_XSPI_DHQC_ENABLE;
            try hal.zig.xspi.init(&self.hxspi);
        }

        try self.pollReady(.{
            .protocol = .OPI,
            .rate = rate,
        });

        const value = try Cfg2.read(
            self,
            .{
                .protocol = .OPI,
                .rate = rate,
            },
            Registers.CR2.REG1.ADDR,
        );
        switch (rate) {
            .STR => if (value != Registers.CR2.REG1.SOPI) {
                return error.DidNotEnterSOPI;
            },
            .DTR => if (value != Registers.CR2.REG1.DOPI) {
                return error.DidNotEnterDOPI;
            },
        }
    }

    fn exit(self: *Self) !void {
        try self.writeEnable(self.bus_config);

        try Cfg2.write(self, self.bus_config, Registers.CR2.REG1.ADDR, 0);

        hal.zig.timer.sleep(.{ .milliseconds = constants.WRITE_REG_MAX_TIME });

        if (self.bus_config.rate == .DTR) {
            self.hxspi.Init.MemoryType = c.HAL_XSPI_MEMTYPE_MICRON;
            self.hxspi.Init.DelayHoldQuarterCycle = c.HAL_XSPI_DHQC_DISABLE;
            try hal.zig.xspi.init(&self.hxspi);
        }

        try self.pollReady(.{
            .protocol = .SPI,
            .rate = .STR,
        });

        const value = try Cfg2.read(
            self,
            .{
                .protocol = .SPI,
                .rate = .STR,
            },
            Registers.CR2.REG1.ADDR,
        );
        if (value != 0) {
            return error.DidNotExitOPI;
        }
    }
};

const Read = struct {
    fn str(self: *Self, read_address: u32, data: []u8) !void {
        const addr_width: AddressWidth = .FourBytes;

        try assertOpiThreeBytes(self.bus_config.protocol, addr_width);
        try assertDataLength(data);

        const command: c.XSPI_RegularCmdTypeDef = .{
            .OperationType = c.HAL_XSPI_OPTYPE_COMMON_CFG,
            .InstructionMode = switch (self.bus_config.protocol) {
                .SPI => c.HAL_XSPI_INSTRUCTION_1_LINE,
                .OPI => c.HAL_XSPI_INSTRUCTION_8_LINES,
            },
            .InstructionDTRMode = c.HAL_XSPI_INSTRUCTION_DTR_DISABLE,
            .InstructionWidth = switch (self.bus_config.protocol) {
                .SPI => c.HAL_XSPI_INSTRUCTION_8_BITS,
                .OPI => c.HAL_XSPI_INSTRUCTION_16_BITS,
            },
            .Instruction = switch (self.bus_config.protocol) {
                .SPI => switch (addr_width) {
                    .ThreeBytes => Commands.SPI.ThreeBytes.FAST_READ,
                    .FourBytes => Commands.SPI.FourBytes.FAST_READ,
                },
                .OPI => Commands.OPI.Memory.READ,
            },
            .AddressMode = switch (self.bus_config.protocol) {
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
            .DataMode = switch (self.bus_config.protocol) {
                .SPI => c.HAL_XSPI_DATA_1_LINE,
                .OPI => c.HAL_XSPI_DATA_8_LINES,
            },
            .DataDTRMode = c.HAL_XSPI_DATA_DTR_DISABLE,
            .DummyCycles = switch (self.bus_config.protocol) {
                .SPI => Config.READ,
                .OPI => Config.READ_OCTAL,
            },
            .DataLength = data.len,
            .DQSMode = c.HAL_XSPI_DQS_DISABLE,
        };
        try hal.zig.xspi.command(&self.hxspi, &command);

        try hal.zig.xspi.receive(&self.hxspi, data.ptr);
    }

    fn dtr(self: *Self, read_address: u32, data: []u8) !void {
        try assertSpiDtr(self.bus_config);

        const command: c.XSPI_RegularCmdTypeDef = .{
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
            .DummyCycles = Config.READ_OCTAL_DTR,
            .DataLength = data.len,
            .DQSMode = c.HAL_XSPI_DQS_ENABLE,
        };
        try hal.zig.xspi.command(&self.hxspi, &command);

        try hal.zig.xspi.receive(&self.hxspi, data.ptr);
    }

    fn read(self: *Self, read_address: u32, data: []u8) !void {
        switch (self.bus_config.rate) {
            .STR => try str(self, read_address, data),
            .DTR => try dtr(self, read_address, data),
        }

        logger.debug("read: {any}", .{data});
    }
};

const Write = struct {
    fn str(self: *Self, write_address: u32, data: []const u8) !void {
        const addr_width: AddressWidth = .FourBytes;

        try assertOpiThreeBytes(self.bus_config.protocol, addr_width);
        try assertDataLength(data);

        const command: c.XSPI_RegularCmdTypeDef = .{
            .OperationType = c.HAL_XSPI_OPTYPE_COMMON_CFG,
            .InstructionMode = switch (self.bus_config.protocol) {
                .SPI => c.HAL_XSPI_INSTRUCTION_1_LINE,
                .OPI => c.HAL_XSPI_INSTRUCTION_8_LINES,
            },
            .InstructionDTRMode = c.HAL_XSPI_INSTRUCTION_DTR_DISABLE,
            .InstructionWidth = switch (self.bus_config.protocol) {
                .SPI => c.HAL_XSPI_INSTRUCTION_8_BITS,
                .OPI => c.HAL_XSPI_INSTRUCTION_16_BITS,
            },
            .Instruction = switch (self.bus_config.protocol) {
                .SPI => switch (addr_width) {
                    .ThreeBytes => Commands.SPI.ThreeBytes.PAGE_PROG,
                    .FourBytes => Commands.SPI.FourBytes.PAGE_PROG,
                },
                .OPI => Commands.OPI.Memory.PAGE_PROG,
            },
            .AddressMode = switch (self.bus_config.protocol) {
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
            .DataMode = switch (self.bus_config.protocol) {
                .SPI => c.HAL_XSPI_DATA_1_LINE,
                .OPI => c.HAL_XSPI_DATA_8_LINES,
            },
            .DataDTRMode = c.HAL_XSPI_DATA_DTR_DISABLE,
            .DummyCycles = 0,
            .DataLength = data.len,
            .DQSMode = c.HAL_XSPI_DQS_DISABLE,
        };
        try hal.zig.xspi.command(&self.hxspi, &command);

        try hal.zig.xspi.transmit(&self.hxspi, data.ptr);
    }

    /// Write data to the XSPI NOR Flash
    /// len(data) <= PAGE_SIZE
    fn dtr(self: *Self, write_address: u32, data: []const u8) !void {
        try assertSpiDtr(self.bus_config);
        try assertDataLength(data);

        const command: c.XSPI_RegularCmdTypeDef = .{
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
        };
        try hal.zig.xspi.command(&self.hxspi, &command);

        try hal.zig.xspi.transmit(&self.hxspi, data.ptr);
    }

    fn write(self: *Self, write_address: u32, data: []const u8) !void {
        // TODO
        //   - (?) Support buffer.len > PAGE_SIZE
        //   - Check if we will ever need to use .ThreeBytes

        try self.pollReady(self.bus_config);
        logger.debug("Polled", .{});

        try self.writeEnable(self.bus_config);
        logger.debug("Write enabled", .{});

        switch (self.bus_config.rate) {
            .STR => try str(self, write_address, data),
            .DTR => try dtr(self, write_address, data),
        }
        logger.debug("wrote {any}", .{data});

        try self.pollReady(self.bus_config);
    }
};
