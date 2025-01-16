const zfat = @import("zfat");

const fs = @import("../fs.zig");
const t = @import("../tab.zig");
const Shell = @import("../../cli.zig").Shell;

const Self = @This();

path: []const u8,

pub fn handle(self: Self, shell: *Shell) !void {
    if (fs.isDir(self.path)) {
        return shell.print("'{s}': Is a directory", .{self.path});
    }

    if (!fs.isFile(self.path)) {
        return shell.print("'{s}': No such file", .{self.path});
    }

    var file = try zfat.File.open(fs.toPath(self.path), .{
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

pub fn tab(shell: *Shell, tokens: []const []const u8) !void {
    return t.path(shell, tokens, 1);
}
