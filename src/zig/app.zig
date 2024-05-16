const std = @import("std");

const hal = @import("common/hal.zig");
const board = @import("common/board.zig");

/// Note: Arguments' signature doesn't really matter as picolibc will be
/// doing `int ret = main(0, NULL)`. But, according to C11, argv should be a
/// non-const, null-terminated list of null-terminated strings.
pub export fn main(argc: i32, argv: [*c][*:0]u8) noreturn {
    _ = argc;
    _ = argv;

    hal.early_init();

    for (board.LEDS) |led| {
        led.init_out();
    }

    while (true) {
        for (board.LEDS) |led| {
            led.toggle();
        }
        hal.HAL_Delay(1000);
    }
}

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, ret_add: ?usize) noreturn {
    @setCold(true);

    _ = msg;
    _ = error_return_trace;
    _ = ret_add;

    while (true) {
        @breakpoint();
    }
}
