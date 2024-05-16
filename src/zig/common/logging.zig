const std = @import("std");

const fatfs = @import("fatfs");

const root = @import("root");
const fs = @import("logging/fs.zig");

const board = @import("../common/board.zig");

const Context = struct { file: struct {
    path: [:0]const u8,
} };

const WriteError = anyerror;

fn write(context: Context, bytes: []const u8) WriteError!usize {
    try fs.log(context.file.path, bytes);
    return bytes.len;
}

const Writer = std.io.GenericWriter(Context, WriteError, write);

pub fn log(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    if (@intFromEnum(level) < @intFromEnum(std.log.Level.info)) {
        // no .debug logging
        return;
    }

    if (scope == .fatfs) {
        // otherwise we will get a bunch of noise
        // TODO?: Over USB/UART/Something
        return;
    }

    const prefix = "[" ++ comptime level.asText() ++ "] (" ++ @tagName(scope) ++ "): ";

    const filename = @typeName(root) ++ switch (level) {
        .debug, .info => ".out",
        .warn, .err => ".err",
    };

    const writer = Writer{ .context = .{ .file = .{ .path = filename } } };

    writer.print(prefix ++ format ++ "\n", args) catch return;
}
