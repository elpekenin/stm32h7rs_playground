//! Second-stage bootloader, allowing to jump into STM-DFU,
//! or use UF2

const std = @import("std");
const Type = std.builtin.Type;

/// root is the real entrypoint (common/start.zig), not the "logical" one (this file)
const root = @import("root");

const defmt = @import("defmt");
const hal = @import("hal");
const mx66 = @import("mx66");
const rtt = @import("rtt");
const sd = @import("sd");

const dfu = @import("dfu.zig");
const cli = @import("cli.zig");
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
fn playground() !noreturn {
    _ = try defmt_logger.writer.write("Testing defmt\n");
    try defmt_logger.err("Potato {d}", .{@as(u8, 'A')});
    _ = try defmt_logger.writer.write("\nFinished\n");

    sd.mount.call();

    var shell = cli.Shell.new(reader, writer);
    shell.loop();

    return error.ShellExit;
}

/// Actual entrypoint/logic of the bootloader
pub fn main() !noreturn {
    // button pressed on boot => STM DFU
    if (dfu.checkJump()) {
        logger.debug("STM-DFU", .{});
        dfu.jumpToBootloader();
    }

    // UF2 bootloader's logic is triggered after:
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
