const c = @import("../mod.zig").c;

pub const NVIC = @as(*c.NVIC_Type, @ptrFromInt(c.NVIC_BASE));
pub const RCC: *c.RCC_TypeDef = @ptrFromInt(c.RCC_BASE);
pub const SCB = @as(*c.SCB_Type, @ptrFromInt(c.SCB_BASE));
pub const SysTick = @as(*c.SysTick_Type, @ptrFromInt(c.SysTick_BASE));
