const std = @import("std");

pub const cameras = @import("cameras.zig");
pub const canvas = @import("canvas.zig");
pub const colors = @import("colors.zig");
pub const floats = @import("floats.zig");
pub const intersections = @import("intersections.zig");
pub const lights = @import("lights.zig");
pub const materials = @import("materials.zig");
pub const matrices = @import("matrices.zig");
pub const rays = @import("rays.zig");
pub const spheres = @import("spheres.zig");
pub const transformations = @import("transformations.zig");
pub const tuples = @import("tuples.zig");
pub const worlds = @import("worlds.zig");

test {
    comptime {
        std.testing.refAllDecls(@This());
    }
}
