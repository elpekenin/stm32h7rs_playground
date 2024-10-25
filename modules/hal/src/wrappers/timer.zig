//! Configure the system timer

const std = @import("std");
const hal = @import("../hal.zig");
const c = hal.c;

/// Timer counter frequency : 500 kHz
const TIM_CNT_FREQ = 500000;

/// Timer frequency : 1 kHz => to have 1 ms interrupt
const TIM_FREQ = 1000;

const TickT = u32;

var TimHandle = std.mem.zeroes(c.TIM_HandleTypeDef);

export fn HAL_InitTick(TickPriority: u32) callconv(.C) c.HAL_StatusTypeDef {
    var Status: c.HAL_StatusTypeDef = undefined;

    // Enable TIM6 clock
    hal.zig.rcc.TIM6.enable();

    // Get clock configuration
    var clkconfig: c.RCC_ClkInitTypeDef = undefined;
    var pFLatency: u32 = undefined;
    c.HAL_RCC_GetClockConfig(&clkconfig, &pFLatency);

    // Get APB1 prescaler
    const uwAPB1Prescaler: u32 = clkconfig.APB1CLKDivider;

    // Compute TIM6 clock
    const pclk1_freq = c.HAL_RCC_GetPCLK1Freq();
    const uwTimclock = switch (uwAPB1Prescaler) {
        c.RCC_APB1_DIV1 => pclk1_freq,
        c.RCC_APB1_DIV2 => 2 * pclk1_freq,
        else => if (c.__HAL_RCC_GET_TIMCLKPRESCALER() == c.RCC_TIMPRES_DISABLE)
            2 * pclk1_freq
        else
            4 * pclk1_freq,
    };

    // Compute the prescaler value to have TIM6 counter clock equal to TIM_CNT_FREQ
    const uwPrescalerValue = (uwTimclock / TIM_CNT_FREQ) - 1;

    // Initialize TIM6
    TimHandle = .{
        .Instance = c.TIM6,
        .Init = .{
            .Period = (c.uwTickFreq * (TIM_CNT_FREQ / TIM_FREQ)) - 1,
            .Prescaler = uwPrescalerValue,
            .ClockDivision = 0,
            .CounterMode = c.TIM_COUNTERMODE_UP,
            .AutoReloadPreload = c.TIM_AUTORELOAD_PRELOAD_DISABLE,
        },
    };
    Status = c.HAL_TIM_Base_Init(&TimHandle);

    if (Status == c.HAL_OK) {
        // Start the TIM time Base generation in interrupt mode
        Status = c.HAL_TIM_Base_Start_IT(&TimHandle);
        if (Status == c.HAL_OK) {
            if (TickPriority < (1 << c.__NVIC_PRIO_BITS)) {
                // Configure the TIM6 global Interrupt priority
                c.HAL_NVIC_SetPriority(c.TIM6_IRQn, TickPriority, 0);

                // Enable the TIM6 global Interrupt
                c.HAL_NVIC_EnableIRQ(c.TIM6_IRQn);

                c.uwTickPrio = TickPriority;
            } else {
                Status = c.HAL_ERROR;
            }
        }
    }

    // Return function status
    return Status;
}

/// Called when IRQ happens, by means of HAL_TIM_IRQHandler
export fn HAL_TIM_PeriodElapsedCallback(htim: *c.TIM_HandleTypeDef) callconv(.C) void {
    _ = htim;
    c.HAL_IncTick();
}

/// Do not use, only public for vector_table.zig to configure it
pub fn isr() callconv(.C) void {
    c.HAL_TIM_IRQHandler(&TimHandle);
}

export fn HAL_ResumeTick() callconv(.C) void {
    TimHandle.Instance.*.DIER |= c.TIM_IT_UPDATE;
}

export fn HAL_SuspendTick() callconv(.C) void {
    TimHandle.Instance.*.DIER &= ~c.TIM_IT_UPDATE;
}

pub fn now() TickT {
    return c.HAL_GetTick();
}

/// TODO: union(enum) for .ms, .ticks, etc
pub fn sleep(ticks: TickT) void {
    c.HAL_Delay(ticks);
}
