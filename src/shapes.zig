const Cone = @import("shapes/Cone.zig");
const Cube = @import("shapes/Cube.zig");
const Cylinder = @import("shapes/Cylinder.zig");
const floats = @import("floats.zig");
const Float = floats.Float;
const Intersection = @import("Intersection.zig");
const Object = @import("Object.zig");
const Plane = @import("shapes/Plane.zig");
const Ray = @import("Ray.zig");
const Sphere = @import("shapes/Sphere.zig");
const Tuple = @import("Tuple.zig");

pub const Shape = union(enum) {
    cone: Cone,
    cube: Cube,
    cylinder: Cylinder,
    plane: Plane,
    sphere: Sphere,

    pub fn _cone() Shape {
        return Shape{ .cone = Cone.init() };
    }
    pub fn _cylinder() Shape {
        return Shape{ .cylinder = Cylinder.init() };
    }
    pub fn _cube() Shape {
        return Shape{ .cube = Cube.init() };
    }
    pub fn _plane() Shape {
        return Shape{ .plane = Plane.init() };
    }
    pub fn _sphere() Shape {
        return Shape{ .sphere = Sphere.init() };
    }

    pub fn truncate(self: Shape, minimum: Float, maximum: Float, is_closed: bool) Shape {
        switch (self) {
            .cone => |c| return Shape{ .cone = c.truncate(minimum, maximum, is_closed) },
            .cylinder => |c| return Shape{ .cylinder = c.truncate(minimum, maximum, is_closed) },
            else => @panic("Cannot truncate shape"),
        }
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
