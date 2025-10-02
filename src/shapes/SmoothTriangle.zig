const builtin = @import("builtin");
const floats = @import("../floats.zig");
const Intersection = @import("../Intersection.zig");
const SmoothTriangle = @This();
const Tuple = @import("../Tuple.zig");
const Object = @import("../Object.zig");
const Ray = @import("../Ray.zig");

p1: Tuple,
p2: Tuple,
p3: Tuple,
e1: Tuple,
e2: Tuple,
n1: Tuple,
n2: Tuple,
n3: Tuple,

pub fn init(p1: Tuple, p2: Tuple, p3: Tuple, n1: Tuple, n2: Tuple, n3: Tuple) SmoothTriangle {
    const e1 = p2.sub(p1);
    const e2 = p3.sub(p1);
    return SmoothTriangle{
        .p1 = p1,
        .p2 = p2,
        .p3 = p3,
        .e1 = e1,
        .e2 = e2,
        .n1 = n1,
        .n2 = n2,
        .n3 = n3,
    };
}

fn test_background() Object {
    const p1 = Tuple.point(0, 1, 0);
    const p2 = Tuple.point(-1, 0, 0);
    const p3 = Tuple.point(1, 0, 0);
    const n1 = Tuple.vector(0, 1, 0);
    const n2 = Tuple.vector(-1, 0, 0);
    const n3 = Tuple.vector(1, 0, 0);

    return Object.smooth_triangle(p1, p2, p3, n1, n2, n3);
}

test "Constructing a smooth triangle" {
    const p1 = Tuple.point(0, 1, 0);
    const p2 = Tuple.point(-1, 0, 0);
    const p3 = Tuple.point(1, 0, 0);
    const n1 = Tuple.vector(0, 1, 0);
    const n2 = Tuple.vector(-1, 0, 0);
    const n3 = Tuple.vector(1, 0, 0);

    var tri = test_background();

    try Tuple.expectEqual(p1, tri.as_smooth_triangle().p1);
    try Tuple.expectEqual(p2, tri.as_smooth_triangle().p2);
    try Tuple.expectEqual(p3, tri.as_smooth_triangle().p3);
    try Tuple.expectEqual(n1, tri.as_smooth_triangle().n1);
    try Tuple.expectEqual(n2, tri.as_smooth_triangle().n2);
    try Tuple.expectEqual(n3, tri.as_smooth_triangle().n3);
}

pub fn local_intersect(self: SmoothTriangle, ray: Ray, object: *const Object, buf: []Intersection) []Intersection {
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
    buf[0] = Intersection.init_with_uv(t, object, u, v);
    return buf[0..1];
}

test "An intersection with a smooth triangle stores u/v" {
    const t = test_background();
    const r = Ray.init(Tuple.point(-0.2, 0.3, -2), Tuple.vector(0, 0, 1));
    var buf = [_]Intersection{undefined} ** 10;
    const xs = t.intersect(r, &buf);
    try floats.expectEqual(0.45, xs[0].u);
    try floats.expectEqual(0.25, xs[0].v);
}

pub fn local_normal_at(self: SmoothTriangle, _: Tuple, hit: Intersection) Tuple {
    return self.n2.muls(hit.u).add(self.n3.muls(hit.v)).add(self.n1.muls(1 - hit.u - hit.v));
}

test "A smooth triangle uses u/v to interpolate the normal" {
    const tri = test_background();
    const i = Intersection.init_with_uv(1, &tri, 0.45, 0.25);
    const n = tri.normal_at(Tuple.point(0, 0, 0), i);
    try Tuple.expectEqual(Tuple.vector(-0.5547, 0.83205, 0), n);
}

test "Preparing the normal on a smooth triangle" {
    const tri = test_background();
    const i = Intersection.init_with_uv(1, &tri, 0.45, 0.25);
    const r = Ray.init(Tuple.point(-0.2, 0.3, -2), Tuple.vector(0, 0, 1));
    const xs = [_]Intersection{i};
    const comps = i.init_computations(r, &xs);
    try Tuple.expectEqual(Tuple.vector(-0.5547, 0.83205, 0), comps.normalv);
}
