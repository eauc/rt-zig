const std = @import("std");

pub const colors = @import("colors.zig");
pub const floats = @import("floats.zig");
pub const tuples = @import("tuples.zig");

test {
    comptime {
        std.testing.refAllDecls(@This());
    }
}
