//! Second-stage bootloader, allowing to jump into STM-DFU,
//! or use UF2

const std = @import("std");
const Type = std.builtin.Type;

const builtin = @import("builtin");

/// root is the real entrypoint (common/start.zig), not the "logical" one (this file)
const root = @import("root");

const config = @import("config");
const defmt = @import("defmt");
const hal = @import("hal");
const mx66 = @import("mx66");
const rtt = @import("rtt");
const ushell = @import("ushell");
const version = @import("version");

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
        .{ .name = "Logger", .buffer_size = 16 * 1024, .mode = .NoBlockSkip },
        .{ .name = "Defmt", .buffer_size = 1024, .mode = .NoBlockSkip },
    },
    .down_channels = &.{
        .{ .name = "Shell", .buffer_size = 1024, .mode = .BlockIfFull },
    },
};
/// as per rtt_config
const rtt_channels = root.rtt_channels;

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

const Commands = union(enum) {
    config: struct {
        const Args = @This();

        type: enum {
            build,
            cycles,
            rtt,
        },

        fn printAttribute(shell: *Shell, container: anytype, comptime name: []const u8) bool {
            const value = @field(container, name);
            const T = @TypeOf(value);

            switch (T) {
                type => return false,
                []const u8 => shell.print("{s}: {s}", .{ name, value }),
                else => shell.print("{s}: {any}", .{ name, value }),
            }

            return true;
        }

        fn printFields(shell: *Shell, container: anytype) void {
            const T = @TypeOf(container);
            const I = @typeInfo(T);
            const fields = I.@"struct".fields;

            inline for (fields[0 .. fields.len - 1]) |field| {
                _ = printAttribute(shell, container, field.name);
                shell.print("\n", .{});
            }
            _ = printAttribute(shell, container, fields[fields.len - 1].name);
        }

        fn printConfig(shell: *Shell) void {
            const I = @typeInfo(config);
            const decls = I.@"struct".decls;

            inline for (decls[0 .. decls.len - 1]) |decl| {
                if (printAttribute(shell, config, decl.name)) {
                    shell.print("\n", .{});
                }
            }
            _ = printAttribute(shell, config, decls[decls.len - 1].name);
        }

        fn printDummy(shell: *Shell) void {
            printFields(shell, dummy_cycles_config);
        }

        fn printRttChannel(shell: *Shell, i: usize, channel: rtt.channel.Config) void {
            shell.print("\n  [{}] {{ .name = \"{s}\", .buffer_size = {}, .mode = {s} }}", .{
                i,
                channel.name,
                channel.buffer_size,
                @tagName(channel.mode),
            });
        }

        fn printRtt(shell: *Shell) void {
            shell.print("up", .{});
            for (0.., rtt_config.up_channels) |i, channel| {
                printRttChannel(shell, i, channel);
            }

            shell.print("\n", .{});

            shell.print("down", .{});
            for (0.., rtt_config.down_channels) |i, channel| {
                printRttChannel(shell, i, channel);
            }
        }

        pub fn handle(args: *const Args, shell: *Shell, _: *ushell.Parser) !void {
            switch (args.type) {
                .build => printConfig(shell),
                .cycles => printDummy(shell),
                .rtt => printRtt(shell),
            }
        }
    },

    led: struct {
        const Args = @This();

        n: u2,
        state: bool,

        pub fn handle(args: *const Args, _: *Shell, _: *ushell.Parser) !void {
            hal.bsp.LEDS[args.n].set(args.state);
        }
    },

    uptime: struct {
        const Args = @This();

        pub fn handle(_: *const Args, shell: *Shell, _: *ushell.Parser) !void {
            const now = hal.zig.timer.now().to_s_ms();
            shell.print("{}.{:0>3}s", .{ now.seconds, now.milliseconds });
        }
    },

    read: struct {
        const Args = @This();

        address: usize,
        bytes: ByteMask = .@"4",

        pub fn handle(args: *const Args, shell: *Shell, _: *ushell.Parser) !void {
            const ptr: *usize = @ptrFromInt(args.address);
            const value = ptr.* & args.bytes.mask();
            shell.print("{d}", .{value});
        }
    },

    reboot: struct {
        const Args = @This();

        fn handle(_: *const Args, _: *Shell, _: *ushell.Parser) !void {
            // This is __NVIC_SystemReset from core_cm7.h, zig was unable to translate
            asm volatile ("dsb 0xF" ::: "memory");
            hal.zig.SCB.AIRCR = (0x5FA << 16) | (hal.zig.SCB.AIRCR & (7 << 8)) | (1 << 2);
            asm volatile ("dsb 0xF" ::: "memory");

            while (true) {}
        }
    },

    sleep: struct {
        const Args = @This();

        ms: u32,

        pub fn handle(args: *const Args, _: *Shell, _: *ushell.Parser) !void {
            hal.zig.timer.sleep(.{
                .milliseconds = args.ms,
            });
        }
    },

    version: struct {
        const Args = @This();

        type: enum {
            zig,
            git,
            build,
            all,
        } = .all,

        pub fn handle(args: *const Args, shell: *Shell, _: *ushell.Parser) !void {
            switch (args.type) {
                .zig => shell.print("{s}", .{builtin.zig_version_string}),
                .git => shell.print("{s}", .{version.commit}),
                .build => shell.print("{s}", .{version.datetime}),
                .all => shell.print("commit {s}, using zig {s} (built {s})", .{ version.commit, builtin.zig_version_string, version.datetime }),
            }
        }
    },

    write: struct {
        const Args = @This();

        address: usize,
        value: usize,
        bytes: ByteMask = .@"4",

        pub fn handle(args: *const Args, _: *Shell, _: *ushell.Parser) !void {
            const ptr: *usize = @ptrFromInt(args.address);
            ptr.* = args.value & args.bytes.mask();
        }
    },

    pub fn handle(self: *Commands, shell: *Shell, parser: *ushell.Parser) !void {
        return switch (self.*) {
            inline else => |child| child.handle(shell, parser),
        };
    }
};

const Shell = ushell.Shell(Commands, .{
    .prompt = "stm32h7s7-dk $ ",
    // bigger history size also needs bigger rtt's output buffer to fit all the text
    .max_history_size = 100,
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
