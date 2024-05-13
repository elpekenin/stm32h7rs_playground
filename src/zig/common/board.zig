// Constants for DK board peripherals
const hal = @import("hal.zig");

pub const Active = enum {
    Low,
    High,
};

pub const BasePin = struct {
    port: *hal.GPIO_TypeDef,
    pin: u16,

    /// Enable a pin, this is:
    ///   - Enable its clock
    ///   - Give it power (only ports O and M implemented yet)
    fn enable(self: BasePin) void {
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

    fn init(self: BasePin, mode: c_uint, pull: c_uint, speed: c_uint) void {
        self.enable();

        const GPIO_InitStruct: hal.GPIO_InitTypeDef = hal.GPIO_InitTypeDef{
            .Pin = self.pin,
            .Mode = mode,
            .Pull = pull,
            .Speed = speed,
        };

        hal.HAL_GPIO_Init(self.port, &GPIO_InitStruct);
    }

    /// Initialize a pin as output
    pub fn as_out(self: BasePin, active: Active) OutPin {
        const ret = OutPin{
            .base = self,
            .active = active,
        };

        ret.init();

        return ret;
    }

    pub fn as_in(self: BasePin, active: Active) InPin {
        const ret = InPin{
            .base = self,
            .active = active,
        };

        ret.init();

        return ret;
    }
};

pub const OutPin = struct {
    base: BasePin,
    active: Active,

    /// Configure the pin and set it at "off" state
    fn init(self: OutPin) void {
        // TODO?: Something based on `self.active`
        self.base.init(hal.GPIO_MODE_OUTPUT_PP, hal.GPIO_PULLUP, hal.GPIO_SPEED_FREQ_VERY_HIGH);
    }

    /// Set the **logical** output level (according to active-ness)
    pub fn set(self: OutPin, value: bool) void {
        const output = switch (self.active) {
            .Low => !value,
            .High => value,
        };

        const hal_out: c_uint = if (output) hal.GPIO_PIN_SET else hal.GPIO_PIN_RESET;

        hal.HAL_GPIO_WritePin(self.base.port, self.base.pin, hal_out);
    }

    /// Toggle the output voltage
    pub fn toggle(self: OutPin) void {
        hal.HAL_GPIO_TogglePin(self.base.port, self.base.pin);
    }
};

pub const InPin = struct {
    base: BasePin,
    active: Active,

    /// Configure the pin
    fn init(self: InPin) void {
        const hal_pull = switch (self.active) {
            .Low => @panic("Unimplemented"),
            .High => hal.GPIO_PULLDOWN,
        };

        self.base.init(hal.GPIO_MODE_INPUT, hal_pull, hal.GPIO_SPEED_FREQ_LOW);
    }

    /// Read input, takin into account the pull, to return "is button pressed"
    pub fn read(self: InPin) bool {
        return switch (self.active) {
            .Low => @panic("Unimplemented"),
            .High => hal.HAL_GPIO_ReadPin(self.base.port, self.base.pin) == hal.GPIO_PIN_SET,
        };
    }
};

// Button
pub const USER = BasePin{
    .port = hal.GPIOC,
    .pin = hal.GPIO_PIN_13,
};

// LEDs
pub const LD1 = BasePin{
    .port = hal.GPIOO,
    .pin = hal.GPIO_PIN_1,
};

pub const LD2 = BasePin{
    .port = hal.GPIOO,
    .pin = hal.GPIO_PIN_5,
};

pub const LD3 = BasePin{
    .port = hal.GPIOM,
    .pin = hal.GPIO_PIN_2,
};

pub const LD4 = BasePin{
    .port = hal.GPIOM,
    .pin = hal.GPIO_PIN_3,
};

pub const LEDS = .{ LD1, LD2, LD3, LD4 };
