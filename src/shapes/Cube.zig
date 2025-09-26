const std = @import("std");
const Cube = @This();
const floats = @import("../floats.zig");
const Float = floats.Float;
const Intersection = @import("../Intersection.zig");
const Object = @import("../Object.zig");
const Ray = @import("../Ray.zig");
const Tuple = @import("../Tuple.zig");

pub fn init() Cube {
    return Cube{};
}

pub fn local_intersect(_: Cube, ray: Ray, object: *const Object, buf: []Intersection) []Intersection {
    const xtmin, const xtmax = check_axis(ray.origin.x, ray.direction.x);
    const ytmin, const ytmax = check_axis(ray.origin.y, ray.direction.y);
    const ztmin, const ztmax = check_axis(ray.origin.z, ray.direction.z);

    const tmin = @max(xtmin, @max(ytmin, ztmin));
    const tmax = @min(xtmax, @min(ytmax, ztmax));
    if (tmin > tmax) {
        return buf[0..0];
    }

    buf[0] = Intersection.init(tmin, object);
    buf[1] = Intersection.init(tmax, object);
    return buf[0..2];
}

fn check_axis(origin: Float, direction: Float) struct { Float, Float } {
    const tmin_numerator = -1 - origin;
    const tmax_numerator = 1 - origin;
    var tmin: Float = 0;
    var tmax: Float = 0;
    if (floats.equals(@abs(direction), 0)) {
        tmin = tmin_numerator * std.math.inf(Float);
        tmax = tmax_numerator * std.math.inf(Float);
    } else {
        tmin = tmin_numerator / direction;
        tmax = tmax_numerator / direction;
    }
    if (tmin > tmax) {
        return .{ tmax, tmin };
    }
    return .{ tmin, tmax };
}

test "A ray intersects a cube" {
    const c = Object.cube();
    var buf = [_]Intersection{undefined} ** 10;
    for ([_]struct { Tuple, Tuple, Float, Float }{
        .{ Tuple.point(5, 0.5, 0), Tuple.vector(-1, 0, 0), 4, 6 },
        .{ Tuple.point(-5, 0.5, 0), Tuple.vector(1, 0, 0), 4, 6 },
        .{ Tuple.point(0.5, 5, 0), Tuple.vector(0, -1, 0), 4, 6 },
        .{ Tuple.point(0.5, -5, 0), Tuple.vector(0, 1, 0), 4, 6 },
        .{ Tuple.point(0.5, 0, 5), Tuple.vector(0, 0, -1), 4, 6 },
        .{ Tuple.point(0.5, 0, -5), Tuple.vector(0, 0, 1), 4, 6 },
        .{ Tuple.point(0, 0.5, 0), Tuple.vector(0, 0, 1), -1, 1 },
    }) |example| {
        const r = Ray.init(example[0], example[1]);
        const xs = c.intersect(r, &buf);
        try std.testing.expectEqual(2, xs.len);
        try floats.expectEqual(example[2], xs[0].t);
        try floats.expectEqual(example[3], xs[1].t);
    }
}

test "A ray misses a cube" {
    const c = Object.cube();
    var buf = [_]Intersection{undefined} ** 10;
    for ([_]struct { Tuple, Tuple }{
        .{ Tuple.point(-2, 0, 0), Tuple.vector(0.2673, 0.5345, 0.8018) },
        .{ Tuple.point(0, -2, 0), Tuple.vector(0.8018, 0.2673, 0.5345) },
        .{ Tuple.point(0, 0, -2), Tuple.vector(0.5345, 0.8018, 0.2673) },
        .{ Tuple.point(2, 0, 2), Tuple.vector(0, 0, -1) },
        .{ Tuple.point(0, 2, 2), Tuple.vector(0, -1, 0) },
        .{ Tuple.point(2, 2, 0), Tuple.vector(-1, 0, 0) },
    }) |example| {
        const r = Ray.init(example[0], example[1]);
        const xs = c.intersect(r, &buf);
        try std.testing.expectEqual(0, xs.len);
    }
}

pub fn local_normal_at(_: Cube, local_point: Tuple) Tuple {
    const maxc = @max(@abs(local_point.x), @max(@abs(local_point.y), @abs(local_point.z)));
    if (maxc == @abs(local_point.x)) {
        return Tuple.vector(local_point.x, 0, 0);
    }
    if (maxc == @abs(local_point.y)) {
        return Tuple.vector(0, local_point.y, 0);
    }
    return Tuple.vector(0, 0, local_point.z);
}

test "The normal on the surface of a cube" {
    const c = Object.cube();
    for ([_]struct { Tuple, Tuple }{
        .{ Tuple.point(1, 0.5, -0.8), Tuple.vector(1, 0, 0) },
        .{ Tuple.point(-1, -0.2, 0.9), Tuple.vector(-1, 0, 0) },
        .{ Tuple.point(-0.4, 1, -0.1), Tuple.vector(0, 1, 0) },
        .{ Tuple.point(0.3, -1, -0.7), Tuple.vector(0, -1, 0) },
        .{ Tuple.point(-0.6, 0.3, 1), Tuple.vector(0, 0, 1) },
        .{ Tuple.point(0.4, 0.4, -1), Tuple.vector(0, 0, -1) },
        .{ Tuple.point(1, 1, 1), Tuple.vector(1, 0, 0) },
        .{ Tuple.point(-1, -1, -1), Tuple.vector(-1, 0, 0) },
    }) |example| {
        try Tuple.expectEqual(example[1], c.normal_at(example[0]));
    }
}
