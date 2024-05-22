//! Convenience namespace to import all "modules", they are the zig equivalent of CubeMX-generated code

pub const clock_config = @import("init/clock_config.zig").init;
pub const gpio = @import("init/gpio.zig").init;
pub const xspi1 = @import("init/xspi1.zig").init;
pub const xspi2 = @import("init/xspi2.zig").init;
