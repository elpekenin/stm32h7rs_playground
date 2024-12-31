const fs = @import("../fs.zig");
const Shell = @import("../../cli.zig").Shell;

const Self = @This();

path: []const u8 = "/home/elpekenin",

pub fn handle(self: *const Self, shell: *Shell) !void {
    if (!fs.exists(self.path)) {
        return shell.print("'{s}': No such file or directory", .{self.path});
    }

    if (fs.isFile(self.path)) {
        return shell.print("'{s}': Is a file", .{self.path});
    }

    try fs.chdir(self.path);
}

pub fn tab(shell: *Shell) !void {
    return fs.autoComplete(shell, .Directory);
}
