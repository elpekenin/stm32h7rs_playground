//! Information about a build

const std = @import("std");
const Build = std.Build;
const Module = Build.Module;

fn withoutNewline(slice: []u8) []u8 {
    return slice[0 .. slice.len - 1];
}

pub fn getOptions(b: *Build) *Module {
    var diff: u8 = undefined;
    _ = b.runAllowFail(&.{ "git", "diff", "--quiet" }, &diff, .Ignore) catch {};

    var diff_cached: u8 = undefined;
    _ = b.runAllowFail(&.{ "git", "diff", "--quiet", "--cached" }, &diff_cached, .Ignore) catch {};

    const hash = withoutNewline(
        b.run(&.{ "git", "rev-parse", "--short", "HEAD" }),
    );

    const commit = if (diff != 0 or diff_cached != 0)
        std.mem.concat(b.allocator, u8, &.{ hash, "*" }) catch unreachable
    else
        hash;

    const datetime = withoutNewline(
        b.run(&.{ "date", "+%F %T" }),
    );

    const options = b.addOptions();
    options.addOption([]const u8, "commit", commit);
    options.addOption([]const u8, "datetime", datetime);
    return options.createModule();
}
