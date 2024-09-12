//! Named asyncio a la Python, because `async` is a keyword in zig.

const std = @import("std");

const hal = @import("hal");

const platform = @import("platform.zig");

/// minimal time unit in the system (1ms so far)
pub const Ticks = u32;

pub const State = struct {
    executed: Ticks,
    private: Awaitable.Private,
};

pub const Result = union(enum) {
    const Exit = u8;

    /// still working, valeu is how long to wait before calling ``.run()`` again
    Wait: Ticks,

    /// value is the status (0 == success)
    Finished: Exit,

    /// something went wrong
    Error: anyerror,
};

/// each element in the pool
const Awaitable = struct {
    /// unique identifier
    const Id = u32;

    const Private = ?*anyopaque;

    const Fn = *const fn (State) Result;

    /// thread's ID
    id: Id,

    /// thread-specific storage
    private: Private,

    /// when this thread's logic shall be run next time
    deadline: Ticks,

    /// thread's logic
    run: Fn,
};

const EventLoop = struct {
    const Self = @This();
    const QUEUE_SIZE = 200;

    next_id: Awaitable.Id,

    /// threads sorted by their next time of execution
    queue: std.BoundedArray(Awaitable, QUEUE_SIZE),

    fn getInsertionIndex(self: *Self, deadline: Ticks) usize {
        for (0..self.queue.len) |i| {
            const thread = self.queue.get(i);

            if (thread.deadline > deadline) {
                return i;
            }
        }

        return self.queue.len;
    }

    fn add(self: *Self, thread: Awaitable) void {
        std.debug.assert(self.queue.len < QUEUE_SIZE);

        const i = self.getInsertionIndex(thread.deadline);
        self.queue.insert(i, thread) catch unreachable;
    }

    fn pop(self: *Self, index: usize) Awaitable {
        return self.queue.orderedRemove(index);
    }

    fn init() Self {
        return .{
            .next_id = 0,
            .queue = .{},
        };
    }

    fn spawn(self: *Self, func: Awaitable.Fn, private: Awaitable.Private) Awaitable.Id {
        const id = self.next_id;

        self.add(.{
            .id = id,
            .run = func,
            .private = private,
            .deadline = platform.getTicks(),
        });

        self.next_id = std.math.add(Awaitable.Id, self.next_id, 1) catch {
            std.debug.panic("Overflowed Thread.Id", .{});
        };

        return id;
    }

    /// find task with the given id and remove it (if found)
    /// returns the removed element (null if not found)
    fn kill(self: *Self, id: Awaitable.Id) ?Awaitable {
        for (0..self.queue.len) |i| {
            if (self.queue.get(i).id == id) {
                return self.pop(i);
            }
        }

        return null;
    }

    fn run(self: *Self) void {
        if (self.queue.len == 0) {
            // TODO: panic instead? no threads at all
            return;
        }

        const head = self.queue.get(0);

        // nothing to do (yet)
        if (head.deadline > platform.getTicks()) {
            return;
        }

        const ret = head.run(.{
            .executed = platform.getTicks(),
            .private = head.private,
        });

        switch (ret) {
            .Wait => |ticks| {
                // this has to be atomic, we dont want an interrupt to chime in
                // between `.pop` and `.add` and mess up the queue's state
                platform.lock();
                defer platform.unlock();

                var next = self.pop(0);
                next.deadline = platform.getTicks() + ticks;
                self.add(next);
            },
            .Finished => |status| {
                std.log.info("Thread ({}): exit {}", .{ head.id, status });
                _ = self.pop(0);
            },
            .Error => |e| {
                std.log.err("Thread ({}): error {}", .{ head.id, e });
                _ = self.pop(0);
            },
        }
    }
};

pub fn sleep(ticks: Ticks) Result {
    return .{ .Wait = ticks };
}

pub fn exit(code: Result.Exit) Result {
    return .{ .Finished = code };
}

pub fn err(e: anyerror) Result {
    return .{ .Error = e };
}

/// single event loop instance for now
/// might support creating/getting event loop in the future
/// for now, this is an implementation detail
/// user is intented to use ``asyncio.*`` API
var loop = EventLoop.init();

pub fn spawn(func: Awaitable.Fn, private: Awaitable.Private) Awaitable.Id {
    return loop.spawn(func, private);
}

pub fn kill(id: Awaitable.Id) ?Awaitable {
    return loop.kill(id);
}

pub fn run() void {
    return loop.run();
}
