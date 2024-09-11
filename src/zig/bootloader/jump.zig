//! Little module to jump into code whose start vector (`sp` and `_start`) is in the given address

const EntryPoint = struct {
    sp: u32,
    main: *const fn () noreturn,
};

inline fn get_entry_point(address: u32) EntryPoint {
    return @as(*EntryPoint, @ptrFromInt(address)).*;
}

inline fn set_MSP(address: u32) void {
    asm volatile ("MSR msp, %[msp]"
        :
        : [msp] "r" (address),
    );
}

pub fn to(address: u32) noreturn {
    const jumping = get_entry_point(address);
    set_MSP(jumping.sp);
    jumping.main();
}
