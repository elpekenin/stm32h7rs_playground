// Constants for DK board peripherals
const hal = @import("hal.zig");

pub const Pull = enum(c_uint) {
    No = hal.GPIO_NOPULL,
    Up = hal.GPIO_PULLUP,
    Down = hal.GPIO_PULLDOWN,
};

/// Inverted logic as this is used on initialization, and we want
/// to init off
pub const Active = enum(c_uint) {
    Low = hal.GPIO_PIN_SET,
    High = hal.GPIO_PIN_RESET,
};

pub const Pin = struct {
    port: *hal.GPIO_TypeDef,
    pin: u16,

    /// Enable a pin, this is:
    ///   - Enable its clock
    ///   - Give it power (only ports O and M implemented yet)
    pub fn enable(self: Pin) void {
        // should use `hal.__HAL_RCC_GPIO%_CLK_ENABLE();`, but zig doesnt like those macros

        var RCC = @as(*hal.RCC_TypeDef, @ptrFromInt(hal.RCC_BASE));
        var _tmpreg: u32 = 0;
        const tmpreg: *volatile u32 = &_tmpreg;

        switch (self.port) {
            hal.GPIOA => RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIOAEN,

            hal.GPIOB => RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIOBEN,

            hal.GPIOC => {
                hal.HAL_PWREx_EnableUSBReg();
                RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIOCEN;
            },

            hal.GPIOD => RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIODEN,

            hal.GPIOE => RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIOEEN,

            hal.GPIOF => RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIOFEN,

            hal.GPIOG => RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIOGEN,

            hal.GPIOH => RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIOHEN,

            hal.GPIOM => {
                const ret = hal.HAL_PWREx_EnableUSBVoltageDetector();
                if (ret != hal.HAL_OK) {
                    @panic("Could not enable USB voltage level detector");
                }
                RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIOMEN;
            },

            hal.GPION => RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIONEN,

            hal.GPIOO => {
                hal.HAL_PWREx_EnableXSPIM1();
                RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIOOEN;
            },

            hal.GPIOP => RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIOPEN,

            else => @panic("Unknown GPIO port"),
        }

        tmpreg.* = RCC.AHB4ENR;
    }

    /// Initialize a pin as output
    pub fn init_out(self: Pin, active: Active) void {
        self.enable();

        const GPIO_InitStruct: hal.GPIO_InitTypeDef = hal.GPIO_InitTypeDef{
            .Pin = self.pin,
            .Mode = hal.GPIO_MODE_OUTPUT_PP,
            .Pull = hal.GPIO_NOPULL,
            .Speed = hal.GPIO_SPEED_FREQ_LOW,
        };
        hal.HAL_GPIO_Init(self.port, &GPIO_InitStruct);

        hal.HAL_GPIO_WritePin(self.port, self.pin, @intFromEnum(active));
    }

    /// Set the value of an output pin
    pub fn set_pin(self: Pin, value: bool) void {
        hal.HAL_GPIO_WritePin(self.port, self.pin, if (value) hal.GPIO_PIN_SET else hal.GPIO_PIN_RESET);
    }

    /// Change the value of an output pin
    pub fn toggle(self: Pin) void {
        hal.HAL_GPIO_TogglePin(self.port, self.pin);
    }

    /// Initialize a pin as input
    pub fn init_in(self: Pin, pull: Pull) void {
        self.enable();

        const GPIO_InitStruct: hal.GPIO_InitTypeDef = hal.GPIO_InitTypeDef{
            .Pin = self.pin,
            .Mode = hal.GPIO_MODE_INPUT,
            .Pull = @intFromEnum(pull),
            .Speed = hal.GPIO_SPEED_FREQ_LOW,
        };
        hal.HAL_GPIO_Init(self.port, &GPIO_InitStruct);
    }

    pub fn read_in(self: Pin) c_uint {
        return hal.HAL_GPIO_ReadPin(self.port, self.pin);
    }
};

// Button
pub const USER = Pin{
    .port = hal.GPIOC,
    .pin = hal.GPIO_PIN_13,
};

// LEDs
pub const LD1 = Pin{
    .port = hal.GPIOO,
    .pin = hal.GPIO_PIN_1,
};

pub const LD2 = Pin{
    .port = hal.GPIOO,
    .pin = hal.GPIO_PIN_5,
};

pub const LD3 = Pin{
    .port = hal.GPIOM,
    .pin = hal.GPIO_PIN_2,
};

pub const LD4 = Pin{
    .port = hal.GPIOM,
    .pin = hal.GPIO_PIN_3,
};

pub const LEDS: [4]Pin = .{ LD1, LD2, LD3, LD3 };
