const std = @import("std");

const hal = @import("hal.zig");
const board = @import("board.zig");

/// Note: Arguments' signature doesn't really matter as picolibc will be
/// doing `int ret = main(0, NULL)`. But, according to C11, argv should be a
/// non-const, null-terminated list of null-terminated strings.
pub export fn main(argc: i32, argv: [*c][*:0]u8) i32 {
    _ = argc;
    _ = argv;

    // Initialize MCU
    hal.HAL_MPU_Disable();
    // hal.SCB_EnableICache(); // zig does not like :/
    // hal.SCB_EnableDCache(); // zig does not like :/
    hal.SystemCoreClockUpdate();

    const ret = hal.HAL_Init();
    if (ret != hal.HAL_OK) {
        @panic("HAL initialization failed");
    }

    for (board.LEDS) |led| {
        led.init_out();
    }

    while (true) {
        for (board.LEDS) |led| {
            led.toggle();
        }
        hal.HAL_Delay(1000);
    }

    return 0;
}

fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, ret_add: ?usize) noreturn {
    @setCold(true);

    _ = msg;
    _ = error_return_trace;
    _ = ret_add;

    while (true) {
        @breakpoint();
    }
}
