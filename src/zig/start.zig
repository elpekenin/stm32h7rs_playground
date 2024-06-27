//! Bootstrap logic to start the program and log its execution
//!
//! This is fed the "actual" logic (bootloader/application) by
//! a module generated on build.zig

const std = @import("std");
const hal = @import("hal");
const app = @import("application");
const options = @import("options");

const logging = @import("logging");
pub const std_options = .{
    .log_level = .debug,
    .logFn = logging.logFn,
};

const PanicType = @import("panic_config.zig").PanicType;

pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    @setCold(true);

    std.log.err("Panic: {s}", .{msg});

    // endless rainbow
    const panic_type: PanicType = @enumFromInt(options.panic_type);

    switch (panic_type) {
        .Nothing => while (true) {},
        .LedsOn => {
            inline for (hal.dk.LEDS) |led| {
                led.set(true);
            }

            while (true) {}
        },
        .CycleLeds => {
            inline for (hal.dk.LEDS) |led| {
                led.set(true);
            }

            while (true) {
                inline for (hal.dk.LEDS) |led| {
                    led.toggle();
                    hal.c.HAL_Delay(options.panic_timer);
                }
            }
        },
        .ToggleLeds => {
            inline for (hal.dk.LEDS) |led| {
                led.set(true);
            }

            while (true) {
                inline for (hal.dk.LEDS) |led| {
                    led.toggle();
                }
                hal.c.HAL_Delay(options.panic_timer);
            }
        },
    }
}

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

        std.debug.panic("main's returned an error ({s})", .{@errorName(main_err)});
    };

    std.debug.panic("main should never exit, exitcode: {}", .{ret});
}
