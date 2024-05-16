const std = @import("std");

const hal = @import("common/hal.zig");
const board = @import("common/board.zig");
const logging = @import("common/logging.zig");

const bootloader = @import("bootloader/main.zig");

/// Note: Arguments' signature doesn't really matter as picolibc will be
/// doing `int ret = main(0, NULL)`. But, according to C11, argv should be a
/// non-const, null-terminated list of null-terminated strings.
pub export fn main(argc: i32, argv: [*c][*:0]u8) i32 {
    _ = argc;
    _ = argv;

    bootloader.run();

    return 0;
}

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, ret_add: ?usize) noreturn {
    @setCold(true);

    _ = msg;
    _ = error_return_trace;
    _ = ret_add;

    inline for (board.LEDS, 0..) |led, i| {
        const active = if (i <= 1) .High else .Low;

        if (led.as_out(active) catch null) |l| {
            l.set(true);
        }
    }

    while (true) {
        inline for (board.LEDS) |led| {
            // .Low / .High ignored here, we just toggling
            if (led.as_out(.Low) catch null) |l| {
                l.toggle();
            }
            hal.HAL_Delay(100);
        }
    }
}

pub const std_options = .{
    .log_level = .debug,
    .logFn = logging.log,
};
