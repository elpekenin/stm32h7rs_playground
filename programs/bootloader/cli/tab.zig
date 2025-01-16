//! Auto-complete logic

// TODO: bool literals

const std = @import("std");

const zfat = @import("zfat");
const ushell = @import("ushell");

const fs = @import("fs.zig");
const Shell = @import("../cli.zig").Shell;

fn getDir(slice: []const u8) ?[]const u8 {
    // no slashes -> null -> work on cwd
    // any slashes -> return up to (including) last one
    const end = std.mem.lastIndexOf(u8, slice, "/") orelse return null;
    return slice[0 .. end + 1];
}

fn getToken(tokens: []const []const u8, index: usize) ?[]const u8 {
    if (tokens.len <= index) return null;
    return tokens[index];
}

pub fn Enum(comptime E: type, shell: *Shell, tokens: []const []const u8, index: usize) !void {
    const input = getToken(tokens, index);
    const needle = input orelse "";

    const fields = @typeInfo(E).@"enum".fields;
    const names = ushell.utils.findMatches(fields, needle);

    shell.complete(needle, names);
}

pub fn path(shell: *Shell, tokens: []const []const u8, index: usize) !void {
    // NOTE: tokens[0] is command's name

    const maybe_input = getToken(tokens, index);

    const dir_path, const needle = if (maybe_input) |input|
        if (getDir(input)) |dir|
            .{ fs.toPath(dir), input[dir.len..input.len] }
        else
            .{ try fs.cwd(), input }
    else
        // std.mem.startsWith(<some_input>, "") always matches
        .{ try fs.cwd(), "" };

    var dir = try zfat.Dir.open(dir_path);
    defer dir.close();

    var n: usize = 0;
    const max_names = 50;
    var entries: [max_names]fs.Entry = undefined;

    while (try dir.next()) |child| {
        const name = child.name();

        if (std.mem.startsWith(u8, name, needle)) {
            if (n == max_names) { // buffer already filled completely
                @branchHint(.unlikely);
                std.debug.panic("Exhausted `names` buffer.", .{});
            }

            entries[n] = fs.Entry.from(child);
            n += 1;
        }
    }

    switch (n) {
        0 => {},
        1 => shell.applyCompletion(needle, entries[0].getCompletion()),
        else => {
            shell.print("\n", .{});

            for (entries[0..n]) |entry| {
                entry.print(shell);
            }

            shell.prompt();
            shell.print("{s}", .{shell.buffer.constSlice()});
        },
    }
}
