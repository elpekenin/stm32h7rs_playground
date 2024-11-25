//! Logging-specific configuration

const std = @import("std");
const Build = std.Build;
const Options = Build.Step.Options;

const Self = @This();

filesystem: bool,
rtt: bool,

pub fn fromArgs(b: *std.Build) Self {
    const filesystem: bool = b.option(
        bool,
        "logging_filesystem",
        "whether to log into filesystem",
    ) orelse true;

    const rtt: bool = b.option(
        bool,
        "logging_rtt",
        "whether to log over rtt",
    ) orelse true;

    return Self{
        .filesystem = filesystem,
        .rtt = rtt,
    };
}

pub fn dumpOptions(self: *const Self, options: *Options) void {
    options.addOption(Self, "logging", self.*);
}
