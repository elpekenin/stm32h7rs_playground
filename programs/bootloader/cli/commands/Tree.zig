const std = @import("std");

const zfat = @import("zfat");

const fs = @import("../fs.zig");
const t = @import("../tab.zig");
const Shell = @import("../../cli.zig").Shell;

const Self = @This();

path: ?[]const u8 = null,

const Stats = struct {
    dirs: usize,
    files: usize,
};

fn iter(shell: *Shell, path: zfat.Path, level: usize, stats: *Stats) !void {
    // so that `Dir.open(child)` works without concatenating slices or the like
    try zfat.chdir(path);

    var dir = try zfat.Dir.open(fs.toPath("")); // we just cd'ed into target
    defer dir.close();

    while (try dir.next()) |child| {
        const name = child.name();

        shell.print("\n", .{});
        for (0..level) |_| shell.print("  ", .{}); // indent
        fs.print(shell, child.kind, name);

        switch (child.kind) {
            .Directory => {
                stats.dirs += 1;
                try iter(shell, fs.toPath(name), level + 1, stats);
                try fs.chdir(".."); // get back to `path`
            },
            .File => stats.files += 1,
        }
    }
}

pub fn handle(self: Self, shell: *Shell) !void {
    if (self.path) |path| {
        if (fs.isFile(path)) {
            return shell.print("'{s}': Is a file", .{path});
        }

        if (!fs.isDir(path)) {
            return shell.print("'{s}': No such directory", .{path});
        }
    }

    // iter() will chdir to use relative paths
    // but we want to end in the same location we ran the command from
    const cwd = try fs.cwd();
    defer zfat.chdir(cwd) catch {
        shell.print("couldn't go back to ", .{});
        fs.print(shell, .Directory, std.mem.sliceTo(cwd, 0));
    };

    const path = try fs.pathOrCwd(self.path);
    fs.print(shell, .Directory, std.mem.sliceTo(path, 0));

    var stats = Stats{
        .dirs = 0,
        .files = 0,
    };
    try iter(shell, path, 1, &stats);

    shell.print("\n\n{d} {s}, {d} {s}", .{
        stats.dirs,
        if (stats.dirs == 1) "directory" else "directories",
        stats.files,
        if (stats.files == 1) "file" else "files",
    });
}

pub fn tab(shell: *Shell, tokens: []const []const u8) !void {
    return t.path(shell, tokens, 1);
}
