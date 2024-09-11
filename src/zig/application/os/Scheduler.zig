//! Handle several work units.

const builtin = @import("builtin");
const std = @import("std");

const hal = @import("hal");

const Thread = @import("Thread.zig");

const Self = @This();

const platform = switch(builtin.target.os.tag) {
    .freestanding => @import("platform/stm.zig"),
    .linux => @import("platform/linux.zig"),
    else => @compileError("Unsupported target platform"),
};

fn noop(_: Thread.State) Thread.Result {
    std.debug.panic("Called noop function.", .{});
}

const QUEUE_SIZE = 200;
const QueueT = std.BoundedArray(Thread, QUEUE_SIZE);

next_id: Thread.Id,

/// threads sorted by their next time of execution
queue: QueueT,

fn getInsertionIndex(self: *Self, deadline: Thread.Ticks) usize {
    var i: usize = 0;

    for (self.queue.buffer) |thread| {
        if (thread.deadline > deadline or thread.id == Thread.INVALID) {
            break;
        }

        i += 1;
    }

    std.debug.assert(i < QUEUE_SIZE);
    return i;
}

fn add(self: *Self, thread: Thread) void {
    std.debug.assert(thread.id != Thread.INVALID);
    self.queue.insert(
        self.getInsertionIndex(thread.deadline),
        thread,
    ) catch std.debug.panic("Scheduler.add()", .{});
}

fn pop(self: *Self, index: usize) Thread {
    std.debug.assert(index < QUEUE_SIZE);
    return self.queue.orderedRemove(index);
}

pub fn init() Self {
    var self = Self{
        .next_id = Thread.INVALID,
        .queue = QueueT.init(QUEUE_SIZE) catch unreachable,
    };

    for (0 .. QUEUE_SIZE) |i| {
        self.queue.set(i, .{
            .deadline = 0,
            .id = Thread.INVALID,
            .private = null,
            .run = noop,
        });
    }

    return self;
}

pub fn spawn(self: *Self, func: Thread.Fn, private: Thread.Private) Thread.Id {
    self.next_id = std.math.add(Thread.Id, self.next_id, 1) catch {
        std.debug.panic("Overflowed Thread.Id", .{});
    };

    self.add(.{
        .id = self.next_id,
        .run = func,
        .private = private,
        .deadline = platform.getTicks(),
    });

    return self.next_id;
}

/// find a thread with the given id and remove it
/// returns whether the id was found
pub fn kill(self: *Self, id: Thread.Id) bool {
    for (&self.queue, 0..) |*thread, i| {
        if (thread.id == id) {
            self.pop(i);
            return true;
        }
    }

    return false;
}

pub fn run(self: *Self) void {
    const head = self.queue.get(0);

    // nothing to do (yet)
    if (head.deadline > platform.getTicks() or head.id == Thread.INVALID) {
        return;
    }

    const ret = head.run(.{
        .executed = platform.getTicks(),
        .scheduler = self,
        .private = head.private,
    });

    switch (ret) {
        .Running => |ticks| {
            // this has to be atomic, we dont want an interrupt to chime in
            // between `.pop` and `.add` and mess up the queue's state 
            platform.lock();
            defer platform.unlock();

            var next = self.pop(0);
            next.deadline = platform.getTicks() + ticks;
            self.add(next);
        },
        .Finished => |exit| {
            std.log.info("Thread ({}): exit {}", .{head.id, exit});
            _ = self.pop(0);
        },
        .Error => |err| {
            std.log.err("Thread ({}): error {}", .{head.id, err});
            _ = self.pop(0);
        },
    }
}
