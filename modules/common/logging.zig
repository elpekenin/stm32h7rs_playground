//! Logging configuration to be used on both bootloader- and application- level code
//! Thus, broken down into a reusable file under `common/`
//!
//! Note: The root of the project (aka: `app.zig` or `bootloader.zig`) has to import
//! and publicly re-export `std_options`

const std = @import("std");
const build_config = @import("build_config");

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
const fs_logger = if (build_config.logging.filesystem)
    struct {
        const fatfs = @import("fatfs");

        // FatFs's generic API implementation
        const Disk = struct {
            const Self = @This();

            const sector_size = 512;

            interface: fatfs.Disk = .{
                .getStatusFn = Self.getStatus,
                .initializeFn = Self.initialize,
                .readFn = Self.read,
                .writeFn = Self.write,
                .ioctlFn = Self.ioctl,
            },

            fn getStatus(_: *fatfs.Disk) fatfs.Disk.Status {
                return fatfs.Disk.Status{
                    .initialized = bsp.sd.?.initialized(),
                    .disk_present = bsp.sd.?.connected(),
                    .write_protected = false,
                };
            }

            fn initialize(_: *fatfs.Disk) fatfs.Disk.Error!fatfs.Disk.Status {
                if (bsp.sd == null) {
                    return error.DiskNotReady;
                }

                return fatfs.Disk.Status{
                    .initialized = bsp.sd.?.initialized(),
                    .disk_present = bsp.sd.?.connected(),
                    .write_protected = false,
                };
            }

            fn read(_: *fatfs.Disk, buff: [*]u8, sector: fatfs.LBA, count: c_uint) fatfs.Disk.Error!void {
                bsp.sd.?.read(buff, sector, count) catch return error.DiskNotReady;
            }

            fn write(_: *fatfs.Disk, buff: [*]const u8, sector: fatfs.LBA, count: c_uint) fatfs.Disk.Error!void {
                bsp.sd.?.write(buff, sector, count) catch return error.DiskNotReady;
            }

            fn ioctl(interface: *fatfs.Disk, cmd: fatfs.IoCtl, buff: [*]u8) fatfs.Disk.Error!void {
                if (interface.getStatus().initialized != true) {
                    return error.DiskNotReady;
                }

                const info = bsp.sd.?.info() catch return error.DiskNotReady;

                switch (cmd) {
                    .sync => return,
                    .get_sector_count => {
                        const sectors = info.LogBlockNbr;
                        const ptr: [*]u32 = @alignCast(@ptrCast(buff));
                        ptr[0] = sectors;
                    },
                    .get_sector_size => {
                        const size = info.LogBlockSize;
                        const ptr: [*]u16 = @alignCast(@ptrCast(buff));
                        ptr[0] = @intCast(size);
                    },
                    .get_block_size => {
                        const size = info.LogBlockSize / Disk.sector_size;
                        const ptr: [*]u16 = @alignCast(@ptrCast(buff));
                        ptr[0] = @intCast(size);
                    },

                    else => return error.InvalidParameter,
                }
            }
        };

        /// requires pointer stability
        var global_fs: fatfs.FileSystem = undefined;

        fn write(_: void, bytes: []const u8) anyerror!usize {
            const state = struct {
                const mount: [:0]const u8 = "0:/";

                var _disk = Disk{}; // requires pointer stability

                var init = false;

                var disk: *fatfs.Disk = &_disk.interface;
            };

            if (!state.init) {
                fatfs.disks[0] = state.disk;
                try global_fs.mount(state.mount, true);
                // defer fatfs.FileSystem.unmount(backend.mount) catch std.debug.panic("Unmount", .{});
                state.init = true;
            }

            if (!state.disk.getStatusFn(state.disk).disk_present) {
                return error.FatFSWriteError;
            }

            var file = try fatfs.File.open(
                state.mount ++ build_config.program ++ ".log",
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

const rtt_logger = if (build_config.logging.rtt)
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
