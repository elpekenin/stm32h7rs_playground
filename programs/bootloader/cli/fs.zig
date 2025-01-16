//! Utilities for filesystem access

const std = @import("std");

const fs = @This();
const zfat = @import("zfat");

const Shell = @import("../cli.zig").Shell;

comptime {
    if (zfat.PathChar != u8) {
        const msg = "Unsupported config";
        @compileError(msg);
    }
}

/// Given "foo/bar/baz" input, calling `.next()` will return
/// foo
/// foo/bar
/// foo/bar/baz
/// null
const PathIterator = struct {
    const Self = @This();

    tokenizer: std.mem.SplitIterator(u8, .scalar),

    fn new(slice: []const u8) Self {
        return .{
            .tokenizer = std.mem.splitScalar(u8, slice, '/'),
        };
    }

    fn next(self: *Self) ?[]const u8 {
        _ = self.tokenizer.next() orelse return null;
        const end = self.tokenizer.index orelse unreachable;
        return self.tokenizer.buffer[0..end];
    }
};

pub inline fn toPath(slice: []const u8) zfat.Path {
    const len = 100;
    var path: [len:0]zfat.PathChar = undefined;

    std.debug.assert(slice.len < len);

    for (0.., slice) |i, char| {
        path[i] = char;
    }
    path[slice.len] = 0;

    return &path;
}

pub fn chdir(slice: []const u8) !void {
    try zfat.chdir(toPath(slice));
}

pub inline fn cwd() !zfat.Path {
    var path: [200]zfat.PathChar = undefined;
    return zfat.getcwd(&path);
}

pub inline fn pathOrCwd(maybe_path: ?[]const u8) !zfat.Path {
    if (maybe_path) |path| {
        return fs.toPath(path);
    }

    return cwd();
}

pub fn mkdir(slice: []const u8, parents: bool) !void {
    if (parents) {
        var iterator: PathIterator = .new(slice);
        while (iterator.next()) |path| {
            if (isDir(path)) continue;
            if (isFile(path)) return error.IsFile;
            try zfat.mkdir(toPath(path));
        }
    }

    return zfat.mkdir(toPath(slice));
}

pub fn unlink(slice: []const u8) !void {
    try zfat.unlink(toPath(slice));
}

pub fn isFile(slice: []const u8) bool {
    const stat = zfat.stat(toPath(slice)) catch return false;
    return stat.kind == .File;
}

pub fn isDir(slice: []const u8) bool {
    const stat = zfat.stat(toPath(slice)) catch return false;
    return stat.kind == .Directory;
}

pub fn print(shell: *Shell, kind: zfat.Kind, name: []const u8) void {
    const style = switch (kind) {
        .Directory => shell.style(.blue),
        .File => shell.style(.default),
    };
    const reset = shell.style(.default);

    if (std.mem.containsAtLeast(u8, name, 1, " ")) {
        shell.print("{s}'{s}'{s} ", .{ style, name, reset });
    } else {
        shell.print("{s}{s}{s} ", .{ style, name, reset });
    }
}

pub const Entry = struct {
    const Self = @This();

    // extra space for '/' and sentinel
    buffer: [zfat.FileInfo.max_name_len + 2]u8,
    kind: zfat.Kind,

    pub fn from(info: zfat.FileInfo) Self {
        const name = info.name();

        var self = Self{
            .buffer = undefined,
            .kind = info.kind,
        };

        for (0.., name) |i, char| {
            self.buffer[i] = char;
        }

        switch (info.kind) {
            .Directory => {
                self.buffer[name.len] = '/';
                self.buffer[name.len + 1] = 0;
            },
            .File => {
                self.buffer[name.len] = 0;
            },
        }

        return self;
    }

    pub fn getCompletion(self: *const Self) []const u8 {
        return std.mem.sliceTo(&self.buffer, 0);
    }

    pub fn getName(self: *const Self) []const u8 {
        const completion = self.getCompletion();

        return switch (self.kind) {
            .Directory => completion[0 .. completion.len - 1], // without '/'
            .File => completion,
        };
    }

    pub fn print(self: *const Self, shell: *Shell) void {
        fs.print(shell, self.kind, self.getName());
    }
};
