const std = @import("std");

const fs = @import("../fs.zig");
const t = @import("../tab.zig");
const Shell = @import("../../cli.zig").Shell;

const Self = @This();

pub const allow_extra_args = true;

pub const usage =
    \\usage: mkdir <folder> [-p]
    \\
    \\create a directory (if it does not exist already)
    \\
    \\
    \\options:
    \\  -p, --parents    no error if existing, make parent directories as needed
;

path: []const u8,

fn parentsFlagPresent(shell: *Shell) bool {
    const token = shell.parser.next() orelse return false;
    return std.mem.eql(u8, token, "-p") or std.mem.eql(u8, token, "--parents");
}

pub fn handle(self: Self, shell: *Shell) !void {
    const parents = parentsFlagPresent(shell);

    if (fs.isFile(self.path) or fs.isDir(self.path)) {
        if (parents) return;
        return shell.print("'{s}': Already exists", .{self.path});
    }

    try fs.mkdir(self.path, parents);
}

pub const tab = t.path;
