const std = @import("std");
const floats = @import("floats.zig");
const Float = floats.Float;
const Intersection = @This();
const Ray = @import("Ray.zig");
const Sphere = @import("Sphere.zig");
const transformations = @import("transformations.zig");
const Tuple = @import("Tuple.zig");

t: Float,
object: *const Sphere,

pub fn init(t: Float, object: *const Sphere) Intersection {
    return Intersection{
        .t = t,
        .object = object,
    };
}

test "An intersection encapsulates t and object" {
    const s = Sphere.init();
    const i = init(3.5, &s);
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
    const s = Sphere.init();
    const int1 = init(1, &s);
    const int2 = init(2, &s);
    const xs = [_]Intersection{ int2, int1 };
    const i = hit(&xs);
    try std.testing.expectEqual(xs[1], i);
}

test "The hit, when some intersections have negative t" {
    const s = Sphere.init();
    const int1 = init(-1, &s);
    const int2 = init(1, &s);
    const xs = [_]Intersection{ int2, int1 };
    const i = hit(&xs);
    try std.testing.expectEqual(xs[0], i);
}

test "The hit, when all intersections have negative t" {
    const s = Sphere.init();
    const int1 = init(-2, &s);
    const int2 = init(-1, &s);
    const xs = [_]Intersection{ int2, int1 };
    const i = hit(&xs);
    try std.testing.expectEqual(null, i);
}

test hit {
    // The hit is always the lowest nonnegative intersection
    const s = Sphere.init();
    const int1 = init(5, &s);
    const int2 = init(7, &s);
    const int3 = init(-3, &s);
    const int4 = init(2, &s);
    const xs = [_]Intersection{ int1, int2, int3, int4 };
    const i = hit(&xs);
    try std.testing.expectEqual(xs[3], i);
}

pub const Computations = struct {
    inside: bool,
    point: Tuple,
    over_point: Tuple,
    eyev: Tuple,
    normalv: Tuple,
};

/// Prepares computations for a ray-shape intersection
pub fn prepare_computations(i: Intersection, r: Ray) Computations {
    const point = r.position(i.t);
    const eyev = r.direction.normalize().neg();
    const normalv = i.object.normal_at(point).normalize();
    var comps = Computations{
        .inside = false,
        .point = point,
        .over_point = point,
        .eyev = eyev,
        .normalv = normalv,
    };
    if (comps.normalv.dot(comps.eyev) < 0) {
        comps.inside = true;
        comps.normalv = comps.normalv.neg();
    }
    comps.over_point = comps.point.add(comps.normalv.muls(floats.EPSILON * 10));
    return comps;
}

test prepare_computations {
    const r = Ray.init(Tuple.point(0, 0, -5), Tuple.vector(0, 0, 1));
    const shape = Sphere.init();
    const i = init(4, &shape);
    const comps = prepare_computations(i, r);
    try Tuple.expectEqual(Tuple.point(0, 0, -1), comps.point);
    try Tuple.expectEqual(Tuple.vector(0, 0, -1), comps.eyev);
    try Tuple.expectEqual(Tuple.vector(0, 0, -1), comps.normalv);
}

test "The hit, when an intersection occurs on the outside" {
    const r = Ray.init(Tuple.point(0, 0, -5), Tuple.vector(0, 0, 1));
    const shape = Sphere.init();
    const i = init(4, &shape);
    const comps = prepare_computations(i, r);
    try std.testing.expectEqual(false, comps.inside);
}

test "The hit, when an intersection occurs on the inside" {
    const r = Ray.init(Tuple.point(0, 0, 0), Tuple.vector(0, 0, 1));
    const shape = Sphere.init();
    const i = init(1, &shape);
    const comps = prepare_computations(i, r);
    try std.testing.expectEqual(true, comps.inside);
    try Tuple.expectEqual(Tuple.point(0, 0, 1), comps.point);
    try Tuple.expectEqual(Tuple.vector(0, 0, -1), comps.eyev);
    try Tuple.expectEqual(Tuple.vector(0, 0, -1), comps.normalv);
}

test "The hit should offset the point" {
    const r = Ray.init(Tuple.point(0, 0, -5), Tuple.vector(0, 0, 1));
    var shape = Sphere.init();
    shape.transform = transformations.translation(0, 0, 1);
    const i = init(5, &shape);
    const comps = prepare_computations(i, r);
    try std.testing.expect(comps.over_point.z < -floats.EPSILON / 2);
    try std.testing.expect(comps.point.z > comps.over_point.z);
}
