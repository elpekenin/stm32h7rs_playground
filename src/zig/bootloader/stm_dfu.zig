const board = @import("../common/board.zig");
const hal = @import("../common/hal.zig");

const _jump = @import("jump.zig").to;

const BUILTIN_ADDR = 0x1FF18000;

inline fn disable_irq() void {
    asm volatile ("cpsid i" ::: "memory");
}

inline fn enable_irq() void {
    asm volatile ("cpsie i" ::: "memory");
}

pub fn check() bool {
    return board.USER.as_in(.High).read();
}

pub fn jump() noreturn {
    const led = board.LD3.as_out(.Low);

    led.set(true);
    hal.HAL_Delay(500);
    led.set(false);

    disable_irq();

    var SysTick = @as(*hal.SysTick_Type, @ptrFromInt(hal.SysTick_BASE));
    SysTick.CTRL = 0;

    // FIXME: handle this?
    _ = hal.HAL_RCC_DeInit();

    var NVIC = @as(*hal.NVIC_Type, @ptrFromInt(hal.NVIC_BASE));
    for (0..5) |i| {
        NVIC.ICER[i] = 0xFFFFFFFF;
        NVIC.ICPR[i] = 0xFFFFFFFF;
    }

    enable_irq();

    _jump(BUILTIN_ADDR);
}
