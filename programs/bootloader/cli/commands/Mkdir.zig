const fs = @import("../fs.zig");
const Shell = @import("../../cli.zig").Shell;

const Self = @This();

path: []const u8,

pub fn handle(self: *const Self, shell: *Shell) !void {
    if (fs.exists(self.path)) {
        return shell.print("'{s}': Already exists", .{self.path});
    }

    try fs.mkdir(self.path);
}
