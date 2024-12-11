//! UF2 logic to receive, write and execute user-land code
//! over USB

const std = @import("std");
const logger = std.log.scoped(.uf2);

const hal = @import("hal");
const jump = @import("jump.zig");

const mx66 = @import("mx66");

const shell = @import("shell.zig");

const main = @import("main.zig");

const defmt_logger = main.defmt_logger;
const rtt_channels = main.rtt_channels;

/// Green LED
const INDICATOR = hal.bsp.LEDS[0];

pub const FLASH_BASE = 0x70000000;
pub const FLASH_SIZE = 0x08000000;

const Flag = struct {
    const MAGIC = 0xBEBECAFE;

    var value: u32 linksection(".preserve.0") = undefined;

    fn set() void {
        value = MAGIC;
    }

    fn clear() void {
        value = 0;
    }

    fn chance() void {
        set();
        hal.zig.timer.sleep(.{ .milliseconds = 500 });
        clear();
    }

    fn check() bool {
        return value == MAGIC;
    }
};

fn flashTest() !i32 {
    var flash = try mx66.new(.{
        .protocol = .OPI,
        .rate = .DTR,
    });

    const SIZE = 10;

    const write_buf = [_]u8{0xAA} ** SIZE;
    try flash.write(0, &write_buf);

    var read_buf = [_]u8{0xFF} ** SIZE;
    try flash.read(0, &read_buf);

    return 0;
}

pub const checkJump = Flag.check;
pub const doubleResetChance = Flag.chance;

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
        pub fn date(self: *const Self, _: *shell.ArgIterator) !void {
            const now = hal.zig.timer.now().to_s_ms();
            try self.print("{}.{:0>3}s", .{ now.seconds, now.milliseconds });
        }

        pub fn echo(self: *const Self, args: *shell.ArgIterator) !void {
            try self.print("{s}", .{args.rest()});
        }

        pub fn led(self: *const Self, args: *shell.ArgIterator) !void {
            // luckily, there are 4 LEDs, thus we can use a u2 and not check bounds :)
            const led_num = shell.parser.Int(args, u2, .{}) catch |err| {
                const options = "in range [0-3]";

                switch (err) {
                    error.MissingArg => try self.print("Must provide a led ({s}) to be controlled", .{options}),
                    error.InvalidArg => try self.print("Led must be {s}", .{options}),
                }

                return err;
            };

            const action = shell.parser.Enum(args, LedAction) catch |err| {
                const options = "one of: {on, off, toggle}";

                switch (err) {
                    error.MissingArg => try self.print("Must provide an operation to perform, {s}", .{options}),
                    error.InvalidArg => try self.print("Operation must be {s}", .{options}),
                }

                return err;
            };

            action.apply(led_num);
            try self.print("Led {d}: {s}", .{ led_num, @tagName(action) });
        }

        pub fn ls(self: *const Self, _: *shell.ArgIterator) !void {
            try self.print("bar.zig  foo.zig", .{});
        }

        pub fn pwd(self: *const Self, _: *shell.ArgIterator) !void {
            try self.print("/home/elpekenin", .{});
        }

        pub fn reboot(self: *const Self, _: *shell.ArgIterator) !void {
            // Usually not seen (lost because RTT block is re-initialized on boot?)
            try self.print("Restarting...\n\n", .{});

            // This is __NVIC_SystemReset from core_cm7.h, zig was unable to translate
            asm volatile ("dsb 0xF" ::: "memory");
            hal.zig.SCB.AIRCR = (0x5FA << 16) | (hal.zig.SCB.AIRCR & (7 << 8)) | (1 << 2);
            asm volatile ("dsb 0xF" ::: "memory");

            while (true) {}
        }

        pub fn whoami(self: *const Self, _: *shell.ArgIterator) !void {
            try self.print("elpekenin", .{});
        }
    };

    /// Functions called under special circumstances. They are optional.
    pub const Special = struct {
        pub fn tab(self: *const Self, line: []const u8) !void {
            _ = self;
            _ = line;
        }

        /// Fallback when no command matches
        pub fn fallback(self: *const Self, line: []const u8) !void {
            // special case: nothing written -> noop + don't print
            if (line.len == 0) return;

            try self.print("{s}: command not found", .{line});
        }
    };
});

pub fn jumpToUserCode() !noreturn {
    // fails, for now.
    _ = flashTest() catch {};

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

    jump.to(FLASH_BASE);
}

pub fn loop() noreturn {
    Flag.clear();

    INDICATOR.set(true);
    hal.zig.timer.sleep(.{ .milliseconds = 500 });
    INDICATOR.set(false);

    while (true) {
        // expose USB MSC
        // wait for input, break on that scenario
    }

    // check family id
    // ... and start address
    // if correct, write it to flash

    jumpToUserCode();
}
