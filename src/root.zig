const std = @import("std");

test {
    comptime {
        std.testing.refAllDecls(@This());
    }
}
