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
const shell = @import("shell");

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

// -- Playground start --
const Shell = shell.Wrapper(struct {
    const Self = @This();
    const prompt = "stm32h7s7-dk $ ";

    const sorted_commands = blk: {
        const commands = @typeInfo(Commands).@"struct".decls;

        var sorted: [commands.len]Type.Declaration = undefined;
        @memcpy(&sorted, commands);
        std.sort.insertion(Type.Declaration, &sorted, {}, compareDeclarations);

        var names: [commands.len][]const u8 = undefined;
        for (sorted, 0..) |command, i| {
            names[i] = command.name;
        }

        break :blk names;
    };

    reader: std.io.AnyReader,
    writer: std.io.AnyWriter,
    stop_running: bool = false,

    fn print(self: *const Self, comptime fmt: []const u8, args: anytype) void {
        std.fmt.format(self.writer, fmt, args) catch {};
    }

    fn showPrompt(self: *const Self) void {
        self.print("{s}", .{prompt});
    }

    fn showUsage(self: *const Self, usage: []const u8) void {
        self.print("Usage: {s}", .{usage});
    }

    fn assertExhausted(self: *const Self, args: *shell.Args) !void {
        if (args.tokensLeft()) {
            self.print("Too many arguments\n", .{});
            return error.TooManyArgs;
        }
    }

    fn compareStrings(_: void, lhs: []const u8, rhs: []const u8) bool {
        return std.mem.order(u8, lhs, rhs).compare(std.math.CompareOperator.lt);
    }

    fn compareDeclarations(_: void, lhs: Type.Declaration, rhs: Type.Declaration) bool {
        return compareStrings({}, lhs.name, rhs.name);
    }

    pub fn readByte(self: *const Self) !u8 {
        return self.reader.readByte();
    }

    /// Every function in here defines a command.
    /// As they are introspected by @CompilerBuiltins in anotheer file, they must be pub.
    /// To invoke a function named <foo>, you must input <foo [...]> in the "reader" stream.
    pub const Commands = struct {
        pub fn help(self: *const Self, args: *shell.Args) !void {
            try self.assertExhausted(args);

            self.print("Available commands:\n", .{});

            for (sorted_commands) |command| {
                self.print("  * {s}\n", .{command});
            }
        }

        pub fn clear(self: *const Self, args: *shell.Args) !void {
            try self.assertExhausted(args);

            self.print("{s}", .{shell.Escape.Clear});
        }

        pub fn echo(self: *const Self, args: *shell.Args) !void {
            self.print("{s}", .{args.rest()});
        }

        pub fn date(self: *const Self, args: *shell.Args) !void {
            try self.assertExhausted(args);

            const now = hal.zig.timer.now().to_s_ms();
            self.print("{}.{:0>3}s", .{ now.seconds, now.milliseconds });
        }

        pub fn sleep(self: *const Self, args: *shell.Args) !void {
            errdefer self.showUsage("sleep <ms>");

            const duration = try args.required(u32);
            try self.assertExhausted(args);

            hal.zig.timer.sleep(.{
                .milliseconds = duration,
            });
        }

        pub fn led(self: *const Self, args: *shell.Args) !void {
            errdefer self.showUsage("led {0,1,2,3} <bool>");

            // luckily, there are 4 LEDs, thus we can use a u2 and not check bounds :)
            const led_num = try args.required(u2);
            const state = try args.required(bool);
            try self.assertExhausted(args);

            hal.bsp.LEDS[led_num].set(state);
        }

        pub fn reboot(self: *const Self, args: *shell.Args) !void {
            try self.assertExhausted(args);

            // This is __NVIC_SystemReset from core_cm7.h, zig was unable to translate
            asm volatile ("dsb 0xF" ::: "memory");
            hal.zig.SCB.AIRCR = (0x5FA << 16) | (hal.zig.SCB.AIRCR & (7 << 8)) | (1 << 2);
            asm volatile ("dsb 0xF" ::: "memory");

            while (true) {}
        }

        pub fn exit(self: *Self, args: *shell.Args) !void {
            try self.assertExhausted(args);
            self.stop_running = true;
        }
    };

    /// Functions called under special circumstances. They are optional.
    pub const Special = struct {
        /// Fallback when no command matches
        pub fn fallback(self: *const Self, args: *shell.Args) !void {
            const command_name = args.commandName() catch {
                // error -> no command name found -> do not print
                return;
            };

            if (std.mem.eql(u8, command_name, "?")) {
                return Commands.help(self, args);
            }

            self.print("{s}: command not found", .{command_name});
        }
    };
});

fn playground() !noreturn {
    const reader: std.io.AnyReader = rtt_channels.reader(0).any();
    const writer: std.io.AnyWriter = rtt_channels.writer(0).any();

    var terminal = Shell.new(.{
        .reader = reader,
        .writer = writer,
    });

    _ = try writer.write("Testing defmt:\n");
    try defmt_logger.err("Potato {d}", .{@as(u8, 'A')});
    _ = try writer.write("\nFinished\n");

    terminal.inner.showPrompt();
    while (!terminal.inner.stop_running) {
        const line = try terminal.readline();
        terminal.handle(line) catch {};
        terminal.inner.print("\n", .{});
        terminal.inner.showPrompt();
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
