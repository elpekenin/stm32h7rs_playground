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

    return fs.unlink(self.path);
}

pub fn tab(shell: *Shell, tokens: []const []const u8) !void {
    return t.path(shell, tokens, 1);
}
