const hal = @import("hal");

const Shell = @import("../../cli.zig").Shell;

const Self = @This();

ms: u32,

pub fn handle(self: *const Self, _: *Shell) void {
    hal.zig.timer.sleep(.{
        .milliseconds = self.ms,
    });
}
