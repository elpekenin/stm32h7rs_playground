const args = @import("../args.zig");
const Shell = @import("../../cli.zig").Shell;

const Self = @This();

pub const description = "write into a memory address";

address: usize,
value: usize,
bytes: args.ByteMask = .@"4",

pub fn handle(self: *const Self, _: *Shell) void {
    const ptr: *usize = @ptrFromInt(self.address);
    ptr.* = self.value & self.bytes.mask();
}
