//! Utilities to parse user input

const std = @import("std");

const Type = std.builtin.Type;
const Iterator = std.mem.SplitIterator(u8, .any);

const Self = @This();

const ArgError = error{
    MissingArg,
    InvalidArg,
};

/// "whitespace" chars to split at (delimit words) when parsing
const delimiters = " \r\n";

const BoolStr = struct {
    value: bool,
    strings: []const []const u8,
};

/// Strings that will be interpreted as true/false
const bool_strings: []BoolStr = &.{
    .{
        .value = false,
        .strings = &.{ "n", "no", "false", "0" },
    },
    .{
        .value = true,
        .strings = &.{ "y", "yes", "true", "1" },
    },
};

iterator: Iterator,

/// Create this wrapper on top of a string
pub fn new(line: []const u8) Self {
    return Self{
        .iterator = std.mem.splitAny(u8, line, delimiters),
    };
}

/// Return the input exactly as received
pub fn rawLine(self: *const Self) []const u8 {
    return self.iterator.buffer;
}

/// Get the command name (first word in input)
pub fn commandName(self: *Self) []const u8 {
    self.iterator.reset();
    return self.iterator.first();
}

/// Get remaining (yet unparsed) input
pub fn rest(self: *Self) []const u8 {
    return self.iterator.rest();
}

/// Get next element as is (ie: string)
pub fn nextRaw(self: *Self) ArgError![]const u8 {
    return self.iterator.next() orelse return error.MissingArg;
}

/// Convert the next element to the provided type
pub fn next(self: *Self, T: type) ArgError!T {
    const I = @typeInfo(T);

    return switch (I) {
        .bool => self.Bool(),
        .@"enum" => self.Enum(T),
        .int => self.Int(T),
        else => {
            const msg = "Parsing arguments of type '" ++ @typeName(T) ++ "' not supported at the moment.";
            @compileError(msg);
        },
    };
}

fn info(T: type) Type {
    return @typeInfo(T);
}

fn Bool(self: *Self) ArgError!bool {
    const arg = try self.nextRaw();

    const lower = std.ascii.lowerString(arg, arg);

    for (bool_strings) |bool_string| {
        for (bool_string.strings) |string| {
            if (std.mem.eql(u8, string, lower)) {
                return bool_string.value;
            }
        }
    }

    return error.InvalidArg;
}

fn Enum(self: *Self, T: type) ArgError!T {
    const I = info(T);

    const arg = try self.nextRaw();

    inline for (I.@"enum".fields) |field| {
        if (std.mem.eql(u8, arg, field.name)) {
            return @enumFromInt(field.value);
        }
    }

    return error.InvalidArg;
}

// TODO: Add support for different bases
fn Int(self: *Self, T: type) ArgError!T {
    const arg = try self.nextRaw();
    return std.fmt.parseInt(T, arg, 10) catch return error.InvalidArg;
}
