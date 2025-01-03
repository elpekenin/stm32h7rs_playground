//! Utilities for filesystem access

const std = @import("std");

const fs = @This();
const fatfs = @import("fatfs");

const Shell = @import("../cli.zig").Shell;

comptime {
    if (fatfs.PathChar != u8) {
        const msg = "Unsupported config";
        @compileError(msg);
    }
}

pub inline fn toPath(slice: []const u8) fatfs.Path {
    const len = 100;
    var path: [len:0]fatfs.PathChar = undefined;

    std.debug.assert(slice.len < len);

    for (0.., slice) |i, char| {
        path[i] = char;
    }
    path[slice.len] = 0;

    return &path;
}

pub fn chdir(slice: []const u8) !void {
    try fatfs.chdir(toPath(slice));
}

pub inline fn cwd() !fatfs.Path {
    var path: [200]fatfs.PathChar = undefined;
    return fatfs.getcwd(&path);
}

pub inline fn pathOrCwd(maybe_path: ?[]const u8) !fatfs.Path {
    if (maybe_path) |path| {
        return fs.toPath(path);
    }

    return cwd();
}

pub fn mkdir(slice: []const u8, parents: bool) !void {
    if (parents) {
        for (0.., slice) |n, char| {
            if (char != '/') continue;

            const path = toPath(slice[0..n]);

            if (isDir(path)) continue;
            if (isFile(path)) return error.IsFile;

            try fatfs.mkdir(path);
        }
    }

    return fatfs.mkdir(toPath(slice));
}

pub fn unlink(slice: []const u8) !void {
    try fatfs.unlink(toPath(slice));
}

pub fn isFile(slice: []const u8) bool {
    const stat = fatfs.stat(toPath(slice)) catch return false;
    return stat.kind == .File;
}

pub fn isDir(slice: []const u8) bool {
    const stat = fatfs.stat(toPath(slice)) catch return false;
    return stat.kind == .Directory;
}

pub fn print(shell: *Shell, kind: fatfs.Kind, name: []const u8) void {
    const reset = shell.style(.{ .foreground = .default });

    const style = switch (kind) {
        .Directory => shell.style(.{ .foreground = .blue }),
        .File => reset,
    };

    if (std.mem.containsAtLeast(u8, name, 1, " ")) {
        shell.print("{s}'{s}'{s} ", .{ style, name, reset });
    } else {
        shell.print("{s}{s}{s} ", .{ style, name, reset });
    }
}

pub const Entry = struct {
    const Self = @This();

    // extra space for '/' and sentinel
    buffer: [fatfs.FileInfo.max_name_len + 2]u8,
    kind: fatfs.Kind,

    pub fn from(info: fatfs.FileInfo) Self {
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
