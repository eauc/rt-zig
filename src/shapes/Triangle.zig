const std = @import("std");
const BoundingBox = @import("../BoundingBox.zig");
const floats = @import("../floats.zig");
const Intersection = @import("../Intersection.zig");
const Object = @import("../Object.zig");
const Ray = @import("../Ray.zig");
const Triangle = @This();
const Tuple = @import("../Tuple.zig");

p1: Tuple,
p2: Tuple,
p3: Tuple,
e1: Tuple,
e2: Tuple,
normal: Tuple,

pub fn init(p1: Tuple, p2: Tuple, p3: Tuple) Triangle {
    const e1 = p2.sub(p1);
    const e2 = p3.sub(p1);
    return Triangle{
        .p1 = p1,
        .p2 = p2,
        .p3 = p3,
        .e1 = e1,
        .e2 = e2,
        .normal = e2.cross(e1).normalize(),
    };
}

test "Constructing a triangle" {
    const p1 = Tuple.point(0, 1, 0);
    const p2 = Tuple.point(-1, 0, 0);
    const p3 = Tuple.point(1, 0, 0);

    const t = Triangle.init(p1, p2, p3);

    try Tuple.expectEqual(p1, t.p1);
    try Tuple.expectEqual(p2, t.p2);
    try Tuple.expectEqual(p3, t.p3);
    try Tuple.expectEqual(Tuple.vector(-1, -1, 0), t.e1);
    try Tuple.expectEqual(Tuple.vector(1, -1, 0), t.e2);
    try Tuple.expectEqual(Tuple.vector(0, 0, -1), t.normal);
}

pub fn prepare_bounding_box(self: Triangle) BoundingBox {
    return BoundingBox.init(Tuple.point(
        @min(@min(self.p1.x, self.p2.x), self.p3.x),
        @min(@min(self.p1.y, self.p2.y), self.p3.y),
        @min(@min(self.p1.z, self.p2.z), self.p3.z),
    ), Tuple.point(
        @max(@max(self.p1.x, self.p2.x), self.p3.x),
        @max(@max(self.p1.y, self.p2.y), self.p3.y),
        @max(@max(self.p1.z, self.p2.z), self.p3.z),
    ));
}

pub fn local_intersect(self: Triangle, ray: Ray, object: *const Object, buf: []Intersection) []Intersection {
    const dir_cross_e2 = ray.direction.cross(self.e2);
    const det = self.e1.dot(dir_cross_e2);
    if (@abs(det) < floats.EPSILON) {
        return buf[0..0];
    }
    const f = 1 / det;
    const p1_to_origin = ray.origin.sub(self.p1);
    const u = f * p1_to_origin.dot(dir_cross_e2);
    if (u < 0 or u > 1) {
        return buf[0..0];
    }
    const origin_cross_e1 = p1_to_origin.cross(self.e1);
    const v = f * ray.direction.dot(origin_cross_e1);
    if (v < 0 or u + v > 1) {
        return buf[0..0];
    }
    const t = f * self.e2.dot(origin_cross_e1);
    buf[0] = Intersection.init(t, object);
    return buf[0..1];
}

test "Intersecting a ray parallel to the the triangle" {
    const t = Object.triangle(Tuple.point(0, 1, 0), Tuple.point(-1, 0, 0), Tuple.point(1, 0, 0));
    const r = Ray.init(Tuple.point(0, -1, -2), Tuple.vector(0, 1, 0));
    var buf = [_]Intersection{undefined} ** 10;
    const xs = t.intersect(r, &buf);
    try std.testing.expectEqual(0, xs.len);
}

test "A ray misses the p1-p3 edge" {
    const t = Object.triangle(Tuple.point(0, 1, 0), Tuple.point(-1, 0, 0), Tuple.point(1, 0, 0));
    const r = Ray.init(Tuple.point(1, 1, -2), Tuple.vector(0, 0, 1));
    var buf = [_]Intersection{undefined} ** 10;
    const xs = t.intersect(r, &buf);
    try std.testing.expectEqual(0, xs.len);
}

test "A ray misses the p1-p2 edge" {
    const t = Object.triangle(Tuple.point(0, 1, 0), Tuple.point(-1, 0, 0), Tuple.point(1, 0, 0));
    const r = Ray.init(Tuple.point(-1, 1, -2), Tuple.vector(0, 0, 1));
    var buf = [_]Intersection{undefined} ** 10;
    const xs = t.intersect(r, &buf);
    try std.testing.expectEqual(0, xs.len);
}

test "A ray misses the p2-p3 edge" {
    const t = Object.triangle(Tuple.point(0, 1, 0), Tuple.point(-1, 0, 0), Tuple.point(1, 0, 0));
    const r = Ray.init(Tuple.point(0, -1, -2), Tuple.vector(0, 0, 1));
    var buf = [_]Intersection{undefined} ** 10;
    const xs = t.intersect(r, &buf);
    try std.testing.expectEqual(0, xs.len);
}

test "A ray strikes a triangle" {
    const t = Object.triangle(Tuple.point(0, 1, 0), Tuple.point(-1, 0, 0), Tuple.point(1, 0, 0));
    const r = Ray.init(Tuple.point(0, 0.5, -2), Tuple.vector(0, 0, 1));
    var buf = [_]Intersection{undefined} ** 10;
    const xs = t.intersect(r, &buf);
    try std.testing.expectEqual(1, xs.len);
    try floats.expectEqual(2, xs[0].t);
}

pub fn local_normal_at(self: Triangle, _: Tuple) Tuple {
    return self.normal;
}

test "Finding the normal on a triangle" {
    const t = Triangle.init(Tuple.point(0, 1, 0), Tuple.point(-1, 0, 0), Tuple.point(1, 0, 0));

    try Tuple.expectEqual(t.normal, t.local_normal_at(Tuple.point(0, 0.5, 0)));
    try Tuple.expectEqual(t.normal, t.local_normal_at(Tuple.point(-0.5, 0.75, 0)));
    try Tuple.expectEqual(t.normal, t.local_normal_at(Tuple.point(0.5, 0.25, 0)));
}
