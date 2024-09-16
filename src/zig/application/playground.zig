const std = @import("std");

const platform = @import("platform.zig");

pub const State = enum {
    Created,
    Running,
    Suspended,
    Completed,
};

/// order based on Python's ``typing.Generator``
pub fn Generator(Y: type, S: type, R: type) type {
    return union(enum) {
        const Self = @This();

        Yield: Y,
        Send: S,
        Return: R,

        pub fn yield(val: Y) Self {
            return Self{ .Yield = val };
        }

        pub fn send(val: S) Self {
            return Self{ .Send = val };
        }

        pub fn ret(val: R) Self {
            return Self{ .Return = val };
        }
    };
}

pub const Coroutine = struct {
    fn CoroT(
        comptime func: anytype,
        comptime ArgsT: anytype,
    ) type {
        const F = @TypeOf(func);
        const FuncInfo = @typeInfo(F);
        if (FuncInfo != .Fn) {
            // for better diagnostic of user errors (hopefully)
            @compileError("Must pass a function");
        }

        const Ret = FuncInfo.Fn.return_type.?;
        const RetInfo = @typeInfo(Ret);
        if (RetInfo != .Union or !@hasField(Ret, "Yield") or !@hasField(Ret, "Send") or !@hasField(Ret, "Return")) {
            @compileError("Function's return must be a Generator() type.");
        }

        return struct {
            const Self = @This();

            args: ArgsT,
            state: State,

            pub fn next(self: *Self) Ret {
                const ret = func(self.args);

                // TODO(elpekenin): better handling
                switch (ret) {
                    .Return => self.state = .Completed,
                    else => self.state = .Suspended,
                }

                return ret;
            }
        };
    }

    pub fn from(
        comptime func: anytype,
        args: anytype,
    ) CoroT(
        func,
        @TypeOf(args),
    ) {
        const T = CoroT(func, @TypeOf(args));
        return T{ .args = args, .state = .Created };
    }
};

pub const Time = union(enum) {
    const Self = @This();

    ticks: usize,
    ms: usize,
    s: usize,

    fn toTicks(self: Self) platform.Tick {
        return switch (self) {
            .ticks => |time| time,
            .ms => |time| time * platform.TICKS_PER_MS,
            .s => |time| time * platform.TICKS_PER_MS * 1000,
        };
    }
};

const _Sleep = struct {
    const Ret = Generator(void, void, void);
    const T = Coroutine.CoroT(run, platform.Tick);

    fn run(deadline: platform.Tick) Ret {
        const now = platform.getTicks();

        if (now < deadline) {
            return Ret.yield({});
        }

        return Ret.ret({});
    }
};

pub const Sleep = _Sleep.T;

pub fn sleep(time: Time) _Sleep.T {
    const deadline = platform.getTicks() + time.toTicks();
    return Coroutine.from(_Sleep.run, deadline);
}
