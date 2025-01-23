const std = @import("std");

const zfat = @import("zfat");
const ushell = @import("ushell");

const fs = @import("../fs.zig");
const Shell = @import("../../cli.zig").Shell;

const Self = @This();

pub const meta: ushell.Meta = .{
    .usage =
    \\usage: echo ...args [{>,>>} file]
    \\
    \\write input back
    \\
    \\
    \\options:
    \\  [none]    write to shell
    \\  >         write to <file>
    \\  >>        append to <file>
    ,
};

args: ushell.RemainingTokens,

fn writeToFile(
    path: []const u8,
    tokens: []const []const u8,
    mode: zfat.File.Mode,
) !void {
    var file = try zfat.File.open(fs.toPath(path), .{ .access = .write_only, .mode = mode });
    defer file.close();

    for (tokens) |token| {
        _ = try file.write(token);
        _ = try file.write(" ");
    }
}

pub fn handle(self: ushell.Args(Self), shell: *Shell) !void {
    const tokens = self.args;

    var mode: ?zfat.File.Mode = null;

    const maybe_redirect = tokens[tokens.len - 2];
    if (std.mem.eql(u8, maybe_redirect, ">")) {
        mode = .open_always;
    } else if (std.mem.eql(u8, maybe_redirect, ">>")) {
        mode = .open_append;
    }

    if (mode) |m| {
        const path = tokens[tokens.len - 1];
        return writeToFile(path, tokens[0 .. tokens.len - 2], m);
    }

    for (tokens) |token| {
        shell.print("{s} ", .{token});
    }
}
