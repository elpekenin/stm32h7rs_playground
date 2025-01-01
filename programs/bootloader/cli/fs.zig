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

// TODO: fix handling of path with leading '/'
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

    pub fn print(self: *const Self, shell: anytype) void {
        const name = self.getName();

        const reset = shell.style(.default);
        const style = switch (self.kind) {
            .Directory => shell.style(.blue),
            .File => reset,
        };

        if (containsSpace(name)) {
            shell.print("{s}'{s}'{s} ", .{ style, name, reset });
        } else {
            shell.print("{s}{s}{s} ", .{ style, name, reset });
        }
    }
};

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
        // std.mem.startsWith(<some_input>, "") always matches
        .{ try cwd(), "" };

    var dir = try fatfs.Dir.open(path);
    defer dir.close();

    var n: usize = 0;
    const max_names = 50;
    var entries: [max_names]Entry = undefined;

    while (try dir.next()) |child| {
        const name = child.name();

        if (std.mem.startsWith(u8, name, needle)) {
            if (n == max_names) { // buffer already filled completely
                @branchHint(.unlikely);
                std.debug.panic("Exhausted `names` buffer.", .{});
            }

            entries[n] = Entry.from(child);
            n += 1;
        }
    }

    switch (n) {
        0 => {},
        1 => {
            const completion = entries[0].getCompletion();

            if (std.mem.eql(u8, needle, completion)) return;

            if (containsSpace(completion)) {
                // remove partial input
                shell.popInputN(needle.len);

                // write complete path, quoted
                shell.appendInput("'");
                shell.appendInput(completion);
                shell.appendInput("'");
            } else {
                // just write the remaining of the name
                const diff = completion[needle.len..completion.len];
                shell.appendInput(diff);
            }
        },
        else => {
            shell.print("\n", .{});

            for (entries[0..n]) |entry| {
                entry.print(shell);
            }

            shell.showPrompt();
            shell.print("{s}", .{shell.buffer.constSlice()});
        },
    }
}
