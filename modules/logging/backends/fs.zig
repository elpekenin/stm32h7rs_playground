//! Logging backend to write data into a filesystem (or many)

// TODO?: Lazy writing, it is somewhat slow, and it is best to write a 200byte message
//        than to write 4x 50byte ones

const std = @import("std");
const config = @import("build_config");
const hal = @import("hal");
const rtt = @import("rtt.zig");
const fatfs = @import("fatfs");
const sd = @import("../fatfs_bindings/sd.zig");

// requires pointer stability
var global_fs: fatfs.FileSystem = undefined;

const FatFSWriteError = anyerror;

fn write(_: void, bytes: []const u8) FatFSWriteError!usize {
    const state = struct {
        const mount: [:0]const u8 = "0:/";

        var _disk = sd.Disk{}; // requires pointer stability

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
        state.mount ++ config.program.name ++ ".log",
        .{
            .mode = .open_append,
            .access = .write_only,
        },
    );
    defer file.close();

    return file.write(bytes);
}

const FatFSWriter = std.io.GenericWriter(void, FatFSWriteError, write);

// Mimic rtt's time prefix
fn get_prefix(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
) []const u8 {
    const level_prefix = comptime "[{}.{:0>6}] " ++ level.asText();
    return comptime level_prefix ++ switch (scope) {
        .default => ": ",
        else => " (" ++ @tagName(scope) ++ "): ",
    };
}

pub fn log(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    if (scope == .fatfs) {
        return;
    }

    const prefix = comptime get_prefix(level, scope);
    const writer = FatFSWriter{ .context = {} };

    // TODO: Decouple logging backends
    const time = rtt.time_getter();
    writer.print(prefix ++ format ++ "\n", .{ time.seconds, time.microseconds } ++ args) catch {};
}
