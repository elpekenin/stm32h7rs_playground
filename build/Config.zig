//! Configuration for a build

const std = @import("std");
const Build = std.Build;
const Module = Build.Module;
const Compile = Build.Step.Compile;

const Self = @This();

const Logging = @import("Logging.zig");
const Panic = @import("Panic.zig");
const Program = @import("Program.zig");

// sorted alphabetically
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
    return b.option(T, name, description) orelse default;
}

pub fn fromArgs(b: *Build) Self {
    return Self{
        .logging = Logging.fromArgs(b),
        .optimize = b.standardOptimizeOption(.{}),
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

pub fn getOptions(self: *const Self, b: *Build) *Module {
    const options = b.addOptions();

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
