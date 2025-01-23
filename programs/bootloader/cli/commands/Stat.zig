const zfat = @import("zfat");

const fs = @import("../fs.zig");
const t = @import("../tab.zig");
const Shell = @import("../../cli.zig").Shell;

const Self = @This();

path: []const u8,

pub fn handle(self: Self, shell: *Shell) !void {
    if (!fs.isFile(self.path) and !fs.isDir(self.path)) {
        return shell.print("'{s}': No such file or directory", .{self.path});
    }

    const stat = try zfat.stat(fs.toPath(self.path));
    shell.print("{any}", .{stat});
}

pub fn tab(shell: *Shell, tokens: []const []const u8) !void {
    return t.path(shell, tokens, 1);
}
