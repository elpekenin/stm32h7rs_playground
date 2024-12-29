const fatfs = @import("fatfs");

const utils = @import("utils.zig");
const Shell = @import("../../../cli.zig").Shell;

const Self = @This();

path: ?[]const u8 = null,

pub fn handle(self: *const Self, shell: *Shell) !void {
    const path = if (self.path) |path|
        utils.toFatFsPath(path)
    else
        try utils.cwd();

    var dir = try fatfs.Dir.open(path);
    defer dir.close();

    while (try dir.next()) |child| {
        const name = child.name();

        switch (child.kind) {
            .File => shell.print("{s} ", .{name}),
            .Directory => shell.print("{s}/ ", .{name}),
        }
    }
}
