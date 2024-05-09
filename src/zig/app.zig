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
    _ = hal.HAL_Init();

    MX_GPIO_Init();

    while (true) {
        board.togglePins();
        hal.HAL_Delay(500);
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

fn MX_GPIO_Init() void {
    var GPIO_InitStruct: hal.GPIO_InitTypeDef = hal.GPIO_InitTypeDef{};

    // this block should be `hal.__HAL_RCC_GPIOO_CLK_ENABLE();`
    // manually copy-pasted the macro, and made some manual tweaks as zig doesnt like it

    var RCC = @as(*hal.RCC_TypeDef, @ptrFromInt(hal.RCC_BASE));
    var _tmp: u32 = 0;
    const tmp: *volatile u32 = &_tmp;

    RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIOOEN;
    tmp.* = RCC.AHB4ENR;

    RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIOMEN;
    tmp.* = RCC.AHB4ENR;

    hal.HAL_GPIO_WritePin(hal.GPIOO, board.LD1.pin | board.LD2.pin, hal.GPIO_PIN_RESET);
    hal.HAL_GPIO_WritePin(hal.GPIOM, board.LD3.pin | board.LD4.pin, hal.GPIO_PIN_RESET);

    GPIO_InitStruct.Pin = board.LD1.pin | board.LD2.pin;
    GPIO_InitStruct.Mode = hal.GPIO_MODE_OUTPUT_PP;
    GPIO_InitStruct.Pull = hal.GPIO_NOPULL;
    GPIO_InitStruct.Speed = hal.GPIO_SPEED_FREQ_LOW;
    hal.HAL_GPIO_Init(hal.GPIOO, &GPIO_InitStruct);

    GPIO_InitStruct.Pin = board.LD3.pin | board.LD4.pin;
    GPIO_InitStruct.Mode = hal.GPIO_MODE_OUTPUT_PP;
    GPIO_InitStruct.Pull = hal.GPIO_NOPULL;
    GPIO_InitStruct.Speed = hal.GPIO_SPEED_FREQ_LOW;
    hal.HAL_GPIO_Init(hal.GPIOM, &GPIO_InitStruct);
}
