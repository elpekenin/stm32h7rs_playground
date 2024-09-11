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

const QUEUE_SIZE = 200;
const QueueT = std.BoundedArray(Thread, QUEUE_SIZE);

next_id: Thread.Id,

/// threads sorted by their next time of execution
queue: QueueT,

fn getInsertionIndex(self: *Self, deadline: Thread.Ticks) usize {
    for (0 .. self.queue.len) |i| {
        const thread = self.queue.get(i);

        if (thread.deadline > deadline) {
            return i;
        }
    }

    return self.queue.len;
}

fn add(self: *Self, thread: Thread) void {
    std.debug.assert(self.queue.len < QUEUE_SIZE);

    const i = self.getInsertionIndex(thread.deadline);
    self.queue.insert(i, thread) catch unreachable;
}

fn pop(self: *Self, index: usize) Thread {
    return self.queue.orderedRemove(index);
}

pub fn init() Self {
    return .{
        .next_id = 0,
        .queue = QueueT.init(0) catch unreachable,
    };
}

pub fn spawn(self: *Self, func: Thread.Fn, private: Thread.Private) Thread.Id {
    const id = self.next_id;

    self.add(.{
        .id = id,
        .run = func,
        .private = private,
        .deadline = platform.getTicks(),
    });

    self.next_id = std.math.add(Thread.Id, self.next_id, 1) catch {
        std.debug.panic("Overflowed Thread.Id", .{});
    };

    return id;
}

/// find a thread with the given id and remove it
/// returns whether the killed Thread (if found)
pub fn kill(self: *Self, id: Thread.Id) ?Thread {
    for (0 .. self.queue.len) |i| {
        if (self.queue.get(i).id == id) {
            return self.pop(i);
        }
    }

    return null;
}

pub fn run(self: *Self) void {
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
