const hal = @import("hal");

const Shell = @import("../../cli.zig").Shell;

const Self = @This();

pub const description = "restart the board";

pub fn handle(_: *const Self, _: *Shell) void {
    // This is __NVIC_SystemReset from core_cm7.h, zig was unable to translate
    asm volatile ("dsb 0xF" ::: "memory");
    hal.zig.SCB.AIRCR = (0x5FA << 16) | (hal.zig.SCB.AIRCR & (7 << 8)) | (1 << 2);
    asm volatile ("dsb 0xF" ::: "memory");

    while (true) {}
}