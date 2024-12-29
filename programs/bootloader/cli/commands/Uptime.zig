const hal = @import("hal");

const Shell = @import("../../cli.zig").Shell;

const Self = @This();

pub const description = "show time since boot";

pub fn handle(_: *const Self, shell: *Shell) void {
    const now = hal.zig.timer.now().to_s_ms();
    shell.print("{}.{:0>3}s", .{ now.seconds, now.milliseconds });
}
