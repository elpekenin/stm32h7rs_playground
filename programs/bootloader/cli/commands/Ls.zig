const fatfs = @import("fatfs");

const fs = @import("../fs.zig");
const Shell = @import("../../cli.zig").Shell;

const Self = @This();

path: ?[]const u8 = null,

pub fn handle(self: *const Self, shell: *Shell) !void {
    if (self.path) |path| {
        if (!fs.exists(path)) {
            return shell.print("'{s}': No such file or directory", .{path});
        }

        if (fs.isFile(path)) {
            return shell.print("'{s}': Is a file", .{path});
        }
    }

    const path = if (self.path) |path|
        fs.toPath(path)
    else
        try fs.cwd();

    var dir = try fatfs.Dir.open(path);
    defer dir.close();

    while (try dir.next()) |child| {
        const entry = fs.Entry.from(child);
        entry.print(shell);
    }
}

pub const tab = fs.autoComplete;
