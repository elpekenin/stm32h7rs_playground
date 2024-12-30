//! Utilities for filesystem access

const std = @import("std");

const fatfs = @import("fatfs");

comptime {
    if (fatfs.PathChar != u8) {
        const msg = "Unsupported config";
        @compileError(msg);
    }
}

pub inline fn toFatFsPath(path: []const u8) fatfs.Path {
    const len = 100;
    var buffer: [len:0]fatfs.PathChar = undefined;

    std.debug.assert(path.len < len);

    for (0.., path) |i, char| {
        buffer[i] = char;
    }
    buffer[path.len] = 0;

    return &buffer;
}

pub inline fn cwd() !fatfs.Path {
    var buffer: [200]fatfs.PathChar = undefined;
    return fatfs.getcwd(&buffer);
}
