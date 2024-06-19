//! Aliases for STM32H7S78-DK board

const hal = @import("../hal.zig");
const Pin = hal.zig.BasePin;

pub const DCMI = struct {
    pub const HSYNC = Pin{
        .pin = hal.c.GPIO_PIN_3,
        .port = hal.c.GPIOG,
    };

    pub const VSYNC = Pin{
        .pin = hal.c.GPIO_PIN_7,
        .port = hal.c.GPIOB,
    };

    pub const PIXCLK = Pin{
        .pin = hal.c.GPIO_PIN_5,
        .port = hal.c.GPIOD,
    };

    pub const D0 = Pin{
        .pin = hal.c.GPIO_PIN_6,
        .port = hal.c.GPIOC,
    };

    pub const D1 = Pin{
        .pin = hal.c.GPIO_PIN_7,
        .port = hal.c.GPIOC,
    };

    pub const D2 = Pin{
        .pin = hal.c.GPIO_PIN_0,
        .port = hal.c.GPIOE,
    };

    pub const D3 = Pin{
        .pin = hal.c.GPIO_PIN_1,
        .port = hal.c.GPIOE,
    };

    pub const D4 = Pin{
        .pin = hal.c.GPIO_PIN_4,
        .port = hal.c.GPIOE,
    };

    pub const D5 = Pin{
        .pin = hal.c.GPIO_PIN_3,
        .port = hal.c.GPIOD,
    };

    pub const D6 = Pin{
        .pin = hal.c.GPIO_PIN_8,
        .port = hal.c.GPIOB,
    };

    pub const D7 = Pin{
        .pin = hal.c.GPIO_PIN_14,
        .port = hal.c.GPIOD,
    };
};

pub const DEBUG = struct {
    pub const SWCLK = Pin{
        .pin = hal.c.GPIO_PIN_14,
        .port = hal.c.GPIOA,
    };

    pub const SWDIO = Pin{
        .pin = hal.c.GPIO_PIN_13,
        .port = hal.c.GPIOA,
    };
};

pub const HXSPI = struct {
    pub const DQS0 = Pin{
        .pin = hal.c.GPIO_PIN_2,
        .port = hal.c.GPIOO,
    };

    pub const DQS1 = Pin{
        .pin = hal.c.GPIO_PIN_3,
        .port = hal.c.GPIOO,
    };

    pub const CLK = Pin{
        .pin = hal.c.GPIO_PIN_4,
        .port = hal.c.GPIOO,
    };

    pub const IO0 = Pin{
        .pin = hal.c.GPIO_PIN_0,
        .port = hal.c.GPIOP,
    };

    pub const IO1 = Pin{
        .pin = hal.c.GPIO_PIN_1,
        .port = hal.c.GPIOP,
    };

    pub const IO2 = Pin{
        .pin = hal.c.GPIO_PIN_2,
        .port = hal.c.GPIOP,
    };

    pub const IO3 = Pin{
        .pin = hal.c.GPIO_PIN_3,
        .port = hal.c.GPIOP,
    };

    pub const IO4 = Pin{
        .pin = hal.c.GPIO_PIN_4,
        .port = hal.c.GPIOP,
    };

    pub const IO5 = Pin{
        .pin = hal.c.GPIO_PIN_5,
        .port = hal.c.GPIOP,
    };

    pub const IO6 = Pin{
        .pin = hal.c.GPIO_PIN_6,
        .port = hal.c.GPIOP,
    };

    pub const IO7 = Pin{
        .pin = hal.c.GPIO_PIN_7,
        .port = hal.c.GPIOP,
    };

    pub const IO8 = Pin{
        .pin = hal.c.GPIO_PIN_8,
        .port = hal.c.GPIOP,
    };

    pub const IO9 = Pin{
        .pin = hal.c.GPIO_PIN_9,
        .port = hal.c.GPIOP,
    };

    pub const IO10 = Pin{
        .pin = hal.c.GPIO_PIN_10,
        .port = hal.c.GPIOP,
    };

    pub const IO11 = Pin{
        .pin = hal.c.GPIO_PIN_11,
        .port = hal.c.GPIOP,
    };

    pub const IO12 = Pin{
        .pin = hal.c.GPIO_PIN_12,
        .port = hal.c.GPIOP,
    };

    pub const IO13 = Pin{
        .pin = hal.c.GPIO_PIN_13,
        .port = hal.c.GPIOP,
    };

    pub const IO14 = Pin{
        .pin = hal.c.GPIO_PIN_14,
        .port = hal.c.GPIOP,
    };

    pub const IO15 = Pin{
        .pin = hal.c.GPIO_PIN_15,
        .port = hal.c.GPIOP,
    };
};

pub const I2C1 = struct {
    pub const SDA = Pin{
        .pin = hal.c.GPIO_PIN_9,
        .port = hal.c.GPIOB,
    };

    pub const SCL = Pin{
        .pin = hal.c.GPIO_PIN_6,
        .port = hal.c.GPIOB,
    };
};

pub const I2S = struct {
    pub const SDO = Pin{
        .pin = hal.c.GPIO_PIN_5,
        .port = hal.c.GPIOB,
    };

    pub const MCK = Pin{
        .pin = hal.c.GPIO_PIN_3,
        .port = hal.c.GPIOA,
    };

    pub const CK = Pin{
        .pin = hal.c.GPIO_PIN_5,
        .port = hal.c.GPIOA,
    };

    pub const WS = Pin{
        .pin = hal.c.GPIO_PIN_4,
        .port = hal.c.GPIOA,
    };

    pub const SDI = Pin{
        .pin = hal.c.GPIO_PIN_12,
        .port = hal.c.GPIOG,
    };
};

pub const LCD = struct {
    pub const DE = struct {
        .pin = hal.c.GPIO_PIN_14,
        .port = hal.c.GPIOB,
    };

    pub const HSYNC = struct {
        .pin = hal.c.GPIO_PIN_2,
        .port = hal.c.GPIOG,
    };

    pub const VSYNC = struct {
        .pin = hal.c.GPIO_PIN_11,
        .port = hal.c.GPIOE,
    };

    pub const CLK = struct {
        .pin = hal.c.GPIO_PIN_13,
        .port = hal.c.GPIOG,
    };

    pub const R0 = struct {
        .pin = hal.c.GPIO_PIN_9,
        .port = hal.c.GPIOF,
    };

    pub const R1 = struct {
        .pin = hal.c.GPIO_PIN_10,
        .port = hal.c.GPIOF,
    };

    pub const R2 = struct {
        .pin = hal.c.GPIO_PIN_0,
        .port = hal.c.GPIOF,
    };

    pub const R3 = struct {
        .pin = hal.c.GPIO_PIN_4,
        .port = hal.c.GPIOB,
    };

    pub const R4 = struct {
        .pin = hal.c.GPIO_PIN_3,
        .port = hal.c.GPIOB,
    };

    pub const R5 = struct {
        .pin = hal.c.GPIO_PIN_15,
        .port = hal.c.GPIOA,
    };

    pub const R6 = struct {
        .pin = hal.c.GPIO_PIN_1,
        .port = hal.c.GPIOG,
    };

    pub const R7 = struct {
        .pin = hal.c.GPIO_PIN_0,
        .port = hal.c.GPIOG,
    };

    pub const G0 = Pin{
        .pin = hal.c.GPIO_PIN_7,
        .port = hal.c.GPIOF,
    };

    pub const G1 = Pin{
        .pin = hal.c.GPIO_PIN_15,
        .port = hal.c.GPIOF,
    };

    pub const G2 = Pin{
        .pin = hal.c.GPIO_PIN_1,
        .port = hal.c.GPIOA,
    };

    pub const G3 = Pin{
        .pin = hal.c.GPIO_PIN_0,
        .port = hal.c.GPIOA,
    };

    pub const G4 = Pin{
        .pin = hal.c.GPIO_PIN_13,
        .port = hal.c.GPIOB,
    };

    pub const G5 = Pin{
        .pin = hal.c.GPIO_PIN_12,
        .port = hal.c.GPIOB,
    };

    pub const G6 = Pin{
        .pin = hal.c.GPIO_PIN_11,
        .port = hal.c.GPIOB,
    };

    pub const G7 = Pin{
        .pin = hal.c.GPIO_PIN_15,
        .port = hal.c.GPIOB,
    };

    pub const B0 = Pin{
        .pin = hal.c.GPIO_PIN_11,
        .port = hal.c.GPIOF,
    };

    pub const B1 = Pin{
        .pin = hal.c.GPIO_PIN_14,
        .port = hal.c.GPIOG,
    };

    pub const B2 = Pin{
        .pin = hal.c.GPIO_PIN_12,
        .port = hal.c.GPIOA,
    };

    pub const B3 = Pin{
        .pin = hal.c.GPIO_PIN_11,
        .port = hal.c.GPIOA,
    };

    pub const B4 = Pin{
        .pin = hal.c.GPIO_PIN_10,
        .port = hal.c.GPIOA,
    };

    pub const B5 = Pin{
        .pin = hal.c.GPIO_PIN_9,
        .port = hal.c.GPIOA,
    };

    pub const B6 = Pin{
        .pin = hal.c.GPIO_PIN_8,
        .port = hal.c.GPIOA,
    };

    pub const B7 = Pin{
        .pin = hal.c.GPIO_PIN_6,
        .port = hal.c.GPIOA,
    };
};

pub const MIC = struct {
    pub const CK = Pin{
        .pin = hal.c.GPIO_PIN_2,
        .port = hal.c.GPIOE,
    };

    pub const DET = Pin{
        .pin = hal.c.GPIO_PIN_1,
        .port = hal.c.GPIOH,
    };
};

pub const OSC_IN = Pin{
    .pin = hal.c.GPIO_PIN_0,
    .port = hal.c.GPIOH,
};

pub const OSC32 = struct {
    pub const OUT = Pin{
        .pin = hal.c.GPIO_PIN_15,
        .port = hal.c.GPIOC,
    };

    pub const IN = Pin{
        .pin = hal.c.GPIO_PIN_14,
        .port = hal.c.GPIOC,
    };
};

pub const OSPI = struct {
    pub const DQS = Pin{
        .pin = hal.c.GPIO_PIN_0,
        .port = hal.c.GPION,
    };

    pub const CLK = Pin{
        .pin = hal.c.GPIO_PIN_6,
        .port = hal.c.GPION,
    };

    pub const IO0 = Pin{
        .pin = hal.c.GPIO_PIN_2,
        .port = hal.c.GPION,
    };

    pub const IO1 = Pin{
        .pin = hal.c.GPIO_PIN_3,
        .port = hal.c.GPION,
    };

    pub const IO2 = Pin{
        .pin = hal.c.GPIO_PIN_4,
        .port = hal.c.GPION,
    };

    pub const IO3 = Pin{
        .pin = hal.c.GPIO_PIN_5,
        .port = hal.c.GPION,
    };

    pub const IO4 = Pin{
        .pin = hal.c.GPIO_PIN_8,
        .port = hal.c.GPION,
    };

    pub const IO5 = Pin{
        .pin = hal.c.GPIO_PIN_9,
        .port = hal.c.GPION,
    };

    pub const IO6 = Pin{
        .pin = hal.c.GPIO_PIN_10,
        .port = hal.c.GPION,
    };

    pub const IO7 = Pin{
        .pin = hal.c.GPIO_PIN_11,
        .port = hal.c.GPION,
    };
};

pub const RMII = struct {
    pub const TX_EN = Pin{
        .pin = hal.c.GPIO_PIN_11,
        .port = hal.c.GPIOG,
    };

    pub const MDC = Pin{
        .pin = hal.c.GPIO_PIN_1,
        .port = hal.c.GPIOC,
    };

    pub const MDIO = Pin{
        .pin = hal.c.GPIO_PIN_2,
        .port = hal.c.GPIOA,
    };

    pub const RXD0 = Pin{
        .pin = hal.c.GPIO_PIN_4,
        .port = hal.c.GPIOC,
    };

    pub const CRS_DV = Pin{
        .pin = hal.c.GPIO_PIN_7,
        .port = hal.c.GPIOA,
    };

    pub const RXD1 = Pin{
        .pin = hal.c.GPIO_PIN_5,
        .port = hal.c.GPIOC,
    };

    pub const TXD0 = Pin{
        .pin = hal.c.GPIO_PIN_0,
        .port = hal.c.GPIOB,
    };

    pub const RX_ER = Pin{
        .pin = hal.c.GPIO_PIN_10,
        .port = hal.c.GPIOB,
    };

    pub const TXD1 = Pin{
        .pin = hal.c.GPIO_PIN_1,
        .port = hal.c.GPIOB,
    };

    pub const REF_CLK = Pin{
        .pin = hal.c.GPIO_PIN_7,
        .port = hal.c.GPIOD,
    };
};

pub const SD = struct {
    pub const CMD = Pin{
        .pin = hal.c.GPIO_PIN_2,
        .port = hal.c.GPIOD,
    };

    pub const CK = Pin{
        .pin = hal.c.GPIO_PIN_12,
        .port = hal.c.GPIOC,
    };

    pub const D0 = Pin{
        .pin = hal.c.GPIO_PIN_8,
        .port = hal.c.GPIOC,
    };

    pub const D1 = Pin{
        .pin = hal.c.GPIO_PIN_9,
        .port = hal.c.GPIOC,
    };

    pub const D2 = Pin{
        .pin = hal.c.GPIO_PIN_10,
        .port = hal.c.GPIOC,
    };

    pub const D3 = Pin{
        .pin = hal.c.GPIO_PIN_11,
        .port = hal.c.GPIOC,
    };
};

pub const SPI = struct {
    pub const CLK = Pin{
        .pin = hal.c.GPIO_PIN_12,
        .port = hal.c.GPIOE,
    };

    pub const MISO = Pin{
        .pin = hal.c.GPIO_PIN_13,
        .port = hal.c.GPIOE,
    };

    pub const MOSI = Pin{
        .pin = hal.c.GPIO_PIN_6,
        .port = hal.c.GPIOE,
    };
};

pub const UCPD1 = struct {
    pub const CC1 = Pin{
        .pin = hal.c.GPIO_PIN_0,
        .port = hal.c.GPIOM,
    };

    pub const CC2 = Pin{
        .pin = hal.c.GPIO_PIN_1,
        .port = hal.c.GPIOM,
    };

    pub const VSENSE = Pin{
        .pin = hal.c.GPIO_PIN_14,
        .port = hal.c.GPIOF,
    };

    pub const ISENSE = Pin{
        .pin = hal.c.GPIO_PIN_12,
        .port = hal.c.GPIOF,
    };
};

pub const USB1 = struct {
    pub const HS_P = Pin{
        .pin = hal.c.GPIO_PIN_6,
        .port = hal.c.GPIOM,
    };

    pub const HS_N = Pin{
        .pin = hal.c.GPIO_PIN_5,
        .port = hal.c.GPIOM,
    };
};

pub const USB2 = struct {
    pub const FS_N = Pin{
        .pin = hal.c.GPIO_PIN_12,
        .port = hal.c.GPIOM,
    };

    pub const FS_P = Pin{
        .pin = hal.c.GPIO_PIN_11,
        .port = hal.c.GPIOM,
    };
};

pub const VCP = struct {
    pub const TX = Pin{
        .pin = hal.c.GPIO_PIN_1,
        .port = hal.c.GPIOD,
    };

    pub const RX = Pin{
        .pin = hal.c.GPIO_PIN_0,
        .port = hal.c.GPIOD,
    };
};

pub const BUTTON = Pin{
    .pin = hal.c.GPIO_PIN_13,
    .port = hal.c.GPIOC,
};

pub const LEDS = .{
    Pin{
        .pin = hal.c.GPIO_PIN_1,
        .port = hal.c.GPIOO,
    },

    Pin{
        .pin = hal.c.GPIO_PIN_5,
        .port = hal.c.GPIOO,
    },

    Pin{
        .pin = hal.c.GPIO_PIN_2,
        .port = hal.c.GPIOM,
    },

    Pin{
        .pin = hal.c.GPIO_PIN_3,
        .port = hal.c.GPIOM,
    },
};