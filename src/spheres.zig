const std = @import("std");
const floats = @import("floats.zig");
const Float = floats.Float;
const intersections = @import("intersections.zig");
const Intersection = intersections.Intersection;
const matrices = @import("matrices.zig");
const Matrix = matrices.Matrix;
const rays = @import("rays.zig");
const Ray = rays.Ray;
const transformations = @import("transformations.zig");
const tuples = @import("tuples.zig");

pub const Sphere = struct {
    transform: Matrix,
};

pub fn sphere() Sphere {
    return Sphere{
        .transform = matrices.identity(),
    };
}

/// Intersects a ray with a sphere
pub fn intersect(s: *const Sphere, ray: Ray, buf: []Intersection) []Intersection {
    const local_ray = rays.transform(ray, matrices.inverse(s.transform));
    const sphere_to_ray = tuples.sub(local_ray.origin, tuples.point(0, 0, 0));
    const a = tuples.dot(local_ray.direction, local_ray.direction);
    const b = 2 * tuples.dot(local_ray.direction, sphere_to_ray);
    const c = tuples.dot(sphere_to_ray, sphere_to_ray) - 1;
    const discriminant = b * b - 4 * a * c;
    if (discriminant < 0) {
        return buf[0..0];
    }
    const t1 = (-b - std.math.sqrt(discriminant)) / (2 * a);
    const t2 = (-b + std.math.sqrt(discriminant)) / (2 * a);
    buf[0] = intersections.intersection(t1, s);
    buf[1] = intersections.intersection(t2, s);
    return buf[0..2];
}

test intersect {
    // A ray intersects a sphere at two points
    const r = rays.ray(tuples.point(0, 0, -5), tuples.vector(0, 0, 1));
    const s = sphere();

    var buf = [_]Intersection{undefined} ** 10;
    const xs = intersect(&s, r, &buf);
    try std.testing.expectEqual(2, xs.len);
    try floats.expectEqual(4.0, xs[0].t);
    try floats.expectEqual(6.0, xs[1].t);
}

test "A ray intersects a sphere at a tangent" {
    const r = rays.ray(tuples.point(0, 1, -5), tuples.vector(0, 0, 1));
    const s = sphere();

    var buf = [_]Intersection{undefined} ** 10;
    const xs = intersect(&s, r, &buf);
    try std.testing.expectEqual(2, xs.len);
    try floats.expectEqual(5.0, xs[0].t);
    try floats.expectEqual(5.0, xs[1].t);
}

test "A ray misses a sphere" {
    const r = rays.ray(tuples.point(0, 2, -5), tuples.vector(0, 0, 1));
    const s = sphere();

    var buf = [_]Intersection{undefined} ** 10;
    const xs = intersect(&s, r, &buf);
    try std.testing.expectEqual(0, xs.len);
}

test "A ray originates inside a sphere" {
    const r = rays.ray(tuples.point(0, 0, 0), tuples.vector(0, 0, 1));
    const s = sphere();

    var buf = [_]Intersection{undefined} ** 10;
    const xs = intersect(&s, r, &buf);
    try std.testing.expectEqual(2, xs.len);
    try floats.expectEqual(-1.0, xs[0].t);
    try floats.expectEqual(1.0, xs[1].t);
}

test "A sphere is behind a ray" {
    const r = rays.ray(tuples.point(0, 0, 5), tuples.vector(0, 0, 1));
    const s = sphere();

    var buf = [_]Intersection{undefined} ** 10;
    const xs = intersect(&s, r, &buf);
    try std.testing.expectEqual(2, xs.len);
    try floats.expectEqual(-6.0, xs[0].t);
    try floats.expectEqual(-4.0, xs[1].t);
}

test "Intersect sets the object on the intersection" {
    const r = rays.ray(tuples.point(0, 0, -5), tuples.vector(0, 0, 1));
    const s = sphere();

    var buf = [_]Intersection{undefined} ** 10;
    const xs = intersect(&s, r, &buf);
    try std.testing.expectEqual(2, xs.len);
    try std.testing.expectEqual(&s, xs[0].object);
    try std.testing.expectEqual(&s, xs[1].object);
}

test "A sphere has a default transformation" {
    const s = sphere();
    try matrices.expectEqual(matrices.identity(), s.transform);
}

test "Changing a sphere's transformation" {
    var s = sphere();
    const t = transformations.translation(2, 3, 4);
    s.transform = t;
    try matrices.expectEqual(t, s.transform);
}

test "Intersecting a scaled sphere with a ray" {
    const r = rays.ray(tuples.point(0, 0, -5), tuples.vector(0, 0, 1));
    var s = sphere();
    s.transform = transformations.scaling(2, 2, 2);

    var buf = [_]Intersection{undefined} ** 10;
    const xs = intersect(&s, r, &buf);
    try std.testing.expectEqual(2, xs.len);
    try floats.expectEqual(3, xs[0].t);
    try floats.expectEqual(7, xs[1].t);
}

test "Intersecting a translated sphere with a ray" {
    const r = rays.ray(tuples.point(0, 0, -5), tuples.vector(0, 0, 1));
    var s = sphere();
    s.transform = transformations.translation(5, 0, 0);

    var buf = [_]Intersection{undefined} ** 10;
    const xs = intersect(&s, r, &buf);
    try std.testing.expectEqual(0, xs.len);
}
