const std = @import("std");
const BoundingBox = @import("../BoundingBox.zig");
const Cylinder = @This();
const floats = @import("../floats.zig");
const Float = floats.Float;
const Intersection = @import("../Intersection.zig");
const Object = @import("../Object.zig");
const Ray = @import("../Ray.zig");
const Tuple = @import("../Tuple.zig");

minimum: Float,
maximum: Float,
is_closed: bool,

pub fn init() Cylinder {
    return Cylinder{
        .minimum = -std.math.inf(Float),
        .maximum = std.math.inf(Float),
        .is_closed = false,
    };
}

pub fn truncate(_: Cylinder, minimum: Float, maximum: Float, is_closed: bool) Cylinder {
    return Cylinder{
        .minimum = minimum,
        .maximum = maximum,
        .is_closed = is_closed,
    };
}

test "The default minimum and maximum for a cylinder" {
    const cyl = Cylinder.init();
    try std.testing.expectEqual(-std.math.inf(Float), cyl.minimum);
    try std.testing.expectEqual(std.math.inf(Float), cyl.maximum);
    try std.testing.expectEqual(false, cyl.is_closed);
}

pub fn prepare_bounding_box(self: Cylinder) BoundingBox {
    var box = BoundingBox.default();
    box.min.y = self.minimum;
    box.max.y = self.maximum;
    return box;
}

pub fn local_intersect(self: Cylinder, ray: Ray, object: *const Object, buf: []Intersection) []Intersection {
    const sides_xs = self.intersect_sides(ray, object, buf);
    const caps_xs = self.intersect_caps(ray, object, buf[sides_xs.len..]);
    return buf[0 .. sides_xs.len + caps_xs.len];
}

fn intersect_sides(self: Cylinder, ray: Ray, object: *const Object, buf: []Intersection) []Intersection {
    const a = std.math.pow(f32, ray.direction.x, 2) + std.math.pow(f32, ray.direction.z, 2);
    if (floats.equals(a, 0)) return buf[0..0];
    const b = 2 * ray.origin.x * ray.direction.x + 2 * ray.origin.z * ray.direction.z;
    const c = std.math.pow(f32, ray.origin.x, 2) + std.math.pow(f32, ray.origin.z, 2) - 1;
    const discriminant = std.math.pow(f32, b, 2) - 4 * a * c;
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

fn intersect_caps(self: Cylinder, ray: Ray, object: *const Object, buf: []Intersection) []Intersection {
    if (!self.is_closed or floats.equals(ray.direction.y, 0)) return buf[0..0];
    var i: usize = 0;
    var t = (self.minimum - ray.origin.y) / ray.direction.y;
    if (check_cap(ray, t)) {
        buf[i] = Intersection.init(t, object);
        i += 1;
    }
    t = (self.maximum - ray.origin.y) / ray.direction.y;
    if (check_cap(ray, t)) {
        buf[i] = Intersection.init(t, object);
        i += 1;
    }
    return buf[0..i];
}

fn check_cap(ray: Ray, t: Float) bool {
    const x = ray.origin.x + t * ray.direction.x;
    const z = ray.origin.z + t * ray.direction.z;
    return std.math.pow(f32, x, 2) + std.math.pow(f32, z, 2) <= 1;
}

test "A ray misses a cylinder" {
    const cyl = Object.cylinder();
    for ([_]struct { Tuple, Tuple }{
        .{ Tuple.point(1, 0, 0), Tuple.vector(0, 1, 0) },
        .{ Tuple.point(0, 0, 0), Tuple.vector(0, 1, 0) },
        .{ Tuple.point(0, 0, -5), Tuple.vector(1, 1, 1) },
    }) |example| {
        const r = Ray.init(example[0], example[1]);
        var buf = [_]Intersection{undefined} ** 10;
        const xs = cyl.intersect(r, &buf);
        try std.testing.expectEqual(0, xs.len);
    }
}

test "A ray strikes a cylinder" {
    const cyl = Object.cylinder();
    for ([_]struct { Tuple, Tuple, Float, Float }{
        .{ Tuple.point(1, 0, -5), Tuple.vector(0, 0, 1), 5, 5 },
        .{ Tuple.point(0, 0, -5), Tuple.vector(0, 0, 1), 4, 6 },
        .{ Tuple.point(0.5, 0, -5), Tuple.vector(0.1, 1, 1), 4.80198, 4.99999 },
    }) |example| {
        const r = Ray.init(example[0], example[1]);
        var buf = [_]Intersection{undefined} ** 10;
        const xs = cyl.intersect(r, &buf);
        try std.testing.expectEqual(2, xs.len);
        try floats.expectEqual(example[2], xs[0].t);
        try floats.expectEqual(example[3], xs[1].t);
    }
}

test "Intersecting a constrained cylinder" {
    const cyl = Object.cylinder().truncate(1, 2, false);
    for ([_]struct { Tuple, Tuple, usize }{
        .{ Tuple.point(0, 1.5, 0), Tuple.vector(0.1, 1, 0), 0 },
        .{ Tuple.point(0, 3, -5), Tuple.vector(0, 0, 1), 0 },
        .{ Tuple.point(0, 0, -5), Tuple.vector(0, 0, 1), 0 },
        .{ Tuple.point(0, 2, -5), Tuple.vector(0, 0, 1), 0 },
        .{ Tuple.point(0, 1, -5), Tuple.vector(0, 0, 1), 0 },
        .{ Tuple.point(0, 1.5, -2), Tuple.vector(0, 0, 1), 2 },
    }) |example| {
        const r = Ray.init(example[0], example[1]);
        var buf = [_]Intersection{undefined} ** 10;
        const xs = cyl.intersect(r, &buf);
        try std.testing.expectEqual(example[2], xs.len);
    }
}

test "Intersecting the caps of a closed cylinder" {
    const cyl = Object.cylinder().truncate(1, 2, true);
    for ([_]struct { Tuple, Tuple, usize }{
        .{ Tuple.point(0, 3, 0), Tuple.vector(0, -1, 0), 2 },
        .{ Tuple.point(0, 3, -2), Tuple.vector(0, -1, 2), 2 },
        .{ Tuple.point(0, 4, -2), Tuple.vector(0, -1, 1), 2 },
        .{ Tuple.point(0, 0, -2), Tuple.vector(0, 1, 2), 2 },
        .{ Tuple.point(0, -1, -2), Tuple.vector(0, 1, 1), 2 },
    }) |example| {
        const r = Ray.init(example[0], example[1]);
        var buf = [_]Intersection{undefined} ** 10;
        const xs = cyl.intersect(r, &buf);
        try std.testing.expectEqual(example[2], xs.len);
    }
}

pub fn local_normal_at(self: Cylinder, point: Tuple) Tuple {
    const dist = std.math.pow(f32, point.x, 2) + std.math.pow(f32, point.z, 2);
    if (dist < 1 and point.y >= self.maximum - floats.EPSILON) return Tuple.vector(0, 1, 0);
    if (dist < 1 and point.y <= self.minimum + floats.EPSILON) return Tuple.vector(0, -1, 0);
    return Tuple.vector(point.x, 0, point.z);
}

test "Normal vector on a cylinder" {
    const cyl = Object.cylinder();
    for ([_]struct { Tuple, Tuple }{
        .{ Tuple.point(1, 0, 0), Tuple.vector(1, 0, 0) },
        .{ Tuple.point(0, 5, -1), Tuple.vector(0, 0, -1) },
        .{ Tuple.point(0, -2, 1), Tuple.vector(0, 0, 1) },
        .{ Tuple.point(-1, 1, 0), Tuple.vector(-1, 0, 0) },
    }) |example| {
        const n = cyl.normal_at(example[0]);
        try Tuple.expectEqual(example[1], n);
    }
}

test "The normal vector on a cylinder's end caps" {
    const cyl = Object.cylinder().truncate(1, 2, true);
    for ([_]struct { Tuple, Tuple }{
        .{ Tuple.point(0, 1, 0), Tuple.vector(0, -1, 0) },
        .{ Tuple.point(0.5, 1, 0), Tuple.vector(0, -1, 0) },
        .{ Tuple.point(0, 1, 0.5), Tuple.vector(0, -1, 0) },
        .{ Tuple.point(0, 2, 0), Tuple.vector(0, 1, 0) },
        .{ Tuple.point(0.5, 2, 0), Tuple.vector(0, 1, 0) },
        .{ Tuple.point(0, 2, 0.5), Tuple.vector(0, 1, 0) },
    }) |example| {
        const n = cyl.normal_at(example[0]);
        try Tuple.expectEqual(example[1], n);
    }
}
