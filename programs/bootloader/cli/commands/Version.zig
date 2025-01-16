const builtin = @import("builtin");
const version = @import("version");

const ushell = @import("ushell");

const t = @import("../tab.zig");
const Shell = @import("../../cli.zig").Shell;

const Self = @This();

pub const meta: ushell.Meta = .{
    .description = "show current version",
};

const Type = enum {
    zig,
    git,
    build,
    all,
};

type: Type,

pub fn handle(self: Self, shell: *Shell) void {
    switch (self.type) {
        .zig => shell.print("{s}", .{builtin.zig_version_string}),
        .git => shell.print("{s}", .{version.commit}),
        .build => shell.print("{s}", .{version.datetime}),
        .all => shell.print("commit {s}, using zig {s} (built {s})", .{ version.commit, builtin.zig_version_string, version.datetime }),
    }
}

pub fn tab(shell: *Shell, tokens: []const []const u8) !void {
    return t.Enum(Type, shell, tokens, 1);
}
