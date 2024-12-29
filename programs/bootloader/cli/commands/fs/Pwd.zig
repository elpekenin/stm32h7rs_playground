const fatfs = @import("fatfs");

const utils = @import("utils.zig");
const Shell = @import("../../../cli.zig").Shell;

const Self = @This();

pub fn handle(_: *const Self, shell: *Shell) !void {
    const cwd = try utils.cwd();
    shell.print("{s}", .{cwd});
}
