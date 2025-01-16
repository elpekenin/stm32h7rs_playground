const ushell = @import("ushell");

const args = @import("../args.zig");
const t = @import("../tab.zig");
const Shell = @import("../../cli.zig").Shell;

const Self = @This();

pub const meta: ushell.Meta = .{
    .description = "read a memory address",
};

address: usize,
bytes: args.ByteMask = .@"4",

pub fn handle(self: Self, shell: *Shell) void {
    const ptr: *usize = @ptrFromInt(self.address);
    const value = ptr.* & self.bytes.mask();
    shell.print("{d}", .{value});
}

pub fn tab(shell: *Shell, tokens: []const []const u8) !void {
    return t.Enum(args.ByteMask, shell, tokens, 2);
}
