//! Bootstrap logic to start the program and log its execution
//!
//! This is fed the "actual" logic (bootloader/application) by
//! a module generated on build.zig

const std = @import("std");
const hal = @import("hal");
const app = @import("application");

// zig std config
pub const std_options = .{
    .log_level = .debug,
    .logFn = @import("logging").logFn,
};
pub const panic = @import("panic.zig").panic;

comptime {
    _ = @import("vector_table.zig");
}

const symbols = struct {
    extern var __bss_start: u8;
    extern var __bss_end: u8;

    // RAM to be filled
    extern var __data_start: u8;
    extern var __data_end: u8;

    // contents in flash, to be copied in RAM
    extern var __data_source: u8;
};

/// Entrypoint of the program (Reset_Handler in interrupt table).
///
/// It sets up the data sections in RAM, to then execute the program.
pub export fn _start() callconv(.C) noreturn {
    // fill BSS with zero
    const bss_start: [*]u8 = @ptrCast(&symbols.__bss_start);
    const bss_end: [*]u8 = @ptrCast(&symbols.__bss_end);
    const bss_len = @intFromPtr(bss_end) - @intFromPtr(bss_start);
    @memset(bss_start[0..bss_len], 0);

    // load data from flash
    const data_start: [*]u8 = @ptrCast(&symbols.__data_start);
    const data_end: [*]u8 = @ptrCast(&symbols.__data_end);
    const data_len = @intFromPtr(data_end) - @intFromPtr(data_start);
    const data_src: [*]const u8 = @ptrCast(&symbols.__data_source);
    @memcpy(data_start[0..data_len], data_src[0..data_len]);

    // halts, apparently, right after executing the func
    // hal.zig.cache.i_cache.enable();

    hal.zig.init();

    // warning if SD not available
    if (!hal.zig.sd.is_connected()) {
        std.log.warn("404 SD not found", .{});
    }

    const ret = app.run() catch |main_err| {
        if (@errorReturnTrace()) |stack_trace| {
            var frame_index: usize = 0;
            var frames_left: usize = @min(stack_trace.index, stack_trace.instruction_addresses.len);

            std.log.err("Stack trace:", .{});
            while (frames_left != 0) : ({
                frames_left -= 1;
                frame_index = (frame_index + 1) % stack_trace.instruction_addresses.len;
            }) {
                const return_address = stack_trace.instruction_addresses[frame_index];
                std.log.err("0x{x}", .{return_address});
            }
        }

        std.debug.panic("main returned an error ({s})", .{@errorName(main_err)});
    };

    std.debug.panic("main's exitcode: {}. hint: it should never exit...", .{ret});
}
