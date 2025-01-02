//! Configuration for a build

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
        .@"enum" => logger.info("{s}=.{s}", .{ name, @tagName(default) }),
        else => logger.info("{s}={}", .{ name, default }),
    }

    return default;
}

pub fn fromArgs(b: *Build) Self {
    const optimize = b.standardOptimizeOption(.{});
    logger.info("optimize={s}", .{@tagName(optimize)});

    return Self{
        .hal = Hal.fromArgs(b),
        .libc = LibC.fromArgs(b),
        .logging = Logging.fromArgs(b),
        .optimize = optimize,
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

    start.setLinkerScript(
        b.path(
            b.fmt("programs/{s}/linker.ld", .{
                self.program.name(),
            }),
        ),
    );

    return start;
}

pub fn getLibC(config: *const Self, b: *Build) *Compile {
    return b.dependency(
        config.libc.dependency,
        .{
            .optimize = config.optimize,
            .target = config.target,
        },
    ).artifact(config.libc.artifact);
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
                b.fmt("programs/{s}/main.zig", .{self.program.name()}),
            ),
        },
    );
}
