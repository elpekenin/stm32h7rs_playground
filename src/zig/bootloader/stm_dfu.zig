//! Logic to define when and how to jump into STM's
//! builtin bootloader in the silicon, programatically.

const hal = @import("../common/hal.zig");

const jump = @import("jump.zig");

const BUILTIN_ADDR = 0x1FF18000;

inline fn disable_irq() void {
    asm volatile ("cpsid i" ::: "memory");
}

inline fn enable_irq() void {
    asm volatile ("cpsie i" ::: "memory");
}

pub fn check() bool {
    return hal.dk.BUTTON.as_in(.High).read();
}

pub fn bootloader() noreturn {
    const led = hal.dk.LEDS[2].as_out(.Low);
    led.set(true);
    hal.c.HAL_Delay(500);
    led.set(false);

    disable_irq();

    var SysTick = @as(*hal.c.SysTick_Type, @ptrFromInt(hal.c.SysTick_BASE));
    SysTick.CTRL = 0;

    // FIXME: handle this?
    _ = hal.c.HAL_RCC_DeInit();

    var NVIC = @as(*hal.c.NVIC_Type, @ptrFromInt(hal.c.NVIC_BASE));
    for (0..5) |i| {
        NVIC.ICER[i] = 0xFFFFFFFF;
        NVIC.ICPR[i] = 0xFFFFFFFF;
    }

    enable_irq();

    jump.to(BUILTIN_ADDR);
}
