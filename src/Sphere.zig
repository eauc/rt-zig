const std = @import("std");
const floats = @import("floats.zig");
const Float = floats.Float;
const Intersection = @import("Intersection.zig");
const Material = @import("Material.zig");
const Matrix = @import("Matrix.zig");
const Ray = @import("Ray.zig");
const Sphere = @This();
const transformations = @import("transformations.zig");
const Tuple = @import("Tuple.zig");

material: Material,
transform: Matrix,

pub fn init() Sphere {
    return Sphere{
        .material = Material.init(),
        .transform = Matrix.identity(),
    };
}

/// Intersects a ray with a sphere
pub fn intersect(s: *const Sphere, ray: Ray, buf: []Intersection) []Intersection {
    const local_ray = ray.transform(s.transform.inverse());
    const sphere_to_ray = local_ray.origin.sub(Tuple.point(0, 0, 0));
    const a = Tuple.dot(local_ray.direction, local_ray.direction);
    const b = 2 * Tuple.dot(local_ray.direction, sphere_to_ray);
    const c = Tuple.dot(sphere_to_ray, sphere_to_ray) - 1;
    const discriminant = b * b - 4 * a * c;
    if (discriminant < 0) {
        return buf[0..0];
    }
    const t1 = (-b - std.math.sqrt(discriminant)) / (2 * a);
    const t2 = (-b + std.math.sqrt(discriminant)) / (2 * a);
    buf[0] = Intersection.init(t1, s);
    buf[1] = Intersection.init(t2, s);
    return buf[0..2];
}

test intersect {
    // A ray intersects a sphere at two points
    const r = Ray.init(Tuple.point(0, 0, -5), Tuple.vector(0, 0, 1));
    const s = init();

    var buf = [_]Intersection{undefined} ** 10;
    const xs = intersect(&s, r, &buf);
    try std.testing.expectEqual(2, xs.len);
    try floats.expectEqual(4.0, xs[0].t);
    try floats.expectEqual(6.0, xs[1].t);
}

test "A ray intersects a sphere at a tangent" {
    const r = Ray.init(Tuple.point(0, 1, -5), Tuple.vector(0, 0, 1));
    const s = init();

    var buf = [_]Intersection{undefined} ** 10;
    const xs = intersect(&s, r, &buf);
    try std.testing.expectEqual(2, xs.len);
    try floats.expectEqual(5.0, xs[0].t);
    try floats.expectEqual(5.0, xs[1].t);
}

test "A ray misses a sphere" {
    const r = Ray.init(Tuple.point(0, 2, -5), Tuple.vector(0, 0, 1));
    const s = init();

    var buf = [_]Intersection{undefined} ** 10;
    const xs = intersect(&s, r, &buf);
    try std.testing.expectEqual(0, xs.len);
}

test "A ray originates inside a sphere" {
    const r = Ray.init(Tuple.point(0, 0, 0), Tuple.vector(0, 0, 1));
    const s = init();

    var buf = [_]Intersection{undefined} ** 10;
    const xs = intersect(&s, r, &buf);
    try std.testing.expectEqual(2, xs.len);
    try floats.expectEqual(-1.0, xs[0].t);
    try floats.expectEqual(1.0, xs[1].t);
}

test "A sphere is behind a ray" {
    const r = Ray.init(Tuple.point(0, 0, 5), Tuple.vector(0, 0, 1));
    const s = init();

    var buf = [_]Intersection{undefined} ** 10;
    const xs = intersect(&s, r, &buf);
    try std.testing.expectEqual(2, xs.len);
    try floats.expectEqual(-6.0, xs[0].t);
    try floats.expectEqual(-4.0, xs[1].t);
}

test "Intersect sets the object on the intersection" {
    const r = Ray.init(Tuple.point(0, 0, -5), Tuple.vector(0, 0, 1));
    const s = init();

    var buf = [_]Intersection{undefined} ** 10;
    const xs = intersect(&s, r, &buf);
    try std.testing.expectEqual(2, xs.len);
    try std.testing.expectEqual(&s, xs[0].object);
    try std.testing.expectEqual(&s, xs[1].object);
}

test "A sphere has a default transformation" {
    const s = init();
    try Matrix.expectEqual(Matrix.identity(), s.transform);
}

test "Changing a sphere's transformation" {
    var s = init();
    const t = transformations.translation(2, 3, 4);
    s.transform = t;
    try Matrix.expectEqual(t, s.transform);
}

test "Intersecting a scaled sphere with a ray" {
    const r = Ray.init(Tuple.point(0, 0, -5), Tuple.vector(0, 0, 1));
    var s = init();
    s.transform = transformations.scaling(2, 2, 2);

    var buf = [_]Intersection{undefined} ** 10;
    const xs = intersect(&s, r, &buf);
    try std.testing.expectEqual(2, xs.len);
    try floats.expectEqual(3, xs[0].t);
    try floats.expectEqual(7, xs[1].t);
}

test "Intersecting a translated sphere with a ray" {
    const r = Ray.init(Tuple.point(0, 0, -5), Tuple.vector(0, 0, 1));
    var s = init();
    s.transform = transformations.translation(5, 0, 0);

    var buf = [_]Intersection{undefined} ** 10;
    const xs = intersect(&s, r, &buf);
    try std.testing.expectEqual(0, xs.len);
}

/// The normal on a sphere at point
pub fn normal_at(s: Sphere, world_point: Tuple) Tuple {
    const local_point = s.transform.inverse().mult(world_point);
    const local_normal = local_point.sub(Tuple.point(0, 0, 0));
    var world_normal = s.transform.inverse().transpose().mult(local_normal);
    world_normal.to_vector();
    return world_normal.normalize();
}

test normal_at {
    const s = init();
    const n = normal_at(s, Tuple.point(floats.sqrt3 / 3, floats.sqrt3 / 3, floats.sqrt3 / 3));
    try Tuple.expectEqual(Tuple.vector(floats.sqrt3 / 3, floats.sqrt3 / 3, floats.sqrt3 / 3), n);
}

test "The normal on a sphere at a point on the x axis" {
    const s = init();
    const n = normal_at(s, Tuple.point(1, 0, 0));
    try Tuple.expectEqual(Tuple.vector(1, 0, 0), n);
}

test "The normal on a sphere at a point on the y axis" {
    const s = init();
    const n = normal_at(s, Tuple.point(0, 1, 0));
    try Tuple.expectEqual(Tuple.vector(0, 1, 0), n);
}

test "The normal on a sphere at a point on the z axis" {
    const s = init();
    const n = normal_at(s, Tuple.point(0, 0, 1));
    try Tuple.expectEqual(Tuple.vector(0, 0, 1), n);
}

test "The normal is a normalized vector" {
    const s = init();
    const n = normal_at(s, Tuple.point(floats.sqrt3 / 3, floats.sqrt3 / 3, floats.sqrt3 / 3));
    try Tuple.expectEqual(n, n.normalize());
}

test "Computing the normal on a translated sphere" {
    var s = init();
    s.transform = transformations.translation(0, 1, 0);
    const n = normal_at(s, Tuple.point(0, 1.70711, -0.70711));
    try Tuple.expectEqual(Tuple.vector(0, 0.70711, -0.70711), n);
}

test "Computing the normal on a transformed sphere" {
    var s = init();
    s.transform = Matrix.mul(transformations.scaling(1, 0.5, 1), transformations.rotation_z(floats.pi / 5));
    const n = normal_at(s, Tuple.point(0, floats.sqrt2 / 2, -floats.sqrt2 / 2));
    try Tuple.expectEqual(Tuple.vector(0, 0.97014, -0.24254), n);
}

test "A sphere has a default material" {
    const s = init();
    try std.testing.expectEqual(Material.init(), s.material);
}

test "A sphere may be assigned a material" {
    var s = init();
    var m = Material.init();
    m.ambient = 1;
    s.material = m;
    try std.testing.expectEqual(m, s.material);
}
