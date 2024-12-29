pub const ByteMask = enum {
    const Self = @This();

    @"1",
    @"2",
    @"4",

    pub fn mask(self: *const Self) usize {
        return switch (self.*) {
            .@"1" => (1 << (1 * 8)) - 1,
            .@"2" => (1 << (2 * 8)) - 1,
            .@"4" => (1 << (4 * 8)) - 1,
        };
    }
};
