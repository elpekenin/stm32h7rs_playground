//! Import the C code used by the project, and do so a single time.
//!
//! Also provide some zig wrappers on top of it

/// Raw C code from STM
pub const c = @cImport({
    @cInclude("dk_pins.h"); // pin names exported by CubeMX
    @cInclude("stm32h7rsxx_hal.h");
    @cInclude("stm32h7rsxx_hal_conf.h");
});

/// "Tiny" zig wrappers on top
pub const zig = @import("hal_wrappers.zig");
