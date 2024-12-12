//! Little module to jump into code whose start vector (`sp` and `_start`) is in the given address

const std = @import("std");

const EntryPoint = struct {
    sp: u32,
    main: *const fn () noreturn,
};

fn getEntryPoint(address: u32) EntryPoint {
    const entry_point: *EntryPoint = @ptrFromInt(address);
    return entry_point.*;
}

inline fn setMsp(address: u32) void {
    asm volatile ("MSR msp, %[msp]"
        :
        : [msp] "r" (address),
    );
}

pub fn to(address: u32) noreturn {
    const entry_point = getEntryPoint(address);
    setMsp(entry_point.sp);
    entry_point.main();
    std.debug.panic("Jumped to an entrypoint that returned", .{});
}
