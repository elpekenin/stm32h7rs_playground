// Constants for DK board peripherals
const hal = @import("hal.zig");

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
            hal.GPIOC => RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIOCEN,
            hal.GPIOD => RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIODEN,
            hal.GPIOE => RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIOEEN,
            hal.GPIOF => RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIOFEN,
            hal.GPIOG => RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIOGEN,
            hal.GPIOH => RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIOHEN,

            hal.GPIOM => {
                const ret = hal.HAL_PWREx_EnableUSBVoltageDetector();
                if (ret != hal.HAL_OK) {
                    @panic("Could not enable USB voltage detector");
                }
                RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIOMEN;
            },

            hal.GPION => RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIONEN,

            hal.GPIOO => {
                hal.HAL_PWREx_EnableXSPIM1();
                RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIOOEN;
            },

            hal.GPIOP => RCC.AHB4ENR |= hal.RCC_AHB4ENR_GPIOPEN,

            else => @panic("Unknown GPIO port")
        }

        tmpreg.* = RCC.AHB4ENR;
    }

    /// Initialize a pin as output
    pub fn init_out(self: Pin) void {
        self.enable();

        const GPIO_InitStruct: hal.GPIO_InitTypeDef = hal.GPIO_InitTypeDef{
            .Pin = self.pin,
            .Mode = hal.GPIO_MODE_OUTPUT_PP,
            .Pull = hal.GPIO_NOPULL,
            .Speed = hal.GPIO_SPEED_FREQ_LOW,
        };
        hal.HAL_GPIO_Init(self.port, &GPIO_InitStruct);

        hal.HAL_GPIO_WritePin(self.port, self.pin, hal.GPIO_PIN_RESET);
    }

    /// Change the value of an output pin
    pub fn toggle(self: Pin) void {
        hal.HAL_GPIO_TogglePin(self.port, self.pin);
    }
};

/// All the LEDs available in the board, by order (first one is labeled as 1 in PCB)
pub const LEDS: [4]Pin = .{
    Pin{
        .port = hal.GPIOO,
        .pin = hal.GPIO_PIN_1,
    },
    Pin{
        .port = hal.GPIOO,
        .pin = hal.GPIO_PIN_5,
    },
    Pin {
        .port = hal.GPIOM,
        .pin = hal.GPIO_PIN_2,
    },
    Pin {
        .port = hal.GPIOM,
        .pin = hal.GPIO_PIN_3,
    },
};
