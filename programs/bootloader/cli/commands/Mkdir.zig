const std = @import("std");

const ushell = @import("ushell");

const fs = @import("../fs.zig");
const t = @import("../tab.zig");
const Shell = @import("../../cli.zig").Shell;

const Self = @This();

pub const meta: ushell.Meta = .{
    .usage =
    \\usage: mkdir <folder> [--parents,--no-parents]
    \\
    \\create a directory (if it does not exist already)
    \\
    \\
    \\options:
    \\  --parents       no error if existing and make parent directories as needed
    \\  --no-parents    error if existing, does not make parents (default behavior)
    ,
};

path: []const u8,
parents: ushell.OptionalFlag,

pub fn handle(self: ushell.Args(Self), shell: *Shell) !void {
    const parents = self.parents orelse false;

    if (fs.isFile(self.path) or fs.isDir(self.path)) {
        if (parents) return;
        return shell.print("'{s}': Already exists", .{self.path});
    }

    try fs.mkdir(self.path, parents);
}

pub fn tab(shell: *Shell, tokens: []const []const u8) !void {
    return t.path(shell, tokens, 1);
}
