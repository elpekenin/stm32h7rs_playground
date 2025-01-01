//! Auto-complete logic

// TODO: bool literals

const std = @import("std");

const fatfs = @import("fatfs");

const fs = @import("fs.zig");
const Shell = @import("../cli.zig").Shell;

fn getDir(slice: []const u8) ?[]const u8 {
    // no slashes -> null -> work on cwd
    // any slashes -> return up to (including) last one
    const end = std.mem.lastIndexOf(u8, slice, "/") orelse return null;
    return slice[0 .. end + 1];
}

fn complete(shell: *Shell, needle: []const u8, final: []const u8) void {
    if (std.mem.eql(u8, needle, final)) return;

    if (std.mem.containsAtLeast(u8, final, 1, " ")) {
        // remove partial input
        shell.popInputN(needle.len);

        // write complete path, quoted
        shell.appendInput("'");
        shell.appendInput(final);
        shell.appendInput("'");
    } else {
        // just write the remaining of the name
        const diff = final[needle.len..final.len];
        shell.appendInput(diff);
    }
}

pub fn Enum(shell: *Shell, E: type) !void {
    const input = shell.parser.optional([]const u8) catch unreachable;
    const needle = input orelse "";

    const I = @typeInfo(E);
    const fields = I.@"enum".fields;

    var n: usize = 0;
    var names: [fields.len][:0]const u8 = undefined;

    inline for (fields) |field| {
        const name = field.name;

        if (std.mem.startsWith(u8, name, needle)) {
            names[n] = name;
            n += 1;
        }
    }

    switch (n) {
        0 => {},
        1 => complete(shell, needle, names[0]),
        else => {
            shell.print("\n", .{});

            for (names[0..n]) |name| {
                shell.print("{s} ", .{name});
            }

            shell.showPrompt();
            shell.print("{s}", .{shell.buffer.constSlice()});
        },
    }
}

pub fn path(shell: *Shell) !void {
    const maybe_input = shell.parser.optional([]const u8) catch unreachable;

    const dir_path, const needle = if (maybe_input) |input|
        if (getDir(input)) |dir|
            .{ fs.toPath(dir), input[dir.len..input.len] }
        else
            .{ try fs.cwd(), input }
    else
        // std.mem.startsWith(<some_input>, "") always matches
        .{ try fs.cwd(), "" };

    var dir = try fatfs.Dir.open(dir_path);
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
        1 => complete(shell, needle, entries[0].getCompletion()),
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
