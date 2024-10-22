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
pub const dk = @import("wrappers/dk_pins.zig");

/// TODO: move to its own module (?)
pub const assembly = struct {
    pub inline fn disable_irq() void {
        asm volatile ("cpsid i" ::: "memory");
    }

    pub inline fn enable_irq() void {
        asm volatile ("cpsie i" ::: "memory");
    }
};
