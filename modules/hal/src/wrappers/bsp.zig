//! Aliases for STM32H7S78-DK board

const std = @import("std");
const hal = @import("../hal.zig");
const c = hal.c;

const Pin = hal.zig.Pin;
const DigitalIn = hal.zig.DigitalIn;
const DigitalOut = hal.zig.DigitalOut;

pub const DCMI = struct {
    pub const HSYNC: Pin = .{
        .pin = c.GPIO_PIN_3,
        .port = c.GPIOG,
    };

    pub const VSYNC: Pin = .{
        .pin = c.GPIO_PIN_7,
        .port = c.GPIOB,
    };

    pub const PIXCLK: Pin = .{
        .pin = c.GPIO_PIN_5,
        .port = c.GPIOD,
    };

    pub const D0: Pin = .{
        .pin = c.GPIO_PIN_6,
        .port = c.GPIOC,
    };

    pub const D1: Pin = .{
        .pin = c.GPIO_PIN_7,
        .port = c.GPIOC,
    };

    pub const D2: Pin = .{
        .pin = c.GPIO_PIN_0,
        .port = c.GPIOE,
    };

    pub const D3: Pin = .{
        .pin = c.GPIO_PIN_1,
        .port = c.GPIOE,
    };

    pub const D4: Pin = .{
        .pin = c.GPIO_PIN_4,
        .port = c.GPIOE,
    };

    pub const D5: Pin = .{
        .pin = c.GPIO_PIN_3,
        .port = c.GPIOD,
    };

    pub const D6: Pin = .{
        .pin = c.GPIO_PIN_8,
        .port = c.GPIOB,
    };

    pub const D7: Pin = .{
        .pin = c.GPIO_PIN_14,
        .port = c.GPIOD,
    };
};

pub const DEBUG = struct {
    pub const SWCLK: Pin = .{
        .pin = c.GPIO_PIN_14,
        .port = c.GPIOA,
    };

    pub const SWDIO: Pin = .{
        .pin = c.GPIO_PIN_13,
        .port = c.GPIOA,
    };
};

pub const HXSPI = struct {
    pub const DQS0: Pin = .{
        .pin = c.GPIO_PIN_2,
        .port = c.GPIOO,
    };

    pub const DQS1: Pin = .{
        .pin = c.GPIO_PIN_3,
        .port = c.GPIOO,
    };

    pub const CLK: Pin = .{
        .pin = c.GPIO_PIN_4,
        .port = c.GPIOO,
    };

    pub const IO0: Pin = .{
        .pin = c.GPIO_PIN_0,
        .port = c.GPIOP,
    };

    pub const IO1: Pin = .{
        .pin = c.GPIO_PIN_1,
        .port = c.GPIOP,
    };

    pub const IO2: Pin = .{
        .pin = c.GPIO_PIN_2,
        .port = c.GPIOP,
    };

    pub const IO3: Pin = .{
        .pin = c.GPIO_PIN_3,
        .port = c.GPIOP,
    };

    pub const IO4: Pin = .{
        .pin = c.GPIO_PIN_4,
        .port = c.GPIOP,
    };

    pub const IO5: Pin = .{
        .pin = c.GPIO_PIN_5,
        .port = c.GPIOP,
    };

    pub const IO6: Pin = .{
        .pin = c.GPIO_PIN_6,
        .port = c.GPIOP,
    };

    pub const IO7: Pin = .{
        .pin = c.GPIO_PIN_7,
        .port = c.GPIOP,
    };

    pub const IO8: Pin = .{
        .pin = c.GPIO_PIN_8,
        .port = c.GPIOP,
    };

    pub const IO9: Pin = .{
        .pin = c.GPIO_PIN_9,
        .port = c.GPIOP,
    };

    pub const IO10: Pin = .{
        .pin = c.GPIO_PIN_10,
        .port = c.GPIOP,
    };

    pub const IO11: Pin = .{
        .pin = c.GPIO_PIN_11,
        .port = c.GPIOP,
    };

    pub const IO12: Pin = .{
        .pin = c.GPIO_PIN_12,
        .port = c.GPIOP,
    };

    pub const IO13: Pin = .{
        .pin = c.GPIO_PIN_13,
        .port = c.GPIOP,
    };

    pub const IO14: Pin = .{
        .pin = c.GPIO_PIN_14,
        .port = c.GPIOP,
    };

    pub const IO15: Pin = .{
        .pin = c.GPIO_PIN_15,
        .port = c.GPIOP,
    };
};

pub const I2C1 = struct {
    pub const SDA: Pin = .{
        .pin = c.GPIO_PIN_9,
        .port = c.GPIOB,
    };

    pub const SCL: Pin = .{
        .pin = c.GPIO_PIN_6,
        .port = c.GPIOB,
    };
};

pub const I2S = struct {
    pub const SDO: Pin = .{
        .pin = c.GPIO_PIN_5,
        .port = c.GPIOB,
    };

    pub const MCK: Pin = .{
        .pin = c.GPIO_PIN_3,
        .port = c.GPIOA,
    };

    pub const CK: Pin = .{
        .pin = c.GPIO_PIN_5,
        .port = c.GPIOA,
    };

    pub const WS: Pin = .{
        .pin = c.GPIO_PIN_4,
        .port = c.GPIOA,
    };

    pub const SDI: Pin = .{
        .pin = c.GPIO_PIN_12,
        .port = c.GPIOG,
    };
};

pub const LCD = struct {
    pub const DE: Pin = .{
        .pin = c.GPIO_PIN_14,
        .port = c.GPIOB,
    };

    pub const HSYNC: Pin = .{
        .pin = c.GPIO_PIN_2,
        .port = c.GPIOG,
    };

    pub const VSYNC: Pin = .{
        .pin = c.GPIO_PIN_11,
        .port = c.GPIOE,
    };

    pub const CLK: Pin = .{
        .pin = c.GPIO_PIN_13,
        .port = c.GPIOG,
    };

    pub const R0: Pin = .{
        .pin = c.GPIO_PIN_9,
        .port = c.GPIOF,
    };

    pub const R1: Pin = .{
        .pin = c.GPIO_PIN_10,
        .port = c.GPIOF,
    };

    pub const R2: Pin = .{
        .pin = c.GPIO_PIN_0,
        .port = c.GPIOF,
    };

    pub const R3: Pin = .{
        .pin = c.GPIO_PIN_4,
        .port = c.GPIOB,
    };

    pub const R4: Pin = .{
        .pin = c.GPIO_PIN_3,
        .port = c.GPIOB,
    };

    pub const R5: Pin = .{
        .pin = c.GPIO_PIN_15,
        .port = c.GPIOA,
    };

    pub const R6: Pin = .{
        .pin = c.GPIO_PIN_1,
        .port = c.GPIOG,
    };

    pub const R7: Pin = .{
        .pin = c.GPIO_PIN_0,
        .port = c.GPIOG,
    };

    pub const G0: Pin = .{
        .pin = c.GPIO_PIN_7,
        .port = c.GPIOF,
    };

    pub const G1: Pin = .{
        .pin = c.GPIO_PIN_15,
        .port = c.GPIOF,
    };

    pub const G2: Pin = .{
        .pin = c.GPIO_PIN_1,
        .port = c.GPIOA,
    };

    pub const G3: Pin = .{
        .pin = c.GPIO_PIN_0,
        .port = c.GPIOA,
    };

    pub const G4: Pin = .{
        .pin = c.GPIO_PIN_13,
        .port = c.GPIOB,
    };

    pub const G5: Pin = .{
        .pin = c.GPIO_PIN_12,
        .port = c.GPIOB,
    };

    pub const G6: Pin = .{
        .pin = c.GPIO_PIN_11,
        .port = c.GPIOB,
    };

    pub const G7: Pin = .{
        .pin = c.GPIO_PIN_15,
        .port = c.GPIOB,
    };

    pub const B0: Pin = .{
        .pin = c.GPIO_PIN_11,
        .port = c.GPIOF,
    };

    pub const B1: Pin = .{
        .pin = c.GPIO_PIN_14,
        .port = c.GPIOG,
    };

    pub const B2: Pin = .{
        .pin = c.GPIO_PIN_12,
        .port = c.GPIOA,
    };

    pub const B3: Pin = .{
        .pin = c.GPIO_PIN_11,
        .port = c.GPIOA,
    };

    pub const B4: Pin = .{
        .pin = c.GPIO_PIN_10,
        .port = c.GPIOA,
    };

    pub const B5: Pin = .{
        .pin = c.GPIO_PIN_9,
        .port = c.GPIOA,
    };

    pub const B6: Pin = .{
        .pin = c.GPIO_PIN_8,
        .port = c.GPIOA,
    };

    pub const B7: Pin = .{
        .pin = c.GPIO_PIN_6,
        .port = c.GPIOA,
    };
};

pub const MIC = struct {
    pub const CK: Pin = .{
        .pin = c.GPIO_PIN_2,
        .port = c.GPIOE,
    };

    pub const DET: Pin = .{
        .pin = c.GPIO_PIN_1,
        .port = c.GPIOH,
    };
};

pub const OSC_IN: Pin = .{
    .pin = c.GPIO_PIN_0,
    .port = c.GPIOH,
};

pub const OSC32 = struct {
    pub const OUT: Pin = .{
        .pin = c.GPIO_PIN_15,
        .port = c.GPIOC,
    };

    pub const IN: Pin = .{
        .pin = c.GPIO_PIN_14,
        .port = c.GPIOC,
    };
};

pub const OSPI = struct {
    pub const CS: Pin = .{
        .pin = c.GPIO_PIN_1,
        .port = c.GPION,
    };

    pub const DQS: Pin = .{
        .pin = c.GPIO_PIN_0,
        .port = c.GPION,
    };

    pub const CLK: Pin = .{
        .pin = c.GPIO_PIN_6,
        .port = c.GPION,
    };

    pub const IO0: Pin = .{
        .pin = c.GPIO_PIN_2,
        .port = c.GPION,
    };

    pub const IO1: Pin = .{
        .pin = c.GPIO_PIN_3,
        .port = c.GPION,
    };

    pub const IO2: Pin = .{
        .pin = c.GPIO_PIN_4,
        .port = c.GPION,
    };

    pub const IO3: Pin = .{
        .pin = c.GPIO_PIN_5,
        .port = c.GPION,
    };

    pub const IO4: Pin = .{
        .pin = c.GPIO_PIN_8,
        .port = c.GPION,
    };

    pub const IO5: Pin = .{
        .pin = c.GPIO_PIN_9,
        .port = c.GPION,
    };

    pub const IO6: Pin = .{
        .pin = c.GPIO_PIN_10,
        .port = c.GPION,
    };

    pub const IO7: Pin = .{
        .pin = c.GPIO_PIN_11,
        .port = c.GPION,
    };

    fn init() void {
        var config: Pin.Config = .{
            .mode = c.GPIO_MODE_AF_PP,
            .pull = c.GPIO_PULLUP,
            .speed = c.GPIO_SPEED_FREQ_VERY_HIGH,
            .alternate = c.GPIO_AF9_XSPIM_P2,
        };

        CS.init(config);
        DQS.init(config);

        config.pull = c.GPIO_NOPULL;
        CLK.init(config);

        inline for (.{ IO0, IO1, IO2, IO3, IO4, IO5, IO6, IO7 }) |pin| {
            pin.init(config);
        }
    }
};

pub const RMII = struct {
    pub const TX_EN: Pin = .{
        .pin = c.GPIO_PIN_11,
        .port = c.GPIOG,
    };

    pub const MDC: Pin = .{
        .pin = c.GPIO_PIN_1,
        .port = c.GPIOC,
    };

    pub const MDIO: Pin = .{
        .pin = c.GPIO_PIN_2,
        .port = c.GPIOA,
    };

    pub const RXD0: Pin = .{
        .pin = c.GPIO_PIN_4,
        .port = c.GPIOC,
    };

    pub const CRS_DV: Pin = .{
        .pin = c.GPIO_PIN_7,
        .port = c.GPIOA,
    };

    pub const RXD1: Pin = .{
        .pin = c.GPIO_PIN_5,
        .port = c.GPIOC,
    };

    pub const TXD0: Pin = .{
        .pin = c.GPIO_PIN_0,
        .port = c.GPIOB,
    };

    pub const RX_ER: Pin = .{
        .pin = c.GPIO_PIN_10,
        .port = c.GPIOB,
    };

    pub const TXD1: Pin = .{
        .pin = c.GPIO_PIN_1,
        .port = c.GPIOB,
    };

    pub const REF_CLK: Pin = .{
        .pin = c.GPIO_PIN_7,
        .port = c.GPIOD,
    };
};

pub const SD = struct {
    /// SD detection pin, low == connected
    pub const DET = DigitalIn{
        .base = .{
            .port = c.GPIOM,
            .pin = c.GPIO_PIN_14,
        },
        .active = .Low,
    };

    pub const CMD: Pin = .{
        .pin = c.GPIO_PIN_2,
        .port = c.GPIOD,
    };

    pub const CK: Pin = .{
        .pin = c.GPIO_PIN_12,
        .port = c.GPIOC,
    };

    pub const D0: Pin = .{
        .pin = c.GPIO_PIN_8,
        .port = c.GPIOC,
    };

    pub const D1: Pin = .{
        .pin = c.GPIO_PIN_9,
        .port = c.GPIOC,
    };

    pub const D2: Pin = .{
        .pin = c.GPIO_PIN_10,
        .port = c.GPIOC,
    };

    pub const D3: Pin = .{
        .pin = c.GPIO_PIN_11,
        .port = c.GPIOC,
    };
};

pub const SPI = struct {
    pub const CLK: Pin = .{
        .pin = c.GPIO_PIN_12,
        .port = c.GPIOE,
    };

    pub const MISO: Pin = .{
        .pin = c.GPIO_PIN_13,
        .port = c.GPIOE,
    };

    pub const MOSI: Pin = .{
        .pin = c.GPIO_PIN_6,
        .port = c.GPIOE,
    };
};

pub const UCPD1 = struct {
    pub const CC1: Pin = .{
        .pin = c.GPIO_PIN_0,
        .port = c.GPIOM,
    };

    pub const CC2: Pin = .{
        .pin = c.GPIO_PIN_1,
        .port = c.GPIOM,
    };

    pub const VSENSE: Pin = .{
        .pin = c.GPIO_PIN_14,
        .port = c.GPIOF,
    };

    pub const ISENSE: Pin = .{
        .pin = c.GPIO_PIN_12,
        .port = c.GPIOF,
    };
};

pub const USB1 = struct {
    pub const HS_P: Pin = .{
        .pin = c.GPIO_PIN_6,
        .port = c.GPIOM,
    };

    pub const HS_N: Pin = .{
        .pin = c.GPIO_PIN_5,
        .port = c.GPIOM,
    };
};

pub const USB2 = struct {
    pub const FS_N: Pin = .{
        .pin = c.GPIO_PIN_12,
        .port = c.GPIOM,
    };

    pub const FS_P: Pin = .{
        .pin = c.GPIO_PIN_11,
        .port = c.GPIOM,
    };
};

pub const VCP = struct {
    pub const TX: Pin = .{
        .pin = c.GPIO_PIN_1,
        .port = c.GPIOD,
    };

    pub const RX: Pin = .{
        .pin = c.GPIO_PIN_0,
        .port = c.GPIOD,
    };
};

pub const BUTTON = DigitalIn{
    .base = .{
        .pin = c.GPIO_PIN_13,
        .port = c.GPIOC,
    },
    .active = .High,
};

pub const LEDS = .{
    DigitalOut{
        .base = .{
            .pin = c.GPIO_PIN_1,
            .port = c.GPIOO,
        },
        .active = .High,
    },

    DigitalOut{
        .base = .{
            .pin = c.GPIO_PIN_5,
            .port = c.GPIOO,
        },
        .active = .High,
    },

    DigitalOut{
        .base = .{
            .pin = c.GPIO_PIN_2,
            .port = c.GPIOM,
        },
        .active = .Low,
    },

    DigitalOut{
        .base = .{
            .pin = c.GPIO_PIN_3,
            .port = c.GPIOM,
        },
        .active = .Low,
    },
};

pub fn init() void {
    inline for (.{ SD.DET, BUTTON }) |pin| {
        pin.init();
    }

    inline for (LEDS) |pin| {
        pin.init();
        pin.set(false);
    }

    OSPI.init();
}
