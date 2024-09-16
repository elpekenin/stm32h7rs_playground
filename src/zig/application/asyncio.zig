//! Named asyncio a la Python, because `async` is a keyword in zig.

const std = @import("std");

const hal = @import("hal");

const platform = @import("platform.zig");

/// minimal time unit in the system (1ms so far)
const Tick = platform.Tick;

/// wrapper around a BoundedArray, to keep elements sorted
fn Queue(
    T: type,
    size: usize,
    args: struct {
        /// compare item to be inserted with an item already in queue
        /// retuning true means: insert in existing-item's position
        /// if no function is passed, elements are always added to the end
        sort: ?*const fn (T, T) bool = null,
    },
) type {
    return struct {
        const Self = @This();

        inner: std.BoundedArray(T, size),

        fn init() Self {
            return .{ .inner = .{} };
        }

        fn isEmpty(self: Self) bool {
            return self.inner.len == 0;
        }

        fn findIndex(self: Self, item: T) usize {
            if (args.sort == null) {
                return self.inner.len;
            }

            for (0..self.inner.len) |i| {
                if (args.sort.?(item, self.inner.get(i))) {
                    return i;
                }
            }

            return self.inner.len;
        }

        /// insert a new element
        fn add(self: *Self, item: T) void {
            std.debug.assert(self.inner.len < size);
            const i = self.findIndex(item);
            self.inner.insert(i, item) catch unreachable;
        }

        fn get(self: Self, i: usize) T {
            return self.inner.get(i);
        }

        fn pop(self: *Self) T {
            return self.inner.orderedRemove(0);
        }
    };
}

/// each element in the pool
const Coroutine = struct {
    const _Result = union(enum) {
        /// still working, value is how long to wait before calling ``.run()`` again
        Wait: Tick,

        /// value is the status (0 == success)
        Finished: u8,

        /// something went wrong
        Error: anyerror,
    };

    const _Userdata = ?*anyopaque;

    const _Fn = *const fn (_Userdata) _Result;

    /// specific storage
    userdata: _Userdata = null,

    /// when this thread's logic shall be run next time
    deadline: Tick,

    /// thread's logic
    run: _Fn,
};

const Executor = struct {
    const Self = @This();

    fn sort(new: Coroutine, existing: Coroutine) bool {
        return new.deadline < existing.deadline;
    }

    const QueueT = Queue(Coroutine, 200, .{ .sort = sort });

    queue: QueueT,

    fn init() Self {
        return .{ .queue = QueueT.init() };
    }

    fn spawn(self: *Self, func: Fn, userdata: Userdata) void {
        self.queue.add(.{
            .run = func,
            .userdata = userdata,
            .deadline = platform.getTicks(),
        });
    }

    fn run(self: *Self) void {
        if (self.queue.isEmpty()) {
            // TODO: panic instead? no threads at all
            return;
        }

        const head = self.queue.get(0);

        // nothing to do (yet)
        if (head.deadline > platform.getTicks()) {
            return;
        }

        const ret = head.run(head.userdata);
        switch (ret) {
            .Wait => |ticks| {
                // this has to be atomic, we dont want an interrupt to chime in
                // between `.pop` and `.add` and mess up the queue's state
                platform.lock();
                defer platform.unlock();

                var new = self.queue.pop();
                new.deadline = platform.getTicks() + ticks;
                self.queue.add(new);
            },
            .Finished => |status| {
                std.log.info("Awaitable ended with exitcode: {}", .{status});
                _ = self.queue.pop();
            },
            .Error => |e| {
                std.log.err("Awaitable ended with error: {}", .{e});
                _ = self.queue.pop();
            },
        }
    }
};

// Public API
pub const Fn = Coroutine._Fn;
pub const Userdata = Coroutine._Userdata;
pub const Result = Coroutine._Result;

/// sleep for ``ms`` milliseconds
pub fn sleep(ms: usize) Result {
    return .{ .Wait = ms * platform.TICKS_PER_MS };
}

/// cancel this task, with an status of ``code``
pub fn exit(code: Result.Exit) Result {
    return .{ .Finished = code };
}

/// cancel this task, due to the error ``e``
pub fn err(e: anyerror) Result {
    return .{ .Error = e };
}

/// single event loop instance for now
/// might support creating/getting event loop in the future
/// for now, this is an implementation detail
/// user is intented to use ``asyncio.*`` API
var executor = Executor.init();

pub fn spawn(func: Fn, userdata: Userdata) void {
    return executor.spawn(func, userdata);
}

pub fn run() void {
    return executor.run();
}
