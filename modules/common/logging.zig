//! Logging configuration to be used on both bootloader- and application- level code
//! Thus, broken down into a reusable file under `common/`
//!
//! Note: The root of the project (aka: `app.zig` or `bootloader.zig`) has to import
//! and publicly re-export `std_options`

const std = @import("std");
const config = @import("config");

const hal = @import("hal");
const bsp = hal.bsp;

const LOGGERS = .{ fs_logger, rtt_logger };

fn genericLog(
    writer: anytype,
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const now = hal.zig.timer.now().to_s_ms();

    const level_prefix = comptime "[{}.{:0>3}] " ++ level.asText();
    const prefix = comptime level_prefix ++ switch (scope) {
        .default => ": ",
        else => " (" ++ @tagName(scope) ++ "): ",
    };

    writer.print(prefix ++ format ++ "\r\n", .{ now.seconds, now.milliseconds } ++ args) catch {};
}

/// No-op implementation when a logging backend (fs, rtt, etc) is not enabled
const noop_logger = struct {
    fn log(
        comptime level: std.log.Level,
        comptime scope: @TypeOf(.EnumLiteral),
        comptime format: []const u8,
        args: anytype,
    ) void {
        _ = level;
        _ = scope;
        _ = format;
        _ = args;
    }
};

// TODO?: Lazy writing, it is somewhat slow, and it is best to write a 200byte message
//        than to write 4x 50byte ones
const fs_logger = if (config.logging.filesystem)
    struct {
        const fatfs = @import("fatfs");
        const sd_fatfs = @import("sd_fatfs");

        fn write(_: void, bytes: []const u8) anyerror!usize {
            if (!sd_fatfs.cardPresent()) {
                return error.FatFSWriteError;
            }

            try sd_fatfs.mount();

            var file = try fatfs.File.open(
                sd_fatfs.mountpoint ++ config.program ++ ".log",
                .{
                    .mode = .open_append,
                    .access = .write_only,
                },
            );
            defer file.close();

            return file.write(bytes);
        }

        const writer: std.io.GenericWriter(void, anyerror, write) = .{
            .context = {},
        };

        fn log(
            comptime level: std.log.Level,
            comptime scope: @TypeOf(.EnumLiteral),
            comptime format: []const u8,
            args: anytype,
        ) void {
            if (scope == .fatfs) {
                return;
            }

            genericLog(writer, level, scope, format, args);
        }
    }
else
    noop_logger;

const rtt_logger = if (config.logging.rtt)
    struct {
        const rtt = @import("rtt");
        const start = @import("start.zig");

        fn log(
            comptime level: std.log.Level,
            comptime scope: @TypeOf(.EnumLiteral),
            comptime format: []const u8,
            args: anytype,
        ) void {
            const writer = start.rtt_channels.writer(0);
            genericLog(writer, level, scope, format, args);
        }
    }
else
    noop_logger;

/// Function exposed to be used by zig's options
pub fn logFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    inline for (LOGGERS) |logger| {
        logger.log(level, scope, format, args);
    }
}

/// Name that STM HAL expects to find
export fn assert_failed(file: [*:0]const u8, line: u32) void {
    std.log.err("assert failed {s}:{}", .{ file, line });
}
