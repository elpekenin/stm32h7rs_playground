//! Import the C code used by the project, and do so a single time.
//!
//! Also provide some zig wrappers on top of it
//!
//! This module also contains the initialization on main, before jumping to
//! root's logic.

const std = @import("std");

const root = @import("root");

/// Initializations to be run prior to user logic
const init = @import("init.zig");

/// Low-level (de)initialization routines needed/used by STM's HAL
const msp = @import("msp.zig");
// Please zig, do not garbage-collect this, we need it to export C funcs
comptime {
    _ = msp;
}

/// Raw C code from STM
pub const c = @cImport({
    @cInclude("dk_pins.h"); // pin names exported by CubeMX
    @cInclude("stm32h7rsxx_hal.h");
    @cInclude("stm32h7rsxx_hal_conf.h");
});

/// "Tiny" zig wrappers on top
pub const zig = @import("hal_wrappers.zig");

/// Arguments' signature doesn't really matter as picolibc will be
/// doing `int ret = main(0, NULL)`
///
/// But, just for reference, according to C11, `argv` should be a
/// non-const, null-terminated list of null-terminated strings.
///
/// Our main consists on doing some initial setup of HAL compontents to
/// then jump into application code.
export fn main(argc: i32, argv: [*c][*:0]u8) callconv(.C) i32 {
    _ = argc;
    _ = argv;

    const ret = c.HAL_Init();
    if (ret != c.HAL_OK) {
        std.debug.panic("HAL_Init", .{});
    }

    init.clock_config();
    c.SystemCoreClockUpdate();

    init.gpio();
    init.xspi1();
    init.xspi2();

    // Actual entrypoint of the app
    root.run();
}
