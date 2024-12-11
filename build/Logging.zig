//! Logging-specific configuration

const std = @import("std");
const Build = std.Build;
const Options = Build.Step.Options;

const Config = @import("Config.zig");

const Self = @This();

filesystem: bool,
rtt: bool,

pub fn fromArgs(b: *std.Build) Self {
    const filesystem: bool = Config.option(
        b,
        bool,
        "logging_filesystem",
        "whether to log into filesystem",
        false,
    );

    const rtt: bool = Config.option(
        b,
        bool,
        "logging_rtt",
        "whether to log over rtt",
        true,
    );

    return Self{
        .filesystem = filesystem,
        .rtt = rtt,
    };
}

pub fn dumpOptions(self: *const Self, options: *Options) void {
    options.addOption(Self, "logging", self.*);
}
