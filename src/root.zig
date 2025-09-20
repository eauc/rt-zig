const std = @import("std");

pub const tuples = @import("tuples.zig");

test {
    comptime {
        std.testing.refAllDecls(@This());
    }
}
