// TODO: Add argument parsing facilities (?)

const std = @import("std");
const Type = std.builtin.Type;

const logger = std.log.scoped(.terminal);

const Keys = @import("Keys.zig");

/// Tiny wrapper for convenience
pub fn matches(first: []const u8, second: []const u8) bool {
    return std.mem.eql(u8, first, second);
}

pub const Args = @import("Args.zig");

// TODO?: Change signature, eg mutable Inner
fn Handler(Inner: type) type {
    return *const fn (*const Inner, *Args) anyerror!void;
}

fn findSpecial(Inner: type, name: []const u8) ?Handler(Inner) {
    if (!@hasDecl(Inner, "Special")) return null;
    if (!@hasDecl(Inner.Special, name)) return null;
    return @field(Inner.Special, name);
}

/// Wrap a struct that "defines" a shell, adding some utilities.
///
/// `Inner` is expected to provide:
///  * `fn readByte(*Inner) !u8`: A function used by this wrapper to read user input.
///  * `Inner.Commands`: A `pub struct` defining commands
///    * Each (pub) decl is a `fn <command_name>(*Inner, *ArgIterator)`. This is, a method where the second argument is an iterator to read the remaining of the input (eg: to parse arguments).
///    * If present, the one named `@" "` will get executed if none matched (eg: to print error message).
///
/// `Outer` (the type returned) provides:
///  * `fn new(Inner) Outer`: Create an instance from an instance of `Inner`
///  * `fn readline(*Outer) ![]const u8`: Consume input until "\n" is received, retuning the string read.
///  * `fn handle(*Outer, []const u8) !void`: Finds command name (first word in input) and -tries- executes the function with the same name within `Inner.Commands`, falling back to `@"not-found"` if available.
///
/// NOTE: Writing back (for user feedback) is out of scope -for now?- and has to be handled completely within `Inner`'s logic.
pub fn Wrapper(comptime Inner: type) type {
    if (@typeInfo(Inner) != .@"struct" or !@hasDecl(Inner, "Commands") or @typeInfo(Inner.Commands) != .@"struct") {
        const msg = "Invalid input passed to `Wrapper()`, check the documentation comment";
        @compileError(msg);
    }

    const maybe_tab = findSpecial(Inner, "tab");
    const maybe_fallback = findSpecial(Inner, "fallback");

    const Outer = struct {
        const Self = @This();

        const rx_len = 1024;
        const Buff = std.BoundedArray(u8, rx_len);

        inner: Inner,
        buffer: Buff,

        pub fn new(inner: Inner) Self {
            return Self{
                .inner = inner,
                // has size rx_len (>0), can't fail
                .buffer = Buff.init(0) catch unreachable,
            };
        }

        /// Read one byte at a time, or null if nothing was to be read
        fn read(self: *Self) !?u8 {
            return self.inner.readByte() catch |err| switch (err) {
                error.EndOfStream => return null, // nothing was read
                else => |e| {
                    logger.err("Unknown error on reader ({any})", .{e});
                    return e;
                },
            };
        }

        /// Call `.read()` in a loop until a newline is received, returning the string at that point
        pub fn readline(self: *Self) ![]const u8 {
            self.buffer.clear(); // cleanup before using

            while (true) {
                const byte = try self.read() orelse continue;

                switch (byte) {
                    Keys.Newline => {
                        // input ready, return it to be handled
                        return self.buffer.constSlice();
                    },
                    Keys.Tab => {
                        if (maybe_tab) |tab| {
                            var args = Args.new(self.buffer.constSlice());
                            tab(&self.inner, &args) catch {};
                        }
                    },
                    Keys.Backspace => {
                        // backspace deletes previous char (if any)
                        _ = self.buffer.popOrNull();
                    },
                    else => {
                        self.buffer.append(byte) catch std.debug.panic("Exhausted rx_buffer", .{});
                    },
                }
            }
        }

        fn findCommandHandler(name: []const u8) ?Handler(Inner) {
            inline for (@typeInfo(Inner.Commands).@"struct".decls) |decl| {
                if (matches(name, decl.name)) {
                    return @field(Inner.Commands, decl.name);
                }
            }

            return null;
        }

        pub fn handle(self: *const Self, line: []const u8) void {
            var args = Args.new(line);

            const command_name = args.commandName();
            if (findCommandHandler(command_name)) |func| {
                return func(&self.inner, &args) catch {};
            }

            if (maybe_fallback) |fallback| {
                return fallback(&self.inner, &args) catch {};
            }
        }
    };

    return Outer;
}
