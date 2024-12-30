const fatfs = @import("fatfs");

const fs = @import("fs.zig");
const Shell = @import("../../cli.zig").Shell;

const Self = @This();

path: []const u8,

pub fn handle(self: *const Self, shell: *Shell) !void {
    const path = fs.toFatFsPath(self.path);

    var file = try fatfs.File.open(path, .{
        .access = .read_only,
        .mode = .open_existing,
    });
    defer file.close();

    var read_buffer: [200]u8 = undefined;
    while (true) {
        const n = try file.read(&read_buffer);
        if (n == 0) return;
        shell.print("{s}", .{read_buffer[0..n]});
    }
}
