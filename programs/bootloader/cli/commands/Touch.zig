const zfat = @import("zfat");

const fs = @import("../fs.zig");
const t = @import("../tab.zig");
const Shell = @import("../../cli.zig").Shell;

const Self = @This();

path: []const u8,

pub fn handle(self: Self, shell: *Shell) !void {
    if (fs.isDir(self.path) or fs.isFile(self.path)) {
        return shell.print("'{s}': Already exists", .{self.path});
    }

    var file = try zfat.File.open(fs.toPath(self.path), .{
        .mode = .create_new,
    });
    defer file.close();
}

pub fn tab(shell: *Shell, tokens: []const []const u8) !void {
    return t.path(shell, tokens, 1);
}
