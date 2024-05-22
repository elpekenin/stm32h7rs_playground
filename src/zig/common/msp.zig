//! Convenience namespace to import all "modules", they are the zig equivalent of CubeMX-generated code

const base = @import("msp/base.zig");
const sd = @import("msp/sd.zig");
const xspi = @import("msp/xspi.zig");

// Please zig, do not garbage-collect this, we need it to export C funcs
comptime {
    _ = base;
    _ = sd;
    _ = xspi;
}
