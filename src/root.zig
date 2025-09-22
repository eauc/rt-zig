const std = @import("std");

pub const canvas = @import("canvas.zig");
pub const colors = @import("colors.zig");
pub const floats = @import("floats.zig");
pub const intersections = @import("intersections.zig");
pub const matrices = @import("matrices.zig");
pub const rays = @import("rays.zig");
pub const spheres = @import("spheres.zig");
pub const transformations = @import("transformations.zig");
pub const tuples = @import("tuples.zig");

test {
    comptime {
        std.testing.refAllDecls(@This());
    }
}
