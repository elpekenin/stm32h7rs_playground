//! Startup logic to be used on both bootloader- and application-level code.
//! Thus, broken down into a reusable file under `common/`
//!
//! Note: The root of the project (aka: `app.zig` or `bootloader.zig`) has to import
//! this file, and "save" it from garbage collection with
//! ```
//! comptime {
//!     _ = imported_name;
//! }
//! ```
//! ...for this to work.
//!
//! It will add the entry point of the zig code, this is:
//!   - Export main, which picolibc will execute after early setup
//!   - Initialize STM's HAL
//!   - Execute `root.run()`

const root = @import("root");

const hal = @import("hal.zig");

/// Arguments' signature doesn't really matter as picolibc will be
/// doing `int ret = main(0, NULL)`
///
/// But, just for reference, according to C11, `argv` should be a
/// non-const, null-terminated list of null-terminated strings.
pub export fn main(argc: i32, argv: [*c][*:0]u8) i32 {
    _ = argc;
    _ = argv;

    hal.early_init();

    root.run();

    return 0;
}
