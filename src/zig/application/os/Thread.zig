//! Represent a work unit.

const Scheduler = @import("Scheduler.zig");

const Self = @This();

/// unique identifier
pub const Id = u32;

/// magic value
pub const INVALID: Id = 0;

pub const Ticks = u32;

pub const ExitCode = u8;

/// result running some code
pub const Result = union(enum) {
    /// still working, valeu is how long to wait before calling ``.run()`` again
    Running: Ticks,

    /// something went wrong
    Error: anyerror,

    /// value is the status (0 == success)
    Finished: ExitCode,
};

pub const Private = ?*anyopaque;

pub const State = struct {
    executed: Ticks,
    scheduler: *Scheduler,
    private: Private,
};

pub const Fn = *const fn (State) Result;

/// thread's ID
id: Id,

/// thread-specific storage
private: Private,

/// when this thread's logic shall be run next time
deadline: Ticks,

/// thread's logic
run: Fn,

pub fn sleep(ticks: Ticks) Result {
    return .{
        .Running = ticks,
    };
}

pub fn exit(code: ExitCode) Result {
    return .{
        .Finished = code,
    };
}

pub fn err(e: anyerror) Result {
    return .{
        .Error = e,
    };
}
