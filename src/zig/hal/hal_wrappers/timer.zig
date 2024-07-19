//! Configure the system timer

const std = @import("std");
const hal = @import("../hal.zig");

/// Timer counter frequency : 500 kHz
const TIM_CNT_FREQ = 500000;

/// Timer frequency : 1 kHz => to have 1 ms interrupt
const TIM_FREQ = 1000;

var TimHandle = std.mem.zeroes(hal.c.TIM_HandleTypeDef);

export fn HAL_InitTick(TickPriority: u32) callconv(.C) hal.c.HAL_StatusTypeDef {
    var Status: hal.c.HAL_StatusTypeDef = undefined;

    // Enable TIM6 clock
    hal.zig.rcc.TIM6.enable();

    // Get clock configuration
    var clkconfig: hal.c.RCC_ClkInitTypeDef = undefined;
    var pFLatency: u32 = undefined;
    hal.c.HAL_RCC_GetClockConfig(&clkconfig, &pFLatency);

    // Get APB1 prescaler
    const uwAPB1Prescaler: u32 = clkconfig.APB1CLKDivider;

    // Compute TIM6 clock
    const pclk1_freq = hal.c.HAL_RCC_GetPCLK1Freq();
    const uwTimclock = switch (uwAPB1Prescaler) {
        hal.c.RCC_APB1_DIV1 => pclk1_freq,
        hal.c.RCC_APB1_DIV2 => 2 * pclk1_freq,
        else => if (hal.c.__HAL_RCC_GET_TIMCLKPRESCALER() == hal.c.RCC_TIMPRES_DISABLE)
            2 * pclk1_freq
        else
            4 * pclk1_freq,
    };

    // Compute the prescaler value to have TIM6 counter clock equal to TIM_CNT_FREQ
    const uwPrescalerValue = (uwTimclock / TIM_CNT_FREQ) - 1;

    // Initialize TIM6
    TimHandle = .{
        .Instance = hal.c.TIM6,
        .Init = .{
            .Period = (hal.c.uwTickFreq * (TIM_CNT_FREQ / TIM_FREQ)) - 1,
            .Prescaler = uwPrescalerValue,
            .ClockDivision = 0,
            .CounterMode = hal.c.TIM_COUNTERMODE_UP,
            .AutoReloadPreload = hal.c.TIM_AUTORELOAD_PRELOAD_DISABLE,
        },
    };
    Status = hal.c.HAL_TIM_Base_Init(&TimHandle);

    if (Status == hal.c.HAL_OK) {
        // Start the TIM time Base generation in interrupt mode
        Status = hal.c.HAL_TIM_Base_Start_IT(&TimHandle);
        if (Status == hal.c.HAL_OK) {
            if (TickPriority < (1 << hal.c.__NVIC_PRIO_BITS)) {
                // Configure the TIM6 global Interrupt priority
                hal.c.HAL_NVIC_SetPriority(hal.c.TIM6_IRQn, TickPriority, 0);

                // Enable the TIM6 global Interrupt
                hal.c.HAL_NVIC_EnableIRQ(hal.c.TIM6_IRQn);

                hal.c.uwTickPrio = TickPriority;
            } else {
                Status = hal.c.HAL_ERROR;
            }
        }
    }

    // Return function status
    return Status;
}

/// Called when IRQ happens, by means of HAL_TIM_IRQHandler
export fn HAL_TIM_PeriodElapsedCallback(htim: *hal.c.TIM_HandleTypeDef) callconv(.C) void {
    _ = htim;
    hal.c.HAL_IncTick();
}

/// Do not use, only public for vector_table.zig to configure it
pub fn isr() callconv(.C) void {
    hal.c.HAL_TIM_IRQHandler(&TimHandle);
}

export fn HAL_ResumeTick() callconv(.C) void {
    TimHandle.Instance.*.DIER |= hal.c.TIM_IT_UPDATE;
}

export fn HAL_SuspendTick() callconv(.C) void {
    TimHandle.Instance.*.DIER &= ~hal.c.TIM_IT_UPDATE;
}
