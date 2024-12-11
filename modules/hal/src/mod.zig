//! Import the C code used by the project, and do so a single time.
//!
//! Also provide some zig wrappers on top of it

/// Raw C code from STM
pub const c = @cImport({
    @cInclude("stm32h7rsxx_hal.h");
});

/// "Tiny" zig wrappers on top
pub const zig = @import("wrappers/__init__.zig");

/// Pin names
pub const bsp = @import("wrappers/bsp.zig");

/// TODO: move to its own module (?)
pub const assembly = struct {
    pub fn disableIrq() void {
        asm volatile ("cpsid i" ::: "memory");
    }

    pub fn enableIrq() void {
        asm volatile ("cpsie i" ::: "memory");
    }
};
