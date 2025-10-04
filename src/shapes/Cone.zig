const std = @import("std");
const BoundingBox = @import("../BoundingBox.zig");
const Cone = @This();
const floats = @import("../floats.zig");
const Float = floats.Float;
const Intersection = @import("../Intersection.zig");
const Object = @import("../Object.zig");
const Ray = @import("../Ray.zig");
const Tuple = @import("../Tuple.zig");

minimum: Float,
maximum: Float,
is_closed: bool,

pub fn init() Cone {
    return Cone{
        .minimum = -std.math.inf(Float),
        .maximum = std.math.inf(Float),
        .is_closed = false,
    };
}

pub fn truncate(_: Cone, minimum: Float, maximum: Float, is_closed: bool) Cone {
    return Cone{
        .minimum = minimum,
        .maximum = maximum,
        .is_closed = is_closed,
    };
}

test "The default minimum and maximum for a cone" {
    const cyl = Cone.init();
    try std.testing.expectEqual(-std.math.inf(Float), cyl.minimum);
    try std.testing.expectEqual(std.math.inf(Float), cyl.maximum);
    try std.testing.expectEqual(false, cyl.is_closed);
}

pub fn prepare_bounding_box(self: *Cone) BoundingBox {
    const size = @max(@abs(self.minimum), @abs(self.maximum));
    return BoundingBox.init(Tuple.point(-size, self.minimum, -size), Tuple.point(size, self.maximum, size));
}

pub fn local_intersect(self: Cone, ray: Ray, object: *const Object, buf: []Intersection) []Intersection {
    const sides_xs = self.intersect_sides(ray, object, buf);
    const caps_xs = self.intersect_caps(ray, object, buf[sides_xs.len..]);
    return buf[0 .. sides_xs.len + caps_xs.len];
}

fn intersect_sides(self: Cone, ray: Ray, object: *const Object, buf: []Intersection) []Intersection {
    const a = std.math.pow(Float, ray.direction.x, 2) - std.math.pow(Float, ray.direction.y, 2) + std.math.pow(Float, ray.direction.z, 2);
    const b = 2 * ray.origin.x * ray.direction.x - 2 * ray.origin.y * ray.direction.y + 2 * ray.origin.z * ray.direction.z;
    const c = std.math.pow(Float, ray.origin.x, 2) - std.math.pow(Float, ray.origin.y, 2) + std.math.pow(Float, ray.origin.z, 2);
    if (floats.equals(a, 0) and !floats.equals(b, 0)) {
        const t = -c / (2 * b);
        buf[0] = Intersection.init(t, object);
        return buf[0..1];
    }
    var discriminant = std.math.pow(Float, b, 2) - 4 * a * c;
    if (-floats.EPSILON < discriminant and discriminant < 0) {
        discriminant = 0;
    }
    if (discriminant < 0) return buf[0..0];
    var t0 = (-b - std.math.sqrt(discriminant)) / (2 * a);
    var t1 = (-b + std.math.sqrt(discriminant)) / (2 * a);
    if (t0 > t1) std.mem.swap(Float, &t0, &t1);

    var i: usize = 0;
    const y0 = ray.origin.y + t0 * ray.direction.y;
    if (self.minimum < y0 and y0 < self.maximum) {
        buf[i] = Intersection.init(t0, object);
        i += 1;
    }
    const y1 = ray.origin.y + t1 * ray.direction.y;
    if (self.minimum < y1 and y1 < self.maximum) {
        buf[i] = Intersection.init(t1, object);
        i += 1;
    }
    return buf[0..i];
}

fn intersect_caps(self: Cone, ray: Ray, object: *const Object, buf: []Intersection) []Intersection {
    if (!self.is_closed or floats.equals(ray.direction.y, 0)) return buf[0..0];
    var i: usize = 0;
    var t = (self.minimum - ray.origin.y) / ray.direction.y;
    if (check_cap(ray, t, @abs(self.minimum))) {
        buf[i] = Intersection.init(t, object);
        i += 1;
    }
    t = (self.maximum - ray.origin.y) / ray.direction.y;
    if (check_cap(ray, t, @abs(self.maximum))) {
        buf[i] = Intersection.init(t, object);
        i += 1;
    }
    return buf[0..i];
}

fn check_cap(ray: Ray, t: Float, radius: Float) bool {
    const x = ray.origin.x + t * ray.direction.x;
    const z = ray.origin.z + t * ray.direction.z;
    return std.math.hypot(x, z) <= radius + floats.EPSILON;
}

test "Intersecting a cone with a ray" {
    const cone = Object.cone();
    for ([_]struct { Tuple, Tuple, Float, Float }{
        .{ Tuple.point(0, 0, -5), Tuple.vector(0, 0, 1), 5, 5 },
        .{ Tuple.point(0, 0, -5), Tuple.vector(1, 1, 1), 8.66025, 8.66025 },
        .{ Tuple.point(1, 1, -5), Tuple.vector(-0.5, -1, 1), 4.55006, 49.44995 },
    }) |example| {
        const r = Ray.init(example[0], example[1].normalize());
        var buf = [_]Intersection{undefined} ** 10;
        const xs = cone.intersect(r, &buf);
        try std.testing.expectEqual(2, xs.len);
        try floats.expectEqual(example[2], xs[0].t);
        try floats.expectEqual(example[3], xs[1].t);
    }
}

test "Intersecting a cone with a ray parallel to one of its halves" {
    const cone = Object.cone();
    const ray = Ray.init(Tuple.point(0, 0, -1), Tuple.vector(0, 1, 1).normalize());
    var buf = [_]Intersection{undefined} ** 10;
    const xs = cone.intersect(ray, &buf);
    try std.testing.expectEqual(1, xs.len);
    try floats.expectEqual(0.35355, xs[0].t);
}

test "Intersecting a cone's end caps" {
    const cone = Object.cone().truncate(-0.5, 0.5, true);
    for ([_]struct { Tuple, Tuple, usize }{
        .{ Tuple.point(0, 0, -5), Tuple.vector(0, 1, 0), 0 },
        .{ Tuple.point(0, 0, -0.25), Tuple.vector(0, 1, 1), 2 },
        .{ Tuple.point(0, 0, -0.25), Tuple.vector(0, 1, 0), 4 },
    }) |example| {
        const r = Ray.init(example[0], example[1].normalize());
        var buf = [_]Intersection{undefined} ** 10;
        const xs = cone.intersect(r, &buf);
        try std.testing.expectEqual(example[2], xs.len);
    }
}

pub fn local_normal_at(self: Cone, point: Tuple) Tuple {
    const dist = std.math.pow(Float, point.x, 2) + std.math.pow(Float, point.z, 2);
    const radius2 = std.math.pow(Float, point.y, 2);
    if (dist < radius2 and point.y >= self.maximum - floats.EPSILON) return Tuple.vector(0, 1, 0);
    if (dist < radius2 and point.y <= self.minimum + floats.EPSILON) return Tuple.vector(0, -1, 0);
    var y = std.math.hypot(point.x, point.z);
    y = if (point.y > 0) -y else y;
    return Tuple.vector(point.x, y, point.z);
}

test "Computing the normal vector on a cone" {
    const cone = Object.cone();
    for ([_]struct { Tuple, Tuple }{
        .{ Tuple.point(0, 0, 0), Tuple.vector(0, 0, 0) },
        .{ Tuple.point(1, 1, 1), Tuple.vector(1, -floats.sqrt2, 1) },
        .{ Tuple.point(-1, -1, 0), Tuple.vector(-1, 1, 0) },
    }) |example| {
        const n = cone.normal_at(example[0], Intersection.init(0, &cone));
        try Tuple.expectEqual(example[1].normalize(), n);
    }
}
