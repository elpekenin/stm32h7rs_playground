const ushell = @import("ushell");

const args = @import("../args.zig");
const t = @import("../tab.zig");
const Shell = @import("../../cli.zig").Shell;

const Self = @This();

pub const meta: ushell.Meta = .{
    .description = "write into a memory address",
};

address: usize,
value: usize,
bytes: args.ByteMask = .@"4",

pub fn handle(self: Self, _: *Shell) void {
    const ptr: *usize = @ptrFromInt(self.address);
    ptr.* = self.value & self.bytes.mask();
}

pub fn tab(shell: *Shell, tokens: []const []const u8) !void {
    return t.Enum(args.ByteMask, shell, tokens, 3);
}
