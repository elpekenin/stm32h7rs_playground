//! Logging backend to write data into a filesystem (or many)

const std = @import("std");

const fatfs = @import("fatfs");

const root = @import("root");

const hal = @import("../hal.zig");
const logging = @import("../logging.zig");
const sd = @import("../fatfs_bindings/sd.zig");

const Context = struct {
    const Self = @This();

    path: [:0]const u8,

    fn get_full_path(comptime level: std.log.Level) [:0]const u8 {
        return switch (level) {
            .debug, .info => @typeName(root) ++ ".out",
            .warn, .err => @typeName(root) ++ ".err",
        };
    }

    pub fn new(comptime level: std.log.Level) Self {
        return Self{
            .path = Self.get_full_path(level),
        };
    }
};

// requires pointer stability
var global_fs: fatfs.FileSystem = undefined;

// requires pointer stability
var sd_disk = sd.Disk{};

const Backend = struct {
    const Self = @This();

    // race conditions on their way!!
    var buff: [100]u8 = undefined;

    mount: [:0]const u8,
    disk: *fatfs.Disk,

    pub fn full_path(self: Self, file_path: []const u8) [:0]const u8 {
        @memset(&buff, 0);

        @memcpy(buff[0..], self.mount);
        @memcpy(buff[self.mount.len..], file_path);
        buff[self.mount.len + file_path.len] = 0;

        // zig doesnt understand that we added the sentinel ourselves
        // "force" it into liking the function by casting
        return @ptrCast(&buff);
    }
};

const BACKENDS: [1]Backend = .{
    .{ .mount = "0:/", .disk = &sd_disk.interface },
};

const FatFSWriteError = anyerror;

fn fatfs_write(context: Context, bytes: []const u8) FatFSWriteError!usize {
    inline for (BACKENDS, 0..) |backend, i| {
        fatfs.disks[i] = backend.disk;

        try global_fs.mount(backend.mount, true);
        defer fatfs.FileSystem.unmount(backend.mount) catch std.debug.panic("Unmount", .{});

        var file = try fatfs.File.open(backend.full_path(context.path), .{
            .mode = .open_append,
            .access = .write_only,
        });
        defer file.close();

        _ = try file.write(bytes);
    }

    return bytes.len;
}

const FatFSWriter = std.io.GenericWriter(Context, FatFSWriteError, fatfs_write);

pub fn log(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    if (scope == .fatfs) {
        return;
    }

    const prefix = comptime logging.prefix(level, scope);
    const context = Context.new(level);
    const writer = FatFSWriter{ .context = context };

    writer.print(prefix ++ format ++ "\n", args) catch return;
}
