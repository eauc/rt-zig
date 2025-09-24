const std = @import("std");
const floats = @import("floats.zig");
const Float = floats.Float;
const rays = @import("rays.zig");
const Ray = rays.Ray;
const spheres = @import("spheres.zig");
const Sphere = spheres.Sphere;
const tuples = @import("tuples.zig");

pub const Intersection = struct {
    t: Float,
    object: *const Sphere,
};

pub fn intersection(t: Float, object: *const Sphere) Intersection {
    return Intersection{
        .t = t,
        .object = object,
    };
}

test "An intersection encapsulates t and object" {
    const s = spheres.sphere();
    const i = intersection(3.5, &s);
    try std.testing.expectEqual(3.5, i.t);
    try std.testing.expectEqual(&s, i.object);
}

fn less_than(_: void, a: Intersection, b: Intersection) bool {
    return a.t < b.t;
}

/// Sort intersections by t
pub fn sort(intersections: []Intersection) void {
    std.mem.sort(Intersection, intersections, {}, less_than);
}

/// Finds the first hit in a set of intersections
pub fn hit(intersections: []const Intersection) ?Intersection {
    var h: ?Intersection = null;
    var t_min: Float = std.math.inf(Float);
    for (intersections) |i| {
        if (i.t > 0 and i.t < t_min) {
            t_min = i.t;
            h = i;
        }
    }
    return h;
}

test "The hit, when all intersections have positive t" {
    const s = spheres.sphere();
    const int1 = intersection(1, &s);
    const int2 = intersection(2, &s);
    const xs = [_]Intersection{ int2, int1 };
    const i = hit(&xs);
    try std.testing.expectEqual(xs[1], i);
}

test "The hit, when some intersections have negative t" {
    const s = spheres.sphere();
    const int1 = intersection(-1, &s);
    const int2 = intersection(1, &s);
    const xs = [_]Intersection{ int2, int1 };
    const i = hit(&xs);
    try std.testing.expectEqual(xs[0], i);
}

test "The hit, when all intersections have negative t" {
    const s = spheres.sphere();
    const int1 = intersection(-2, &s);
    const int2 = intersection(-1, &s);
    const xs = [_]Intersection{ int2, int1 };
    const i = hit(&xs);
    try std.testing.expectEqual(null, i);
}

test hit {
    // The hit is always the lowest nonnegative intersection
    const s = spheres.sphere();
    const int1 = intersection(5, &s);
    const int2 = intersection(7, &s);
    const int3 = intersection(-3, &s);
    const int4 = intersection(2, &s);
    const xs = [_]Intersection{ int1, int2, int3, int4 };
    const i = hit(&xs);
    try std.testing.expectEqual(xs[3], i);
}

pub const Computations = struct {
    inside: bool,
    point: tuples.Tuple,
    eyev: tuples.Tuple,
    normalv: tuples.Tuple,
};

/// Prepares computations for a ray-shape intersection
pub fn prepare_computations(i: Intersection, r: Ray) Computations {
    const point = rays.position(r, i.t);
    const eyev = tuples.neg(tuples.normalize(r.direction));
    const normalv = tuples.normalize(spheres.normal_at(i.object.*, point));
    var comps = Computations{
        .inside = false,
        .point = point,
        .eyev = eyev,
        .normalv = normalv,
    };
    if (tuples.dot(comps.normalv, comps.eyev) < 0) {
        comps.inside = true;
        comps.normalv = tuples.neg(comps.normalv);
    }
    return comps;
}

test prepare_computations {
    const r = rays.ray(tuples.point(0, 0, -5), tuples.vector(0, 0, 1));
    const shape = spheres.sphere();
    const i = intersection(4, &shape);
    const comps = prepare_computations(i, r);
    try tuples.expectEqual(tuples.point(0, 0, -1), comps.point);
    try tuples.expectEqual(tuples.vector(0, 0, -1), comps.eyev);
    try tuples.expectEqual(tuples.vector(0, 0, -1), comps.normalv);
}

test "The hit, when an intersection occurs on the outside" {
    const r = rays.ray(tuples.point(0, 0, -5), tuples.vector(0, 0, 1));
    const shape = spheres.sphere();
    const i = intersection(4, &shape);
    const comps = prepare_computations(i, r);
    try std.testing.expectEqual(false, comps.inside);
}

test "The hit, when an intersection occurs on the inside" {
    const r = rays.ray(tuples.point(0, 0, 0), tuples.vector(0, 0, 1));
    const shape = spheres.sphere();
    const i = intersection(1, &shape);
    const comps = prepare_computations(i, r);
    try std.testing.expectEqual(true, comps.inside);
    try tuples.expectEqual(tuples.point(0, 0, 1), comps.point);
    try tuples.expectEqual(tuples.vector(0, 0, -1), comps.eyev);
    try tuples.expectEqual(tuples.vector(0, 0, -1), comps.normalv);
}
