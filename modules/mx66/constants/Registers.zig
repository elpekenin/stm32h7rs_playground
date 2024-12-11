//! Registers in the chip and their possible values

/// Status Register
pub const Status = struct {
    /// Write in progress
    pub const WIP = 0x01;
    /// Write enable latch
    pub const WELL = 0x02;
    /// Block protected against program and erase operations
    pub const PB = 0x3C;
};

/// Configuration Register 1
pub const CR1 = struct {
    /// Output driver strength
    pub const ODS = 0x07;
    /// Top / bottom  selected
    pub const TB = 0x08;
    /// Preamble bit enable
    pub const PBE = 0x10;
};

/// Configuration Register 2
pub const CR2 = struct {
    /// CR2 register address 0x00000000
    pub const REG1 = struct {
        pub const ADDR = 0x00000000;
        /// STR OPI Enable
        pub const SOPI = 0x01;
        /// DTR OPI Enable
        pub const DOPI = 0x02;
    };

    /// CR2 register address 0x00000200
    pub const REG2 = struct {
        pub const ADDR = 0x00000200;
        /// DTR DQS pre-cycle
        pub const DQSPRC = 0x01;
        /// DQS on STR mode
        pub const DOS = 0x02;
    };

    /// CR2 register address 0x00000300
    pub const REG3 = struct {
        pub const ADDR = 0x00000300;
        /// Dummy cycle
        pub const DC = 0x07;
        /// 20 Dummy cycles
        pub const DC_20_CYCLES = 0x00;
        /// 18 Dummy cycles
        pub const DC_18_CYCLES = 0x01;
        /// 16 Dummy cycles
        pub const DC_16_CYCLES = 0x02;
        /// 14 Dummy cycles
        pub const DC_14_CYCLES = 0x03;
        /// 12 Dummy cycles
        pub const DC_12_CYCLES = 0x04;
        /// 10 Dummy cycles
        pub const DC_10_CYCLES = 0x05;
        /// 8 Dummy cycles
        pub const DC_8_CYCLES = 0x06;
        /// 6 Dummy cycles
        pub const DC_6_CYCLES = 0x07;
    };

    /// CR2 register address 0x00000500
    pub const REG4 = struct {
        pub const ADDR = 0x00000500;
        /// Preamble pattern selection
        pub const PPTSEL = 0x01;
    };

    /// CR2 register address 0x40000000
    pub const REG5 = struct {
        pub const ADDR = 0x40000000;
        /// Enable SOPI after power on reset
        pub const DEFSOPI = 0x01;
        /// Enable DOPI after power on reset
        pub const DEFDOPI = 0x02;
    };
};

// Security Register
pub const Security = struct {
    /// Secured OTP indicator
    pub const SECR_SOI = 0x01;
    /// Lock-down secured OTP
    pub const SECR_LDSO = 0x02;
    /// Program suspend bit
    pub const SECR_PSB = 0x04;
    /// Erase suspend bit
    pub const SECR_ESB = 0x08;
    /// Program fail flag
    pub const SECR_P_FAIL = 0x20;
    /// Erase fail flag
    pub const SECR_E_FAIL = 0x40;
    /// Write protection selection
    pub const SECR_WPSEL = 0x80;
};
