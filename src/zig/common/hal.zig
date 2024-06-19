//! Import the C code used by the project, and do so a single time.
//!
//! Also provide some zig wrappers on top of it

/// Raw C code from STM
// These `@cDefine` macros are already defined on the build script
// but are also here for better LSP support
pub const c = @cImport({
    @cDefine("__PROGRAM_START", "_start");
    @cDefine("STM32H7S7xx", {});
    @cDefine("USE_HAL_DRIVER", {});
    @cInclude("stm32h7rsxx_hal.h");
    @cInclude("stm32h7rsxx_hal_conf.h");
});

/// "Tiny" zig wrappers on top
pub const zig = @import("hal_wrappers.zig");

/// Pin names
pub const dk = @import("hal_wrappers/dk_pins.zig");
