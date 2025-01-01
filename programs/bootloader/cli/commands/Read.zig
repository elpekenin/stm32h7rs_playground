const args = @import("../args.zig");
const t = @import("../tab.zig");
const Shell = @import("../../cli.zig").Shell;

const Self = @This();

pub const description = "read a memory address";

address: usize,
bytes: args.ByteMask = .@"4",

pub fn handle(self: *const Self, shell: *Shell) void {
    const ptr: *usize = @ptrFromInt(self.address);
    const value = ptr.* & self.bytes.mask();
    shell.print("{d}", .{value});
}

pub fn tab(shell: *Shell) !void {
    _ = try shell.parser.required(usize); // address
    return t.Enum(shell, args.ByteMask);
}
