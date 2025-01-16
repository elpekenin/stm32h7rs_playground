const hal = @import("hal");
const ushell = @import("ushell");

const Shell = @import("../../cli.zig").Shell;

const Self = @This();

pub const meta: ushell.Meta = .{
    .description = "show time since boot",
};

pub fn handle(_: Self, shell: *Shell) void {
    const now = hal.zig.timer.now().to_s_ms();
    shell.print("{}.{:0>3}s", .{ now.seconds, now.milliseconds });
}
