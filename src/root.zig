const std = @import("std");

pub const Camera = @import("Camera.zig");
pub const Canvas = @import("Canvas.zig");
pub const Color = @import("Color.zig");
pub const floats = @import("floats.zig");
pub const Intersection = @import("Intersection.zig");
pub const Object = @import("Object.zig");
pub const PointLight = @import("Light.zig");
pub const Material = @import("Material.zig");
pub const Matrix = @import("Matrix.zig");
pub const Pattern = @import("Pattern.zig");
pub const Ray = @import("Ray.zig");
pub const Shape = @import("shapes.zig").Shape;
pub const transformations = @import("transformations.zig");
pub const Tuple = @import("Tuple.zig");
pub const World = @import("World.zig");

test {
    comptime {
        std.testing.refAllDecls(@This());
    }
}
