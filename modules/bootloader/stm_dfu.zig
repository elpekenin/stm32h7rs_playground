//! Logic to define when and how to jump into STM's
//! builtin bootloader in the silicon, programmatically.

const hal = @import("hal");
const c = hal.c;
const NVIC = hal.zig.peripherals.NVIC;
const SysTick = hal.zig.peripherals.SysTick;

const jump = @import("jump.zig");

const BUILTIN_ADDR = 0x1FF18000;

/// Red LED
const INDICATOR = hal.dk.LEDS[2];

pub fn check() bool {
    return hal.dk.BUTTON.read();
}

pub fn bootloader() noreturn {
    INDICATOR.set(true);
    hal.zig.timer.sleep(500);
    INDICATOR.set(false);

    hal.assembly.disable_irq();

    SysTick.CTRL = 0;

    // FIXME: handle this?
    _ = c.HAL_RCC_DeInit();

    for (0..5) |i| {
        NVIC.ICER[i] = 0xFFFFFFFF;
        NVIC.ICPR[i] = 0xFFFFFFFF;
    }

    hal.assembly.enable_irq();

    jump.to(BUILTIN_ADDR);
}
