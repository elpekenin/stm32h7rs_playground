//! Second-stage bootloader, allowing to jump into STM-DFU,
//! or use UF2

const std = @import("std");
const logger = std.log.scoped(.bootloader);

/// root is the real entrypoint (common/start.zig), not the "logical" one (this file)
const start = @import("root");

const defmt = @import("defmt");
const hal = @import("hal");
const mx66 = @import("mx66");
const rtt = @import("rtt");
const shell = @import("shell");

const dfu = @import("dfu.zig");
const uf2 = @import("uf2.zig");

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
const LedAction = enum {
    const Self = @This();

    on,
    off,
    toggle,

    fn apply(self: *const Self, led_num: u2) void {
        const led = hal.bsp.LEDS[led_num];

        switch (self.*) {
            .on => led.set(true),
            .off => led.set(false),
            .toggle => led.toggle(),
        }
    }
};

const Shell = shell.Wrapper(struct {
    const Self = @This();
    const prompt = "stm32h7s7-dk $ ";

    reader: std.io.AnyReader,
    writer: std.io.AnyWriter,

    fn print(self: *const Self, comptime fmt: []const u8, args: anytype) !void {
        return std.fmt.format(self.writer, fmt, args);
    }

    fn showPrompt(self: *const Self) !void {
        try self.print("{s}", .{prompt});
    }

    pub fn readByte(self: *const Self) !u8 {
        return self.reader.readByte();
    }

    /// Every function in here defines a command.
    /// As they are introspected by @CompilerBuiltins in anotheer file, they must be pub.
    /// To invoke a function named <foo>, you must input <foo [...]> in the "reader" stream.
    pub const Commands = struct {
        pub fn date(self: *const Self, _: *shell.Args) !void {
            const now = hal.zig.timer.now().to_s_ms();
            try self.print("{}.{:0>3}s", .{ now.seconds, now.milliseconds });
        }

        pub fn echo(self: *const Self, args: *shell.Args) !void {
            try self.print("{s}", .{args.rest()});
        }

        pub fn led(self: *const Self, args: *shell.Args) !void {
            const usage = "Usage: led {0,1,2,3} {on,off,toggle}";

            // luckily, there are 4 LEDs, thus we can use a u2 and not check bounds :)
            const led_num = args.next(u2) catch |err| {
                self.print("{s}", .{usage}) catch {};
                return err;
            };

            const action = args.next(LedAction) catch |err| {
                self.print("{s}", .{usage}) catch {};
                return err;
            };

            action.apply(led_num);
            try self.print("Done!", .{});
        }

        pub fn ls(self: *const Self, _: *shell.Args) !void {
            try self.print("bar.zig  foo.zig", .{});
        }

        pub fn pwd(self: *const Self, _: *shell.Args) !void {
            try self.print("/home/elpekenin", .{});
        }

        pub fn reboot(self: *const Self, _: *shell.Args) !void {
            // Usually not seen (lost because RTT block is re-initialized on boot?)
            try self.print("Restarting...\n\n", .{});

            // This is __NVIC_SystemReset from core_cm7.h, zig was unable to translate
            asm volatile ("dsb 0xF" ::: "memory");
            hal.zig.SCB.AIRCR = (0x5FA << 16) | (hal.zig.SCB.AIRCR & (7 << 8)) | (1 << 2);
            asm volatile ("dsb 0xF" ::: "memory");

            while (true) {}
        }

        pub fn whoami(self: *const Self, _: *shell.Args) !void {
            try self.print("elpekenin", .{});
        }
    };

    /// Functions called under special circumstances. They are optional.
    pub const Special = struct {
        pub fn tab(_: *const Self, _: *shell.Args) !void {}

        /// Fallback when no command matches
        pub fn fallback(self: *const Self, args: *shell.Args) !void {
            const command_name = args.commandName();

            // special case: nothing written -> noop + don't print
            if (command_name.len == 0) return;

            try self.print("{s}: command not found", .{command_name});
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

    try terminal.inner.showPrompt();
    while (true) {
        const line = try terminal.readline();
        terminal.handle(line);
        try terminal.inner.print("\n", .{});
        try terminal.inner.showPrompt();
    }
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
