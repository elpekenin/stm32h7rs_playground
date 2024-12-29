const fatfs = @import("fatfs");

const utils = @import("utils.zig");
const Shell = @import("../../../cli.zig").Shell;

const Self = @This();

path: []const u8,

pub fn handle(self: *const Self, _: *Shell) !void {
    const path = utils.toFatFsPath(self.path);
    try fatfs.unlink(path);
}
