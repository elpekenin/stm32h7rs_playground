const fatfs = @import("fatfs");

const fs = @import("../fs.zig");
const Shell = @import("../../cli.zig").Shell;

const Self = @This();

path: []const u8,

pub fn handle(self: *const Self, shell: *Shell) !void {
    if (fs.exists(self.path)) {
        return shell.print("'{s}': Already exists", .{self.path});
    }

    var file = try fatfs.File.open(fs.toPath(self.path), .{
        .mode = .create_new,
    });
    defer file.close();
}
