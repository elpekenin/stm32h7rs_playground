//! Configuration for a build

// TODO: research
// .optimize = b.standardOptimizeOption(.{
//     .preferred_optimize_mode = .ReleaseSmall,
// }),

const std = @import("std");
const Build = std.Build;
const Module = Build.Module;
const Compile = Build.Step.Compile;

const Self = @This();

const Hal = @import("Hal.zig");
const LibC = @import("LibC.zig");
const Logging = @import("Logging.zig");
const Panic = @import("Panic.zig");
const Program = @import("Program.zig");

const logger = std.log.scoped(.build);

// sorted alphabetically
hal: Hal,
libc: LibC,
logging: Logging,
optimize: std.builtin.OptimizeMode,
panic: Panic,
program: Program,
target: std.Build.ResolvedTarget,

/// Shared logic for optional flag, printing default value selected
pub fn option(
    b: *Build,
    comptime T: type,
    name: []const u8,
    description: []const u8,
    comptime default: T,
) T {
    const maybe_val: ?T = b.option(T, name, description);

    if (maybe_val) |val| {
        return val;
    }

    // specialization for enum printing
    switch (@typeInfo(T)) {
        .@"enum" => logger.info("'{s}' not specified, using `.{s}`", .{ name, @tagName(default) }),
        else => logger.info("'{s}' not specified, using `{}`", .{ name, default }),
    }

    return default;
}

pub fn fromArgs(b: *Build) Self {
    return Self{
        .hal = Hal.fromArgs(b),
        .libc = LibC.fromArgs(b),
        .logging = Logging.fromArgs(b),
        .optimize = .ReleaseSmall,
        .panic = Panic.fromArgs(b),
        .program = Program.fromArgs(b),
        .target = b.resolveTargetQuery(.{
            .cpu_arch = .thumb,
            .cpu_model = .{
                .explicit = &std.Target.arm.cpu.cortex_m7,
            },
            .cpu_features_add = std.Target.arm.featureSet(&.{
                // FIXME: which one is correct?
                .vfp4d16,
                // .fp_armv8d16,
            }),
            .os_tag = .freestanding,
            .abi = .eabihf,
        }),
    };
}

/// Create an executable into the entry/startup code (copy data sections, jump to main, handle its output)
pub fn getEntrypoint(self: *const Self, b: *Build) *std.Build.Step.Compile {
    const start = b.addExecutable(.{
        .error_tracing = true,
        .name = b.fmt("{s}.elf", .{
            self.program.name(),
        }), // STM32CubeProgrammer does not like the lack of extension
        .optimize = self.optimize,
        .root_source_file = b.path(
            "modules/common/start.zig",
        ),
        .single_threaded = true,
        .strip = false,
        .target = self.target,
    });

    if (self.logging.filesystem) {
        const zfat = b.dependency(
            "zfat",
            .{
                .@"no-libc" = true,
                .optimize = self.optimize,
                .@"static-rtc" = currentDate(b),
                .target = self.target,
            },
        ).module("zfat");

        zfat.linkLibrary(self.getLibC(b)); // FIXME: Clean this up
        start.root_module.addImport("fatfs", zfat);
    }

    if (self.logging.rtt) {
        const rtt = b.dependency(
            "rtt",
            .{},
        ).module("rtt");
        start.root_module.addImport("rtt", rtt);
    }

    start.setLinkerScript(
        b.path(
            b.fmt("ld/{s}.ld", .{
                self.program.name(),
            }),
        ),
    );

    return start;
}

pub fn getHal(self: *const Self, b: *Build) *Module {
    return b.dependency(
        "hal",
        .{
            .optimize = self.optimize,
            .target = self.target,
        },
    ).module("hal");
}

pub fn getLibC(self: *const Self, b: *Build) *Compile {
    return b.dependency(
        self.libc.dependency,
        .{
            .optimize = self.optimize,
            .target = self.target,
        },
    ).artifact(self.libc.artifact);
}

/// Fix the fake RTC shown by zfat/FatFS, to the date of building
fn currentDate(b: *Build) []const u8 {
    const out = b.run(&.{ "date", "+\"%Y-%m-%d\"" });
    return out[1 .. out.len - 2]; // output is wrapped in quotes, remove them
}

pub fn getOptions(self: *const Self, b: *Build) *Module {
    const options = b.addOptions();

    self.hal.dumpOptions(options);
    self.libc.dumpOptions(options);
    self.logging.dumpOptions(options);
    self.panic.dumpOptions(options);
    self.program.dumpOptions(options);

    return options.createModule();
}

pub fn getProgram(self: *const Self, b: *Build) *Module {
    return b.addModule(
        "program",
        .{
            .root_source_file = b.path(
                b.fmt("modules/{s}/main.zig", .{self.program.name()}),
            ),
        },
    );
}
