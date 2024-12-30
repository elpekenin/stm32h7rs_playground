const fatfs = @import("fatfs");

const fs = @import("../fs.zig");
const Shell = @import("../../cli.zig").Shell;

const Self = @This();

path: []const u8,

pub fn handle(self: *const Self, _: *Shell) !void {
    const path = fs.toFatFsPath(self.path);
    try fatfs.unlink(path);
}
