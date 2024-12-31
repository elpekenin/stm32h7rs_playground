//! Utilities for filesystem access

const std = @import("std");

const fatfs = @import("fatfs");

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

// TODO: handle directories
// eg: `ls var/l<tab>` doesn't work now, should complete to `ls var/log`
pub fn autoComplete(shell: anytype, kind: fatfs.Kind) !void {
    const input = shell.parser.optional([]const u8) catch unreachable;

    // tokens left means the command looks something like `<command> foo bar<tab>`
    // nothing we can suggest, this is a single arg command
    try shell.parser.assertExhausted();

    var dir = try fatfs.Dir.open(try cwd());
    defer dir.close();

    var n: usize = 0;
    const max_names = 50;
    // extra u8 for sentinel value
    var names: [max_names][fatfs.FileInfo.max_name_len + 1]u8 = undefined;

    while (try dir.next()) |child| {
        if (child.kind != kind) continue;

        const name = child.name();

        if (input == null or std.mem.startsWith(u8, name, input.?)) {
            if (n == max_names) { // buffer already filled completely
                @branchHint(.unlikely);
                std.debug.panic("Exhausted `names` buffer.", .{});
            }

            for (0.., name) |i, char| {
                names[n][i] = char;
            }
            names[n][name.len] = 0;

            n += 1;
        }
    }

    switch (n) {
        0 => return,
        1 => {
            const name = std.mem.sliceTo(&names[0], 0);
            const diff = name[input.?.len..name.len];
            shell.buffer.appendSlice(diff) catch std.debug.panic("Exhausted reception buffer", .{});
            shell.print("{s}", .{diff});
        },
        else => {
            shell.print("\n", .{});
            for (names[0..n]) |name| {
                shell.print("{s} ", .{std.mem.sliceTo(&name, 0)});
            }
            shell.showPrompt();
            shell.print("{s}", .{shell.buffer.constSlice()});
        },
    }
}
