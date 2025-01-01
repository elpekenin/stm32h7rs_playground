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

fn containsSpace(slice: []const u8) bool {
    for (slice) |char| {
        if (char == ' ') return true;
    }

    return false;
}

// find deepest directory in input
// Examples:
//   foo -> null
//   foo/ -> foo
//   foo/bar -> foo
//   foo/bar/baz -> foo/bar
fn findDir(slice: []const u8) ?[]const u8 {
    var end: usize = slice.len - 1;

    while (end > 0) : (end -= 1) {
        if (slice[end] == '/') {
            return slice[0..end];
        }
    }

    return null;
}

pub fn autoComplete(shell: anytype) !void {
    const maybe_input: ?[]const u8 = shell.parser.optional([]const u8) catch unreachable;

    // tokens left means the command looks something like `<command> foo bar<tab>`
    // nothing we can suggest, this is a single arg command
    try shell.parser.assertExhausted();

    const path, const needle = if (maybe_input) |input|
        if (findDir(input)) |dir|
            // +1 because `dir` does not contain the '/'
            .{ toPath(dir), input[dir.len + 1 .. input.len] }
        else
            .{ try cwd(), input }
    else
        .{ try cwd(), "" } // std.mem.startswith(<some_input>, "") always matches
        ;

    var dir = try fatfs.Dir.open(path);
    defer dir.close();

    var n: usize = 0;
    const max_names = 50;
    // extra space for '/' and sentinel
    var names: [max_names][fatfs.FileInfo.max_name_len + 2]u8 = undefined;

    while (try dir.next()) |child| {
        const name = child.name();

        if (std.mem.startsWith(u8, name, needle)) {
            if (n == max_names) { // buffer already filled completely
                @branchHint(.unlikely);
                std.debug.panic("Exhausted `names` buffer.", .{});
            }

            for (0.., name) |i, char| {
                names[n][i] = char;
            }

            switch (child.kind) {
                .Directory => {
                    names[n][name.len] = '/';
                    names[n][name.len + 1] = 0;
                },
                .File => {
                    names[n][name.len] = 0;
                },
            }

            n += 1;
        }
    }

    switch (n) {
        0 => {},
        1 => {
            const name = std.mem.sliceTo(&names[0], 0);

            if (std.mem.eql(u8, needle, name)) return;

            if (containsSpace(name)) {
                // remove partial input
                shell.popInputN(needle.len);

                // write complete path, quoted
                shell.appendInput("'");
                shell.appendInput(name);
                shell.appendInput("'");
            } else {
                // just write the remaining of the name
                const diff = name[needle.len..name.len];
                shell.appendInput(diff);
            }
        },
        else => {
            shell.print("\n", .{});

            for (names[0..n]) |raw| {
                const name: []const u8 = std.mem.sliceTo(&raw, 0);

                if (containsSpace(name)) {
                    shell.print("'{s}' ", .{name});
                } else {
                    shell.print("{s} ", .{name});
                }
            }

            shell.showPrompt();
            shell.print("{s}", .{shell.buffer.constSlice()});
        },
    }
}
