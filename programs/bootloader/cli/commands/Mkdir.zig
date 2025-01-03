const fs = @import("../fs.zig");
const t = @import("../tab.zig");
const Shell = @import("../../cli.zig").Shell;

const Self = @This();

path: []const u8,

pub fn handle(self: Self, shell: *Shell) !void {
    if (fs.isFile(self.path) or fs.isDir(self.path)) {
        return shell.print("'{s}': Already exists", .{self.path});
    }

    try fs.mkdir(self.path);
}

pub const tab = t.path;
