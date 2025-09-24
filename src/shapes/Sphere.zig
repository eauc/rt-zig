const std = @import("std");
const floats = @import("../floats.zig");
const Float = floats.Float;
const Intersection = @import("../Intersection.zig");
const Material = @import("../Material.zig");
const Matrix = @import("../Matrix.zig");
const Object = @import("../Object.zig");
const Ray = @import("../Ray.zig");
const Sphere = @This();
const transformations = @import("../transformations.zig");
const Tuple = @import("../Tuple.zig");

pub fn init() Sphere {
    return Sphere{};
}

/// Intersects a ray with a sphere
pub fn local_intersect(_: *const Sphere, ray: Ray, object: *const Object, buf: []Intersection) []Intersection {
    const sphere_to_ray = ray.origin.sub(Tuple.point(0, 0, 0));
    const a = Tuple.dot(ray.direction, ray.direction);
    const b = 2 * Tuple.dot(ray.direction, sphere_to_ray);
    const c = Tuple.dot(sphere_to_ray, sphere_to_ray) - 1;
    const discriminant = b * b - 4 * a * c;
    if (discriminant < 0) {
        return buf[0..0];
    }
    const t1 = (-b - std.math.sqrt(discriminant)) / (2 * a);
    const t2 = (-b + std.math.sqrt(discriminant)) / (2 * a);
    buf[0] = Intersection.init(t1, object);
    buf[1] = Intersection.init(t2, object);
    return buf[0..2];
}

test local_intersect {
    // A ray intersects a sphere at two points
    const r = Ray.init(Tuple.point(0, 0, -5), Tuple.vector(0, 0, 1));
    const s = Object.sphere();

    var buf = [_]Intersection{undefined} ** 10;
    const xs = s.shape.local_intersect(r, &s, &buf);
    try std.testing.expectEqual(2, xs.len);
    try floats.expectEqual(4.0, xs[0].t);
    try floats.expectEqual(6.0, xs[1].t);
}

test "A ray intersects a sphere at a tangent" {
    const r = Ray.init(Tuple.point(0, 1, -5), Tuple.vector(0, 0, 1));
    const s = Object.sphere();

    var buf = [_]Intersection{undefined} ** 10;
    const xs = s.shape.local_intersect(r, &s, &buf);
    try std.testing.expectEqual(2, xs.len);
    try floats.expectEqual(5.0, xs[0].t);
    try floats.expectEqual(5.0, xs[1].t);
}

test "A ray misses a sphere" {
    const r = Ray.init(Tuple.point(0, 2, -5), Tuple.vector(0, 0, 1));
    const s = Object.sphere();

    var buf = [_]Intersection{undefined} ** 10;
    const xs = s.shape.local_intersect(r, &s, &buf);
    try std.testing.expectEqual(0, xs.len);
}

test "A ray originates inside a sphere" {
    const r = Ray.init(Tuple.point(0, 0, 0), Tuple.vector(0, 0, 1));
    const s = Object.sphere();

    var buf = [_]Intersection{undefined} ** 10;
    const xs = s.shape.local_intersect(r, &s, &buf);
    try std.testing.expectEqual(2, xs.len);
    try floats.expectEqual(-1.0, xs[0].t);
    try floats.expectEqual(1.0, xs[1].t);
}

test "A sphere is behind a ray" {
    const r = Ray.init(Tuple.point(0, 0, 5), Tuple.vector(0, 0, 1));
    const s = Object.sphere();

    var buf = [_]Intersection{undefined} ** 10;
    const xs = s.shape.local_intersect(r, &s, &buf);
    try std.testing.expectEqual(2, xs.len);
    try floats.expectEqual(-6.0, xs[0].t);
    try floats.expectEqual(-4.0, xs[1].t);
}

/// The normal on a sphere at point
pub fn local_normal_at(_: Sphere, local_point: Tuple) Tuple {
    return local_point.sub(Tuple.point(0, 0, 0));
}

test local_normal_at {
    const s = init();
    const n = s.local_normal_at(Tuple.point(floats.sqrt3 / 3, floats.sqrt3 / 3, floats.sqrt3 / 3));
    try Tuple.expectEqual(Tuple.vector(floats.sqrt3 / 3, floats.sqrt3 / 3, floats.sqrt3 / 3), n);
}

test "The normal on a sphere at a point on the x axis" {
    const s = init();
    const n = s.local_normal_at(Tuple.point(1, 0, 0));
    try Tuple.expectEqual(Tuple.vector(1, 0, 0), n);
}

test "The normal on a sphere at a point on the y axis" {
    const s = init();
    const n = s.local_normal_at(Tuple.point(0, 1, 0));
    try Tuple.expectEqual(Tuple.vector(0, 1, 0), n);
}

test "The normal on a sphere at a point on the z axis" {
    const s = init();
    const n = s.local_normal_at(Tuple.point(0, 0, 1));
    try Tuple.expectEqual(Tuple.vector(0, 0, 1), n);
}
