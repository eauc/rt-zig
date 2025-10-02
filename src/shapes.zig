const std = @import("std");
const BoundingBox = @import("BoundingBox.zig");
const Cone = @import("shapes/Cone.zig");
const Cube = @import("shapes/Cube.zig");
const Cylinder = @import("shapes/Cylinder.zig");
const floats = @import("floats.zig");
const Float = floats.Float;
pub const Group = @import("shapes/Group.zig");
const Intersection = @import("Intersection.zig");
const Matrix = @import("Matrix.zig");
const Object = @import("Object.zig");
const Plane = @import("shapes/Plane.zig");
const Ray = @import("Ray.zig");
const Sphere = @import("shapes/Sphere.zig");
pub const Triangle = @import("shapes/Triangle.zig");
const Tuple = @import("Tuple.zig");

pub const Shape = union(enum) {
    cone: Cone,
    cube: Cube,
    cylinder: Cylinder,
    group: Group,
    plane: Plane,
    sphere: Sphere,
    triangle: Triangle,

    pub fn _cone() Shape {
        return Shape{ .cone = Cone.init() };
    }
    pub fn _cylinder() Shape {
        return Shape{ .cylinder = Cylinder.init() };
    }
    pub fn _cube() Shape {
        return Shape{ .cube = Cube.init() };
    }
    pub fn _group(allocator: std.mem.Allocator) Shape {
        return Shape{ .group = Group.init(allocator) };
    }
    pub fn _plane() Shape {
        return Shape{ .plane = Plane.init() };
    }
    pub fn _sphere() Shape {
        return Shape{ .sphere = Sphere.init() };
    }
    pub fn _triangle(p1: Tuple, p2: Tuple, p3: Tuple) Shape {
        return Shape{ .triangle = Triangle.init(p1, p2, p3) };
    }

    pub fn deinit(self: *Shape) void {
        switch (self.*) {
            .group => |*g| g.deinit(),
            else => {},
        }
    }

    pub fn truncate(self: Shape, minimum: Float, maximum: Float, is_closed: bool) Shape {
        switch (self) {
            .cone => |c| return Shape{ .cone = c.truncate(minimum, maximum, is_closed) },
            .cylinder => |c| return Shape{ .cylinder = c.truncate(minimum, maximum, is_closed) },
            else => @panic("Cannot truncate shape"),
        }
    }

    pub fn prepare_transform(self: *Shape, world_to_object: Matrix, object_to_world: Matrix) void {
        switch (self.*) {
            .group => |*g| g.prepare_transform(world_to_object, object_to_world),
            else => {},
        }
    }

    pub fn prepare_bounding_box(self: *Shape) BoundingBox {
        return switch (self.*) {
            .cone => |*c| c.prepare_bounding_box(),
            .cylinder => |*c| c.prepare_bounding_box(),
            .group => |*g| g.prepare_bounding_box(),
            .plane => |*p| p.prepare_bounding_box(),
            .triangle => |*t| t.prepare_bounding_box(),
            inline else => BoundingBox.default(),
        };
    }

    pub fn local_intersect(self: Shape, ray: Ray, object: *const Object, buf: []Intersection) []Intersection {
        return switch (self) {
            inline else => |s| s.local_intersect(ray, object, buf),
        };
    }

    pub fn local_normal_at(self: Shape, local_point: Tuple) Tuple {
        return switch (self) {
            inline else => |s| s.local_normal_at(local_point),
        };
    }
};
