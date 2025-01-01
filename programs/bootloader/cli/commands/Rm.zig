const fs = @import("../fs.zig");
const t = @import("../tab.zig");
const Shell = @import("../../cli.zig").Shell;

const Self = @This();

path: []const u8,

pub fn handle(self: *const Self, shell: *Shell) !void {
    if (!fs.exists(self.path)) {
        return shell.print("'{s}': No such file or directory", .{self.path});
    }

    if (fs.isDir(self.path)) {
        return shell.print("'{s}': Is a directory", .{self.path});
    }

    return fs.unlink(self.path);
}

pub const tab = t.path;
