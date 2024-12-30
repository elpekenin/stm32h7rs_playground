const std = @import("std");

const fatfs = @import("fatfs");
const ushell = @import("ushell");

const fs = @import("fs.zig");
const Shell = @import("../../cli.zig").Shell;

const Self = @This();

pub const allow_extra_args = true;

fn getPath(parser: *ushell.Parser) ![]const u8 {
    const path = try parser.required([]const u8);
    try parser.assertExhausted();
    return path;
}

// get parser back to initial state (only command_name has been consumed)
fn initialState(parser: *ushell.Parser) void {
    parser.reset();
    _ = parser.next();
}

fn writeToFile(
    path: []const u8,
    parser: *ushell.Parser,
    tokens: usize,
    mode: fatfs.File.Mode,
) !void {
    const ff_path = fs.toFatFsPath(path);

    var file = try fatfs.File.open(ff_path, .{ .access = .write_only, .mode = mode });
    defer file.close();

    for (0..tokens) |_| {
        _ = try file.write(parser.next().?);
        _ = try file.write(" ");
    }
}

pub fn handle(_: *const Self, shell: *Shell) !void {
    const parser = &shell.parser;

    var i: usize = 0;
    var mode: ?fatfs.File.Mode = null;
    while (parser.next()) |token| {
        if (std.mem.eql(u8, token, ">")) {
            mode = .open_always;
        } else if (std.mem.eql(u8, token, ">>")) {
            mode = .open_append;
        }

        if (mode) |m| {
            const path = try getPath(parser);
            initialState(parser);
            return writeToFile(path, parser, i, m);
        }

        i += 1;
    }

    initialState(parser);
    while (parser.next()) |token| {
        shell.print("{s} ", .{token});
    }
}
