//! Bootstrap logic to start the program and log its execution
//!
//! This is fed the "actual" logic (bootloader/application) by
//! a module generated on build.zig

const std = @import("std");
const logger = std.log.scoped(.main);

const hal = @import("hal");
const rtt = @import("rtt");
const program = @import("program");

const logging = @import("logging.zig");
const panic_mod = @import("panic.zig");

const VectorTable = @import("vector_table.zig").VectorTable;

// zig std config
pub const std_options: std.Options = .{
    .log_level = .debug,
    .logFn = logging.logFn,
    .log_scope_levels = &.{
        .{
            .scope = .ushell,
            .level = .info,
        },
        .{
            .scope = .fatfs,
            .level = .info,
        },
    },
};
pub const panic = panic_mod.panic;

// app-level config
pub const rtt_channels = rtt.RTT(program.rtt_config);
pub const dummy_cycles_config = program.dummy_cycles_config;

const symbols = struct {
    extern var __stack: anyopaque;

    extern var __bss_start: anyopaque;
    extern var __bss_end: anyopaque;

    // RAM to be filled
    extern var __data_start: anyopaque;
    extern var __data_end: anyopaque;

    // contents in flash, to be copied in RAM
    extern var __data_source: anyopaque;
};

fn deadlock() noreturn {
    while (true) {
        @breakpoint();
    }
}

/// Entrypoint of the program (Reset_Handler in interrupt table).
///
/// It sets up the data sections in RAM, to then execute the program.
pub export fn _start() noreturn {
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

    rtt_channels.init();
    hal.zig.init();

    const ret = program.main() catch |main_err| {
        logger.err("returned an error ({s})", .{@errorName(main_err)});

        const maybe_stack_trace: ?*std.builtin.StackTrace = @errorReturnTrace();
        if (maybe_stack_trace) |stack_trace| {
            var frame_index: usize = 0;
            var frames_left: usize = @min(stack_trace.index, stack_trace.instruction_addresses.len);

            while (frames_left != 0) : ({
                frames_left -= 1;
                frame_index = (frame_index + 1) % stack_trace.instruction_addresses.len;
            }) {
                const return_address = stack_trace.instruction_addresses[frame_index];
                logger.err("\t0x{x}", .{return_address});
            }
        }

        deadlock();
    };

    logger.err("exitcode: {}", .{ret});
    deadlock();
}

export const vector_table: VectorTable linksection(".data.init.enter") = .{
    .stack_pointer = &symbols.__stack,
    .Reset = @import("start.zig")._start,
    .SDMMC1 = hal.bsp.sdIsr,
    .TIM6 = hal.zig.timer.isr,
};
