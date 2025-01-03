const std = @import("std");

const fs = @import("../fs.zig");
const t = @import("../tab.zig");
const Shell = @import("../../cli.zig").Shell;

const Self = @This();

path: []const u8,

pub fn handle(self: Self, shell: *Shell) !void {
    if (fs.isFile(self.path)) {
        return shell.print("'{s}': Is a file", .{self.path});
    }

    if (!fs.isDir(self.path)) {
        return shell.print("'{s}': No such directory", .{self.path});
    }

    try fs.unlink(self.path);
}

pub const tab = t.path;
