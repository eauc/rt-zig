const std = @import("std");
const BoundingBox = @import("../BoundingBox.zig");
const floats = @import("../floats.zig");
const Intersection = @import("../Intersection.zig");
const Object = @import("../Object.zig");
const Plane = @This();
const Ray = @import("../Ray.zig");
const Tuple = @import("../Tuple.zig");

pub fn init() Plane {
    return Plane{};
}

pub fn prepare_bounding_box(_: *Plane) BoundingBox {
    var box = BoundingBox.infinite();
    box.min.y = -floats.EPSILON;
    box.max.y = floats.EPSILON;
    return box;
}

pub fn local_intersect(self: Plane, ray: Ray, object: *const Object, buf: []Intersection) []Intersection {
    _ = self;
    if (floats.equals(ray.direction.y, 0)) {
        return buf[0..0];
    }
    const t = -ray.origin.y / ray.direction.y;
    buf[0] = Intersection.init(t, object);
    return buf[0..1];
}

test "Intersect with a ray parallel to the plane" {
    const p = Object.plane();
    const r = Ray.init(Tuple.point(0, 10, 0), Tuple.vector(0, 0, 1));

    var buf = [_]Intersection{undefined} ** 10;
    const xs = p.intersect(r, &buf);

    try std.testing.expectEqual(0, xs.len);
}

test "Intersect with a coplanar ray" {
    const p = Object.plane();
    const r = Ray.init(Tuple.point(0, 0, 0), Tuple.vector(0, 0, 1));

    var buf = [_]Intersection{undefined} ** 10;
    const xs = p.intersect(r, &buf);

    try std.testing.expectEqual(0, xs.len);
}

test "A ray intersecting a plane from above" {
    const p = Object.plane();
    const r = Ray.init(Tuple.point(0, 1, 0), Tuple.vector(0, -1, 0));

    var buf = [_]Intersection{undefined} ** 10;
    const xs = p.intersect(r, &buf);

    try std.testing.expectEqual(1, xs.len);
    try floats.expectEqual(1, xs[0].t);
    try std.testing.expectEqual(&p, xs[0].object);
}

test "A ray intersecting a plane from below" {
    const p = Object.plane();
    const r = Ray.init(Tuple.point(0, -1, 0), Tuple.vector(0, 1, 0));

    var buf = [_]Intersection{undefined} ** 10;
    const xs = p.intersect(r, &buf);

    try std.testing.expectEqual(1, xs.len);
    try floats.expectEqual(1, xs[0].t);
    try std.testing.expectEqual(&p, xs[0].object);
}

pub fn local_normal_at(self: Plane, local_point: Tuple) Tuple {
    _ = self;
    _ = local_point;
    return Tuple.vector(0, 1, 0);
}

test "the normal of a plane is constant everywhere" {
    const p = Object.plane();
    const n1 = p.normal_at(Tuple.point(0, 0, 0), Intersection.init(0, &p));
    const n2 = p.normal_at(Tuple.point(10, 0, -10), Intersection.init(0, &p));
    const n3 = p.normal_at(Tuple.point(-5, 0, 150), Intersection.init(0, &p));
    try Tuple.expectEqual(n1, Tuple.vector(0, 1, 0));
    try Tuple.expectEqual(n2, Tuple.vector(0, 1, 0));
    try Tuple.expectEqual(n3, Tuple.vector(0, 1, 0));
}
