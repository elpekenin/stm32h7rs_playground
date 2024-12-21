//! Second-stage bootloader, allowing to jump into STM-DFU,
//! or use UF2

const std = @import("std");
const Type = std.builtin.Type;

/// root is the real entrypoint (common/start.zig), not the "logical" one (this file)
const start = @import("root");

const defmt = @import("defmt");
const hal = @import("hal");
const mx66 = @import("mx66");
const rtt = @import("rtt");
const ushell = @import("ushell");

const dfu = @import("dfu.zig");
const uf2 = @import("uf2.zig");

const logger = std.log.scoped(.bootloader);

pub const dummy_cycles_config: mx66.DummyCyclesConfiguration = .{
    .READ = 8,
    .READ_OCTAL = 6,
    .READ_OCTAL_DTR = 6,
    .REG_OCTAL = 4,
    .REG_OCTAL_DTR = 5,
};

/// inform root how to configure the code
pub const rtt_config: rtt.Config = .{
    .up_channels = &.{
        .{ .name = "Logger", .buffer_size = 1024, .mode = .NoBlockSkip },
        .{ .name = "Defmt", .buffer_size = 1024, .mode = .NoBlockSkip },
    },
    .down_channels = &.{
        .{ .name = "Shell", .buffer_size = 1024, .mode = .BlockIfFull },
    },
};
/// as per rtt_config
const rtt_channels = start.rtt_channels;

const defmt_logger: defmt.Logger = .{
    .writer = rtt_channels.writer(1).any(),
};

const reader: std.io.AnyReader = rtt_channels.reader(0).any();
const writer: std.io.AnyWriter = rtt_channels.writer(0).any();

// -- Playground start --
const ByteMask = enum {
    const Self = @This();

    @"1",
    @"2",
    @"4",

    fn mask(self: *const Self) usize {
        return switch (self.*) {
            .@"1" => (1 << (1 * 8)) - 1,
            .@"2" => (1 << (2 * 8)) - 1,
            .@"4" => (1 << (4 * 8)) - 1,
        };
    }
};

fn print(comptime fmt: []const u8, args: anytype) void {
    std.fmt.format(writer, fmt, args) catch {};
}

const Commands = union(enum) {
    echo: struct {
        pub const allow_extra_args = true;

        pub fn handle(_: *const @This(), parser: *ushell.Parser) !void {
            while (parser.next()) |val| {
                print("{s} ", .{val});
            }
        }
    },

    led: struct {
        n: u2,
        state: bool,

        pub fn handle(self: *const @This(), _: *ushell.Parser) !void {
            hal.bsp.LEDS[self.n].set(self.state);
        }
    },

    uptime: struct {
        pub fn handle(_: *const @This(), _: *ushell.Parser) !void {
            const now = hal.zig.timer.now().to_s_ms();
            print("{}.{:0>3}s", .{ now.seconds, now.milliseconds });
        }
    },

    read: struct {
        address: usize,
        bytes: ByteMask = .@"4",

        pub fn handle(self: *const @This(), _: *ushell.Parser) !void {
            const ptr: *usize = @ptrFromInt(self.address);
            const value = ptr.* & self.bytes.mask();
            print("{d}", .{value});
        }
    },

    reboot: struct {
        fn handle(_: *const @This(), _: *ushell.Parser) !void {
            // This is __NVIC_SystemReset from core_cm7.h, zig was unable to translate
            asm volatile ("dsb 0xF" ::: "memory");
            hal.zig.SCB.AIRCR = (0x5FA << 16) | (hal.zig.SCB.AIRCR & (7 << 8)) | (1 << 2);
            asm volatile ("dsb 0xF" ::: "memory");

            while (true) {}
        }
    },

    sleep: struct {
        ms: u32,

        pub fn handle(args: *const @This(), _: *ushell.Parser) !void {
            hal.zig.timer.sleep(.{
                .milliseconds = args.ms,
            });
        }
    },

    write: struct {
        address: usize,
        value: usize,
        bytes: ByteMask = .@"4",

        pub fn handle(self: *const @This(), _: *ushell.Parser) !void {
            const ptr: *usize = @ptrFromInt(self.address);
            ptr.* = self.value & self.bytes.mask();
        }
    },

    pub fn handle(self: *Commands, parser: *ushell.Parser) !void {
        return switch (self.*) {
            inline else => |child| child.handle(parser),
        };
    }
};

const Shell = ushell.Shell(Commands, .{
    .prompt = "stm32h7s7-dk $ ",
});

fn playground() !noreturn {
    _ = try defmt_logger.writer.write("Testing defmt\n");
    try defmt_logger.err("Potato {d}", .{@as(u8, 'A')});
    _ = try defmt_logger.writer.write("\nFinished\n");

    var shell = Shell.new(reader, writer);

    while (!shell.stop_running) {
        shell.showPrompt();

        // do not break loop because of errors
        const line = shell.readline() catch continue;

        shell.handle(line) catch continue;
    }

    return error.ShellExit;
}

/// Actual entrypoint/logic of the bootloader
pub fn main() !noreturn {
    // button pressed on boot => STM DFU
    if (dfu.checkJump()) {
        logger.debug("STM-DFU", .{});
        dfu.jumpToBootloader();
    }

    // UF2 bootloader's logic is triggeren after:
    //   a) quick double reset
    //   b) user-level code setting sentinel + resetting
    if (uf2.checkJump()) {
        logger.debug("UF2 bootloader", .{});
        uf2.loop();
    }

    // give chance for a double reset into bootloader
    uf2.doubleResetChance();

    try playground();

    // jump to user code
    logger.debug("User code", .{});
    try uf2.jumpToUserCode();
}
