const hal = @import("hal");
const ushell = @import("ushell");

const Shell = @import("../../cli.zig").Shell;

const Self = @This();

pub const meta: ushell.Meta = .{
    .description = "control a LED",
};

n: u2,
state: bool,

pub fn handle(self: Self, _: *Shell) void {
    hal.bsp.LEDS[self.n].set(self.state);
}
