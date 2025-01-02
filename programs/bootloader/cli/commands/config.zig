const root = @import("root");

const config = @import("config");
const rtt = @import("rtt");

const t = @import("../tab.zig");
const Shell = @import("../../cli.zig").Shell;

pub const Config = enum {
    const Self = @This();

    pub const description = "show current configuration";

    build,
    cycles,
    rtt,

    fn printAttribute(shell: *Shell, container: anytype, comptime name: []const u8) bool {
        const value = @field(container, name);
        const T = @TypeOf(value);

        switch (T) {
            type => return false,
            []const u8 => shell.print("{s}: {s}", .{ name, value }),
            else => shell.print("{s}: {any}", .{ name, value }),
        }

        return true;
    }

    fn printFields(shell: *Shell, container: anytype) void {
        const T = @TypeOf(container);
        const I = @typeInfo(T);
        const fields = I.@"struct".fields;

        inline for (fields[0 .. fields.len - 1]) |field| {
            _ = printAttribute(shell, container, field.name);
            shell.print("\n", .{});
        }
        _ = printAttribute(shell, container, fields[fields.len - 1].name);
    }

    fn printConfig(shell: *Shell) void {
        const I = @typeInfo(config);
        const decls = I.@"struct".decls;

        inline for (decls[0 .. decls.len - 1]) |decl| {
            if (printAttribute(shell, config, decl.name)) {
                shell.print("\n", .{});
            }
        }
        _ = printAttribute(shell, config, decls[decls.len - 1].name);
    }

    fn printDummy(shell: *Shell) void {
        printFields(shell, root.dummy_cycles_config);
    }

    fn printRttChannel(shell: *Shell, i: usize, channel: rtt.channel.Config) void {
        shell.print("\n  [{}] {{ .name = \"{s}\", .buffer_size = {}, .mode = {s} }}", .{
            i,
            channel.name,
            channel.buffer_size,
            @tagName(channel.mode),
        });
    }

    fn printRtt(shell: *Shell) void {
        shell.print("up", .{});
        for (0.., root.rtt_config.up_channels) |i, channel| {
            printRttChannel(shell, i, channel);
        }

        shell.print("\n", .{});

        shell.print("down", .{});
        for (0.., root.rtt_config.down_channels) |i, channel| {
            printRttChannel(shell, i, channel);
        }
    }

    pub fn handle(self: Self, shell: *Shell) void {
        switch (self) {
            .build => printConfig(shell),
            .cycles => printDummy(shell),
            .rtt => printRtt(shell),
        }
    }

    pub fn tab(shell: *Shell) !void {
        return t.Enum(shell, Self);
    }
};
