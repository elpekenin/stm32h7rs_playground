const std = @import("std");

const hal = @cImport({
    @cInclude("stm32h7rsxx_hal_ltdc.h");
});

const LTDC: type = hal.LTDC_HandleTypeDef;
const Status = hal.HAL_StatusTypeDef;


fn default_panic(
    msg: []const u8,
    error_return_trace: ?*std.builtin.StackTrace,
    ret_add: ?usize
) noreturn {
    @setCold(true);

    _ = msg;
    _ = error_return_trace;
    _ = ret_add;

    while (true) {
        @breakpoint();
    }
}

extern fn printf([*:0]const u8, ...) callconv(.C) c_int;

export fn main() c_int {
    var ltdc: LTDC = LTDC{};
    _ = hal.HAL_LTDC_Init(&ltdc);

    // Toooo big
    // _ = printf("Hello %d", @as(u32, 1));

    while (true) {}

    return 0;
}
