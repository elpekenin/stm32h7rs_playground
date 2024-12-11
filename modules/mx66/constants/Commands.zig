//! Commands sent to the chip for various operations

/// SPI-specific commands
pub const SPI = struct {
    /// READ/WRITE MEMORY Operations with 3-Byte Address
    pub const ThreeBytes = struct {
        /// Normal Read 3 Byte Address
        pub const READ = 0x03;
        /// Fast Read 3 Byte Address
        pub const FAST_READ = 0x0B;
        /// Page Program 3 Byte Address
        pub const PAGE_PROG = 0x02;
        /// SubSector Erase 4KB 3 Byte Address
        pub const SECTOR_ERASE_4K = 0x20;
        /// Sector Erase 64KB 3 Byte Address
        pub const BLOCK_ERASE_64K = 0xD8;
        /// Bulk Erase
        pub const BULK_ERASE = 0x60;
    };

    /// READ/WRITE MEMORY Operations with 4-Byte Address
    pub const FourBytes = struct {
        /// Normal Read 4 Byte address
        pub const READ = 0x13;
        /// Fast Read 4 Byte address
        pub const FAST_READ = 0x0C;
        /// Page Program 4 Byte Address
        pub const PAGE_PROG = 0x12;
        /// SubSector Erase 4KB 4 Byte Address
        pub const SECTOR_ERASE_4K = 0x21;
        /// Sector Erase 64KB 4 Byte Address
        pub const BLOCK_ERASE_64K = 0xDC;
    };

    /// Setting commands
    pub const Settings = struct {
        /// Write Enable
        pub const WRITE_ENABLE = 0x06;
        /// Write Disable
        pub const WRITE_DISABLE = 0x04;
        /// Program/Erase suspend
        pub const PROG_ERASE_SUSPEND = 0xB0;
        /// Program/Erase resume
        pub const PROG_ERASE_RESUME = 0x30;
        /// Enter deep power down
        pub const ENTER_DEEP_POWER_DOWN = 0xB9;
        /// Release from deep power down
        pub const RELEASE_DEEP_POWER_DOWN = 0xAB;
        /// Set burst length
        pub const SET_BURST_LENGTH = 0xC0;
        /// Enter secured OTP
        pub const ENTER_SECURED_OTP = 0xB1;
        /// Exit secured OTP
        pub const EXIT_SECURED_OTP = 0xC1;
    };

    /// RESET commands
    pub const Reset = struct {
        /// No operation
        pub const NOP = 0x00;
        /// Reset Enable
        pub const RESET_ENABLE = 0x66;
        /// Reset Memory
        pub const RESET_MEMORY = 0x99;
    };

    /// Register Commands (SPI)
    pub const Register = struct {
        /// Read IDentification
        pub const READ_ID = 0x9F;
        /// Read Serial Flash Discoverable Parameter
        pub const READ_SERIAL_FLASH_DISCO_PARAM = 0x5A;
        /// Read Status Register
        pub const READ_STATUS_REG = 0x05;
        /// Read bus_config Register
        pub const READ_CFG_REG = 0x15;
        /// Write Status Register
        pub const WRITE_STATUS_REG = 0x01;
        /// Read bus_config Register2
        pub const READ_CFG_REG2 = 0x71;
        /// Write bus_config Register2
        pub const WRITE_CFG_REG2 = 0x72;
        /// Read fast boot Register
        pub const READ_FAST_BOOT_REG = 0x16;
        /// Write fast boot Register
        pub const WRITE_FAST_BOOT_REG = 0x17;
        /// Erase fast boot Register
        pub const ERASE_FAST_BOOT_REG = 0x18;
        /// Read security Register
        pub const READ_SECURITY_REG = 0x2B;
        /// Write security Register
        pub const WRITE_SECURITY_REG = 0x2F;
        /// Read lock Register
        pub const READ_LOCK_REG = 0x2D;
        /// Write lock Register
        pub const WRITE_LOCK_REG = 0x2C;
        /// Read DPB register
        pub const READ_DPB_REG = 0xE0;
        /// Write DPB register
        pub const WRITE_DPB_REG = 0xE1;
        /// Read SPB status
        pub const READ_SPB_STATUS = 0xE2;
        /// SPB bit program
        pub const WRITE_SPB_BIT = 0xE3;
        /// Erase all SPB bit
        pub const ERASE_ALL_SPB = 0xE4;
        /// Write Protect selection
        pub const WRITE_PROTECT_SEL = 0x68;
        /// Gang block lock: whole chip write protect
        pub const GANG_BLOCK_LOCK = 0x7E;
        /// Gang block unlock: whole chip write unprotect
        pub const GANG_BLOCK_UNLOCK = 0x98;
        /// Read Password
        pub const READ_PASSWORD_REGISTER = 0x27;
        /// Write Password
        pub const WRITE_PASSWORD_REGISTER = 0x28;
        /// Unlock Password
        pub const PASSWORD_UNLOCK = 0x29;
    };
};

/// OPI-specific commands
pub const OPI = struct {
    /// READ/WRITE MEMORY Operations
    pub const Memory = struct {
        /// Octa IO Read
        pub const READ = 0xEC13;
        /// Octa IO Read DTR
        pub const READ_DTR = 0xEE11;
        /// Octa Page Program
        pub const PAGE_PROG = 0x12ED;
        /// Octa SubSector Erase 4KB
        pub const SECTOR_ERASE_4K = 0x21DE;
        /// Octa Sector Erase 64KB 3
        pub const BLOCK_ERASE_64K = 0xDC23;
        /// Octa Bulk Erase
        pub const BULK_ERASE = 0x609F;
    };

    /// Setting commands
    pub const Settings = struct {
        /// Octa Write Enable
        pub const WRITE_ENABLE = 0x06F9;
        /// Octa Write Disable
        pub const WRITE_DISABLE = 0x04FB;
        /// Octa Program/Erase suspend
        pub const PROG_ERASE_SUSPEND = 0xB04F;
        /// Octa Program/Erase resume
        pub const PROG_ERASE_RESUME = 0x30CF;
        /// Octa Enter deep power down
        pub const ENTER_DEEP_POWER_DOWN = 0xB946;
        /// Octa Release from deep power down
        pub const RELEASE_DEEP_POWER_DOWN = 0xAB54;
        /// Octa Set burst length
        pub const SET_BURST_LENGTH = 0xC03F;
        /// Octa Enter secured OTP
        pub const ENTER_SECURED_OTP = 0xB14E;
        /// Octa Exit secured OTP
        pub const EXIT_SECURED_OTP = 0xC13E;
    };

    /// RESET commands
    pub const Reset = struct {
        /// Octa No operation
        pub const NOP = 0x00FF;
        /// Octa Reset Enable
        pub const RESET_ENABLE = 0x6699;
        /// Octa Reset Memory
        pub const RESET_MEMORY = 0x9966;
    };

    /// Register Commands (OPI)
    pub const Register = struct {
        /// Octa Read IDentification
        pub const READ_ID = 0x9F60;
        /// Octa Read Serial Flash Discoverable Parameter
        pub const READ_SERIAL_FLASH_DISCO_PARAM = 0x5AA5;
        /// Octa Read Status Register
        pub const READ_STATUS_REG = 0x05FA;
        /// Octa Read bus_config Register
        pub const READ_CFG_REG = 0x15EA;
        /// Octa Write Status Register
        pub const WRITE_STATUS_REG = 0x01FE;
        /// Octa Read bus_config Register2
        pub const READ_CFG_REG2 = 0x718E;
        /// Octa Write bus_config Register2
        pub const WRITE_CFG_REG2 = 0x728D;
        /// Octa Read fast boot Register
        pub const READ_FAST_BOOT_REG = 0x16E9;
        /// Octa Write fast boot Register
        pub const WRITE_FAST_BOOT_REG = 0x17E8;
        /// Octa Erase fast boot Register
        pub const ERASE_FAST_BOOT_REG = 0x18E7;
        /// Octa Read security Register
        pub const READ_SECURITY_REG = 0x2BD4;
        /// Octa Write security Register
        pub const WRITE_SECURITY_REG = 0x2FD0;
        /// Octa Read lock Register
        pub const READ_LOCK_REG = 0x2DD2;
        /// Octa Write lock Register
        pub const WRITE_LOCK_REG = 0x2CD3;
        /// Octa Read DPB register
        pub const READ_DPB_REG = 0xE01F;
        /// Octa Write DPB register
        pub const WRITE_DPB_REG = 0xE11E;
        /// Octa Read SPB status
        pub const READ_SPB_STATUS = 0xE21D;
        /// Octa SPB bit program
        pub const WRITE_SPB_BIT = 0xE31C;
        /// Octa Erase all SPB bit
        pub const ERASE_ALL_SPB = 0xE41B;
        /// Octa Write Protect selection
        pub const WRITE_PROTECT_SEL = 0x6897;
        /// Octa Gang block lock: whole chip write protect
        pub const GANG_BLOCK_LOCK = 0x7E81;
        /// Octa Gang block unlock: whole chip write unprote
        pub const GANG_BLOCK_UNLOCK = 0x9867;
        /// Octa Read Password
        pub const READ_PASSWORD_REGISTER = 0x27D8;
        /// Octa Write Password
        pub const WRITE_PASSWORD_REGISTER = 0x28D7;
        /// Octa Unlock Password
        pub const PASSWORD_UNLOCK = 0x29D6;
    };
};
