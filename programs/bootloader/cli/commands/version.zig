const builtin = @import("builtin");
const version = @import("version");

const t = @import("../tab.zig");
const Shell = @import("../../cli.zig").Shell;

pub const Version = enum {
    const Self = @This();

    pub const description = "show current version";

    zig,
    git,
    build,
    all,

    pub fn handle(self: Self, shell: *Shell) void {
        switch (self) {
            .zig => shell.print("{s}", .{builtin.zig_version_string}),
            .git => shell.print("{s}", .{version.commit}),
            .build => shell.print("{s}", .{version.datetime}),
            .all => shell.print("commit {s}, using zig {s} (built {s})", .{ version.commit, builtin.zig_version_string, version.datetime }),
        }
    }

    pub fn tab(shell: *Shell) !void {
        return t.Enum(shell, Self);
    }
};
