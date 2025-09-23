const std = @import("std");
const floats = @import("floats.zig");
const Float = floats.Float;
const intersections = @import("intersections.zig");
const Intersection = intersections.Intersection;
const materials = @import("materials.zig");
const matrices = @import("matrices.zig");
const Matrix = matrices.Matrix;
const rays = @import("rays.zig");
const Ray = rays.Ray;
const transformations = @import("transformations.zig");
const tuples = @import("tuples.zig");

pub const Sphere = struct {
    material: materials.Material,
    transform: Matrix,
};

pub fn sphere() Sphere {
    return Sphere{
        .material = materials.material(),
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

/// The normal on a sphere at point
pub fn normal_at(s: Sphere, world_point: tuples.Tuple) tuples.Tuple {
    const local_point = matrices.mult(matrices.inverse(s.transform), world_point);
    const local_normal = tuples.sub(local_point, tuples.point(0, 0, 0));
    var world_normal = matrices.mult(matrices.transpose(matrices.inverse(s.transform)), local_normal);
    tuples.to_vector(&world_normal);
    return tuples.normalize(world_normal);
}

test normal_at {
    const s = sphere();
    const n = normal_at(s, tuples.point(floats.sqrt3 / 3, floats.sqrt3 / 3, floats.sqrt3 / 3));
    try tuples.expectEqual(tuples.vector(floats.sqrt3 / 3, floats.sqrt3 / 3, floats.sqrt3 / 3), n);
}

test "The normal on a sphere at a point on the x axis" {
    const s = sphere();
    const n = normal_at(s, tuples.point(1, 0, 0));
    try tuples.expectEqual(tuples.vector(1, 0, 0), n);
}

test "The normal on a sphere at a point on the y axis" {
    const s = sphere();
    const n = normal_at(s, tuples.point(0, 1, 0));
    try tuples.expectEqual(tuples.vector(0, 1, 0), n);
}

test "The normal on a sphere at a point on the z axis" {
    const s = sphere();
    const n = normal_at(s, tuples.point(0, 0, 1));
    try tuples.expectEqual(tuples.vector(0, 0, 1), n);
}

test "The normal is a normalized vector" {
    const s = sphere();
    const n = normal_at(s, tuples.point(floats.sqrt3 / 3, floats.sqrt3 / 3, floats.sqrt3 / 3));
    try tuples.expectEqual(tuples.normalize(n), n);
}

test "Computing the normal on a translated sphere" {
    var s = sphere();
    s.transform = transformations.translation(0, 1, 0);
    const n = normal_at(s, tuples.point(0, 1.70711, -0.70711));
    try tuples.expectEqual(tuples.vector(0, 0.70711, -0.70711), n);
}

test "Computing the normal on a transformed sphere" {
    var s = sphere();
    s.transform = matrices.mul(transformations.scaling(1, 0.5, 1), transformations.rotation_z(floats.pi / 5));
    const n = normal_at(s, tuples.point(0, floats.sqrt2 / 2, -floats.sqrt2 / 2));
    try tuples.expectEqual(tuples.vector(0, 0.97014, -0.24254), n);
}

test "A sphere has a default material" {
    const s = sphere();
    try std.testing.expectEqual(materials.material(), s.material);
}

test "A sphere may be assigned a material" {
    var s = sphere();
    var m = materials.material();
    m.ambient = 1;
    s.material = m;
    try std.testing.expectEqual(m, s.material);
}
