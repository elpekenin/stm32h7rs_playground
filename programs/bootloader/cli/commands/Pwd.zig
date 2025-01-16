const fs = @import("../fs.zig");
const Shell = @import("../../cli.zig").Shell;

const Self = @This();

pub fn handle(_: Self, shell: *Shell) !void {
    const cwd = try fs.cwd();
    shell.print("{s}", .{cwd});
}
