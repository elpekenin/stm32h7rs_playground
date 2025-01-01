//! Utilities for filesystem access

const std = @import("std");

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

pub fn mkdir(slice: []const u8) !void {
    return fatfs.mkdir(toPath(slice));
}

pub fn unlink(slice: []const u8) !void {
    try fatfs.unlink(toPath(slice));
}

pub fn isFile(slice: []const u8) bool {
    var file = fatfs.File.open(toPath(slice), .{
        .access = .read_only,
        .mode = .open_existing,
    }) catch return false;
    defer file.close();

    return true;
}

pub fn isDir(slice: []const u8) bool {
    var dir = fatfs.Dir.open(toPath(slice)) catch return false;
    defer dir.close();

    return true;
}

pub fn exists(slice: []const u8) bool {
    return isFile(slice) or isDir(slice);
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
        const name = self.getName();

        const reset = shell.style(.default);
        const style = switch (self.kind) {
            .Directory => shell.style(.blue),
            .File => reset,
        };

        if (std.mem.containsAtLeast(u8, name, 1, " ")) {
            shell.print("{s}'{s}'{s} ", .{ style, name, reset });
        } else {
            shell.print("{s}{s}{s} ", .{ style, name, reset });
        }
    }
};
