//! Logging configuration to be used on both bootloader- and application- level code
//! Thus, broken down into a reusable file under `common/`
//!
//! Note: The root of the project (aka: `app.zig` or `bootloader.zig`) has to import
//! and publicly re-export `std_options`

const std = @import("std");
const build_config = @import("build_config");

pub fn logFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    if (scope == .fatfs and level == .debug) {
        // FatFS is too verbose with debug messages ON, lets ignore them
        return;
    }

    if (build_config.logging.rtt) {
        @import("backends/rtt.zig").log(
            level,
            scope,
            format,
            args,
        );
    }

    if (build_config.logging.filesystem) {
        @import("backends/fs.zig").log(
            level,
            scope,
            format,
            args,
        );
    }
}

/// Name that STM HAL expects to find
export fn assert_failed(file: [*:0]const u8, line: u32) void {
    std.log.err("assert failed {s}:{}", .{ file, line });
}
