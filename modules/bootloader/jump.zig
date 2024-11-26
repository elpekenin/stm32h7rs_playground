//! Little module to jump into code whose start vector (`sp` and `_start`) is in the given address

const EntryPoint = struct {
    sp: u32,
    main: *const fn () noreturn,
};

fn getEntryPoint(address: u32) EntryPoint {
    return @as(*EntryPoint, @ptrFromInt(address)).*;
}

inline fn setMsp(address: u32) void {
    asm volatile ("MSR msp, %[msp]"
        :
        : [msp] "r" (address),
    );
}

pub fn to(address: u32) noreturn {
    const jumping = getEntryPoint(address);
    setMsp(jumping.sp);
    jumping.main();
    unreachable;
}
