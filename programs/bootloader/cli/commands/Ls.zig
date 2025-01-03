const fatfs = @import("fatfs");

const fs = @import("../fs.zig");
const t = @import("../tab.zig");
const Shell = @import("../../cli.zig").Shell;

const Self = @This();

path: ?[]const u8 = null,

pub fn handle(self: Self, shell: *Shell) !void {
    if (self.path) |path| {
        if (fs.isFile(path)) {
            return shell.print("'{s}': Is a file", .{path});
        }

        if (!fs.isDir(path)) {
            return shell.print("'{s}': No such directory", .{path});
        }
    }

    const path = try fs.pathOrCwd(self.path);

    var dir = try fatfs.Dir.open(path);
    defer dir.close();

    while (try dir.next()) |child| {
        const entry = fs.Entry.from(child);
        entry.print(shell);
    }
}

pub const tab = t.path;
