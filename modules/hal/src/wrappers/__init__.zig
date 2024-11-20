//! "Tiny" zig wrappers on top of STM HAL

const std = @import("std");
const hal = @import("../hal.zig");
const c = hal.c;

pub const cache = @import("cache.zig");
pub const peripherals = @import("peripherals.zig");
pub const rcc = @import("rcc.zig");
pub const sd = @import("sd.zig");
pub const timer = @import("timer.zig");
pub const usb = @import("usb.zig");
pub const xspi = @import("xspi.zig");

const RCC = peripherals.RCC;
const SCB = peripherals.SCB;

fn to_f32(val: anytype) f32 {
    return @as(f32, @floatFromInt(val));
}

fn to_u5(val: anytype) u5 {
    return @as(u5, @intCast(val));
}

fn enableFPU() void {
    // CP10 & CP11 Full Access
    SCB.CPACR |= (3 << 10 * 2) | (3 << 11 * 2);
}

fn initHal() void {
    const ret = c.HAL_Init();
    if (ret != c.HAL_OK) {
        std.debug.panic("HAL_Init", .{});
    }
}

fn initPower() void {
    if (c.HAL_PWREx_ControlVoltageScaling(c.PWR_REGULATOR_VOLTAGE_SCALE0) != c.HAL_OK) {
        std.debug.panic("HAL_PWREx_ControlVoltageScaling", .{});
    }
}

fn initClocks() void {
    var rcc_init = std.mem.zeroInit(
        c.RCC_OscInitTypeDef,
        .{
            .OscillatorType = c.RCC_OSCILLATORTYPE_HSI48 | c.RCC_OSCILLATORTYPE_HSI,
            .HSIState = c.RCC_HSI_ON,
            .HSIDiv = c.RCC_HSI_DIV1,
            .HSICalibrationValue = c.RCC_HSICALIBRATION_DEFAULT,
            .HSI48State = c.RCC_HSI48_ON,
            .PLL1 = .{
                .PLLState = c.RCC_PLL_ON,
                .PLLSource = c.RCC_PLLSOURCE_HSI,
                .PLLM = 32,
                .PLLN = 300,
                .PLLP = 1,
                .PLLQ = 2,
                .PLLR = 2,
                .PLLS = 2,
                .PLLT = 2,
                .PLLFractional = 0,
            },
            .PLL2 = .{
                .PLLState = c.RCC_PLL_ON,
                .PLLSource = c.RCC_PLLSOURCE_HSI,
                .PLLM = 4,
                .PLLN = 25,
                .PLLP = 2,
                .PLLQ = 2,
                .PLLR = 2,
                .PLLS = 2,
                .PLLT = 2,
                .PLLFractional = 0,
            },
            .PLL3 = .{
                .PLLState = c.RCC_PLL_ON,
                .PLLSource = c.RCC_PLLSOURCE_HSI,
                .PLLM = 4,
                .PLLN = 25,
                .PLLP = 2,
                .PLLQ = 20,
                .PLLR = 1,
                .PLLS = 2,
                .PLLT = 2,
                .PLLFractional = 0,
            },
        },
    );
    try rcc.config(&rcc_init);

    var rcc_clk = std.mem.zeroInit(
        c.RCC_ClkInitTypeDef,
        .{
            .ClockType = c.RCC_CLOCKTYPE_HCLK | c.RCC_CLOCKTYPE_SYSCLK | c.RCC_CLOCKTYPE_PCLK1 | c.RCC_CLOCKTYPE_PCLK2 | c.RCC_CLOCKTYPE_PCLK4 | c.RCC_CLOCKTYPE_PCLK5,
            .SYSCLKSource = c.RCC_SYSCLKSOURCE_PLLCLK,
            .SYSCLKDivider = c.RCC_SYSCLK_DIV1,
            .AHBCLKDivider = c.RCC_HCLK_DIV2,
            .APB1CLKDivider = c.RCC_APB1_DIV2,
            .APB2CLKDivider = c.RCC_APB2_DIV2,
            .APB4CLKDivider = c.RCC_APB4_DIV2,
            .APB5CLKDivider = c.RCC_APB5_DIV2,
        },
    );
    if (c.HAL_RCC_ClockConfig(&rcc_clk, c.FLASH_LATENCY_6) != c.HAL_OK) {
        std.debug.panic("HAL_RCC_ClockConfig", .{});
    }
}

export var SystemCoreClock: u32 = c.HSI_VALUE;

fn SystemCoreClockUpdate() void {
    // Get SYSCLK source
    const sysclk: u32 = switch (RCC.CFGR & c.RCC_CFGR_SWS) {
        // HIS used as system clock source (default after reset)
        0x00 => c.HSI_VALUE >> to_u5((RCC.CR & c.RCC_CR_HSIDIV) >> c.RCC_CR_HSIDIV_Pos),

        // CSI used as system clock source
        0x08 => c.CSI_VALUE,

        // HSE used as system clock source
        0x10 => c.HSE_VALUE,

        // PLL1 used as system clock  source
        // PLL1_VCO = (HSE_VALUE or HSI_VALUE or CSI_VALUE/ PLLM) * PLLN
        // SYSCLK = PLL1_VCO / PLL1R
        0x18 => pll1_source_blk: {
            const pllm = (RCC.PLLCKSELR & c.RCC_PLLCKSELR_DIVM1) >> c.RCC_PLLCKSELR_DIVM1_Pos;
            if (pllm == 0) {
                break :pll1_source_blk 0;
            }

            const pllfracn: f32 = if ((RCC.PLLCFGR & c.RCC_PLLCFGR_PLL1FRACEN) != 0)
                to_f32(RCC.PLL1FRACR & c.RCC_PLL1FRACR_FRACN >> c.RCC_PLL1FRACR_FRACN_Pos)
            else
                0;

            const factor: f32 = (to_f32(RCC.PLL1DIVR1 & c.RCC_PLL1DIVR1_DIVN) + (pllfracn / 0x2000) + 1) / to_f32(pllm);
            const hsivalue: u32 = c.HSI_VALUE >> to_u5((RCC.CR & c.RCC_CR_HSIDIV) >> c.RCC_CR_HSIDIV_Pos);

            const pllvco: f32 = switch (RCC.PLLCKSELR & c.RCC_PLLCKSELR_PLLSRC) {
                // HSE used as PLL1 clock source
                0x02 => c.HSE_VALUE * factor,

                // CSI used as PLL1 clock source
                0x01 => c.CSI_VALUE * factor,

                // HIS used as PLL1 clock source */
                else => to_f32(hsivalue) * factor,
            };

            const pllp: u32 = ((RCC.PLL1DIVR1 & c.RCC_PLL1DIVR1_DIVP) >> c.RCC_PLL1DIVR1_DIVP_Pos) + 1;

            break :pll1_source_blk @intFromFloat(pllvco / to_f32(pllp));
        },

        // Unexpected, default to HIS used as system clock source (default after reset)
        else => c.HSI_VALUE >> to_u5((RCC.CR & c.RCC_CR_HSIDIV) >> c.RCC_CR_HSIDIV_Pos),
    };

    // system clock frequency : CM7 CPU frequency
    const core_presc: u32 = RCC.CDCFGR & c.RCC_CDCFGR_CPRE;

    SystemCoreClock = if (core_presc >= 8)
        sysclk >> to_u5(core_presc - c.RCC_CDCFGR_CPRE_3 + 1)
    else
        sysclk;
}

/// Initialize HAL and clocks
pub fn init() void {
    enableFPU();
    initHal();
    initPower();
    initClocks();
    SystemCoreClockUpdate();
    hal.dk.init();
}

// Please zig, do not garbage-collect these, we need to export C funcs, thx!!
comptime {
    _ = @import("msp/base.zig");
    _ = @import("msp/sd.zig");
    _ = @import("msp/xspi.zig");
}

pub const Active = enum {
    Low,
    High,
};

/// Mostly meant to store pin+port combo, but also tiny wrappers for HAL
pub const Pin = struct {
    const Self = @This();

    pub const Config = struct {
        mode: c_uint = 0,
        pull: c_uint = 0,
        speed: c_uint = 0,
        alternate: c_uint = 0,
    };

    port: *c.GPIO_TypeDef,
    pin: u16,

    pub fn init(pin: Self, config: Config) void {
        rcc.enable_gpio(pin.port);

        var gpio_init = std.mem.zeroInit(
            c.GPIO_InitTypeDef,
            .{
                .Pin = pin.pin,
                .Mode = config.mode,
                .Pull = config.pull,
                .Speed = config.speed,
                .Alternate = config.alternate,
            },
        );
        c.HAL_GPIO_Init(pin.port, &gpio_init);
    }
};

/// Store the configuration for an input pin (eg button)
pub const DigitalIn = struct {
    const Self = @This();

    base: Pin,
    active: Active,

    /// Configure the pin
    pub fn init(self: Self) void {
        const hal_pull = switch (self.active) {
            .Low => c.GPIO_PULLUP,
            .High => c.GPIO_PULLDOWN,
        };

        self.base.init(.{
            .mode = c.GPIO_MODE_INPUT,
            .pull = hal_pull,
            .speed = c.GPIO_SPEED_FREQ_LOW,
        });
    }

    /// Read input, takin into account the pull, to return "is button pressed"
    pub fn read(self: Self) bool {
        const check = switch (self.active) {
            .Low => c.GPIO_PIN_RESET,
            .High => c.GPIO_PIN_SET,
        };

        return c.HAL_GPIO_ReadPin(self.base.port, self.base.pin) == check;
    }
};

/// Store the configuration for an output pin (eg LED)
pub const DigitalOut = struct {
    const Self = @This();

    base: Pin,
    active: Active,

    /// Configure the pin and set it at "off" state
    pub fn init(self: Self) void {
        // TODO?: Something based on `self.active`
        self.base.init(.{
            .mode = c.GPIO_MODE_OUTPUT_PP,
            .pull = c.GPIO_PULLUP,
            .speed = c.GPIO_SPEED_FREQ_VERY_HIGH,
        });
    }

    /// Set the **logical** output level (according to active-ness)
    pub fn set(self: Self, value: bool) void {
        const output = switch (self.active) {
            .Low => !value,
            .High => value,
        };

        const hal_out: c_uint = if (output) c.GPIO_PIN_SET else c.GPIO_PIN_RESET;

        c.HAL_GPIO_WritePin(self.base.port, self.base.pin, hal_out);
    }

    /// Toggle the output voltage
    pub fn toggle(self: Self) void {
        c.HAL_GPIO_TogglePin(self.base.port, self.base.pin);
    }
};
