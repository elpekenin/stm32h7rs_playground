// TODO: Low-level SD card for private API

const std = @import("std");

const fatfs = @import("fatfs");

const root = @import("root");

const hal = @import("../../common/hal.zig");
const board = @import("../../common/board.zig");
const logging = @import("../logging.zig");
const sd = @import("bindings/sd.zig");

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
var sd_disk: sd.Disk = .{
    .sd = board.SD,
};

const UnionDisk = union(enum) {
    sd: *sd.Disk,
};

// race conditions on their way!!
var buff: [100]u8 = undefined;

const Backend = struct {
    const Self = @This();

    mount: [:0]const u8,
    disk: UnionDisk,

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
    .{ .mount = "0:/", .disk = UnionDisk{ .sd = &sd_disk } },
};

const WriteError = anyerror;

fn write(context: Context, bytes: []const u8) WriteError!usize {
    inline for (BACKENDS, 0..) |backend, i| {
        var interface: fatfs.Disk = switch (backend.disk) {
            .sd => |*disk_ptr| disk_ptr.*.interface,
        };

        fatfs.disks[i] = &interface;

        try global_fs.mount(backend.mount, true);
        defer fatfs.FileSystem.unmount(backend.mount) catch std.debug.panic("Failed to unmount.", .{});

        var file = try fatfs.File.open(backend.full_path(context.path), .{
            .mode = .open_append,
            .access = .write_only,
        });
        defer file.close();

        _ = try file.write(bytes);
    }

    return bytes.len;
}

const Writer = std.io.GenericWriter(Context, WriteError, write);

var ever_failed = false;

pub fn log(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    if (ever_failed) {
        return;
    }

    if (scope == .fatfs) {
        // otherwise we will get a bunch of noise
        // TODO?: Over USB/UART/Something
        return;
    }

    const prefix = comptime logging.prefix(level, scope);
    const context = Context.new(level);
    const writer = Writer{ .context = context };

    writer.print(prefix ++ format ++ "\n", args) catch {
        ever_failed = true;
    };
}
