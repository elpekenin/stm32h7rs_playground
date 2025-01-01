const std = @import("std");

const fs = @import("../fs.zig");
const Shell = @import("../../cli.zig").Shell;

const Self = @This();

path: []const u8,

pub fn handle(self: *const Self, shell: *Shell) !void {
    if (!fs.exists(self.path)) {
        shell.print("'{s}': No such file or directory", .{self.path});
        return;
    }

    if (fs.isFile(self.path)) {
        shell.print("'{s}': Is a file", .{self.path});
    }

    try fs.unlink(self.path);
}

pub const tab = fs.autoComplete;
