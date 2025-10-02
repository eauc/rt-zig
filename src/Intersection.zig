const std = @import("std");
const floats = @import("floats.zig");
const Float = floats.Float;
const Intersection = @This();
const Object = @import("Object.zig");
const Ray = @import("Ray.zig");
const transformations = @import("transformations.zig");
const Tuple = @import("Tuple.zig");

t: Float,
object: *const Object,
u: Float,
v: Float,

pub fn init(t: Float, object: *const Object) Intersection {
    return Intersection{
        .t = t,
        .object = object,
        .u = 0,
        .v = 0,
    };
}

pub fn init_with_uv(t: Float, object: *const Object, u: Float, v: Float) Intersection {
    return Intersection{
        .t = t,
        .object = object,
        .u = u,
        .v = v,
    };
}

fn equals(self: Intersection, other: Intersection) bool {
    return self.t == other.t and self.object == other.object;
}

test "An intersection encapsulates t and object" {
    const s = Object.sphere();
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
    const s = Object.sphere();
    const int1 = init(1, &s);
    const int2 = init(2, &s);
    const xs = [_]Intersection{ int2, int1 };
    const i = hit(&xs);
    try std.testing.expectEqual(xs[1], i);
}

test "The hit, when some intersections have negative t" {
    const s = Object.sphere();
    const int1 = init(-1, &s);
    const int2 = init(1, &s);
    const xs = [_]Intersection{ int2, int1 };
    const i = hit(&xs);
    try std.testing.expectEqual(xs[0], i);
}

test "The hit, when all intersections have negative t" {
    const s = Object.sphere();
    const int1 = init(-2, &s);
    const int2 = init(-1, &s);
    const xs = [_]Intersection{ int2, int1 };
    const i = hit(&xs);
    try std.testing.expectEqual(null, i);
}

test hit {
    // The hit is always the lowest nonnegative intersection
    const s = Object.sphere();
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
    under_point: Tuple,
    eyev: Tuple,
    normalv: Tuple,
    reflectv: Tuple,
    n1: Float,
    n2: Float,

    fn find_refractive_indices(self: *Computations, current_hit: Intersection, xs: []const Intersection) void {
        var buf = [_]u8{0} ** (100 * @sizeOf(*const Object));
        var fba = std.heap.FixedBufferAllocator.init(&buf);
        const allocator = fba.allocator();
        var containers = std.ArrayList(*const Object){};
        for (xs) |x| {
            if (x.equals(current_hit)) {
                if (containers.items.len == 0) {
                    self.n1 = 1;
                } else {
                    self.n1 = containers.items[containers.items.len - 1].material.refractive_index;
                }
            }
            const index_of_object: ?usize = for (containers.items, 0..) |o, i| {
                if (o == x.object) {
                    break i;
                }
            } else null;
            if (index_of_object) |i| {
                _ = containers.orderedRemove(i);
            } else {
                containers.append(allocator, x.object) catch unreachable;
            }
            if (x.equals(current_hit)) {
                if (containers.items.len == 0) {
                    self.n2 = 1;
                } else {
                    self.n2 = containers.items[containers.items.len - 1].material.refractive_index;
                }
                return;
            }
        }
    }

    pub fn schlick(comps: Computations) Float {
        var cos = comps.eyev.dot(comps.normalv);
        if (comps.n1 > comps.n2) {
            const n = comps.n1 / comps.n2;
            const sin2_t = n * n * (1 - cos * cos);
            if (sin2_t > 1) {
                return 1;
            }
            const cos_t = @sqrt(1 - sin2_t);
            cos = cos_t;
        }
        const r0 = std.math.pow(Float, (comps.n1 - comps.n2) / (comps.n1 + comps.n2), 2);
        return r0 + (1 - r0) * std.math.pow(Float, 1 - cos, 5);
    }
};

pub fn init_computations(i: Intersection, r: Ray, xs: []const Intersection) Computations {
    const point = r.position(i.t);
    const eyev = r.direction.normalize().neg();
    const normalv = i.object.normal_at(point, i).normalize();
    var comps = Computations{
        .inside = false,
        .point = point,
        .over_point = point,
        .under_point = point,
        .eyev = eyev,
        .normalv = normalv,
        .reflectv = normalv,
        .n1 = 1,
        .n2 = 1,
    };
    if (comps.normalv.dot(comps.eyev) < 0) {
        comps.inside = true;
        comps.normalv = comps.normalv.neg();
    }
    comps.over_point = comps.point.add(comps.normalv.muls(floats.EPSILON * 10));
    comps.under_point = comps.point.sub(comps.normalv.muls(floats.EPSILON * 10));
    comps.reflectv = r.direction.reflect(comps.normalv);
    comps.find_refractive_indices(i, xs);
    return comps;
}

test init_computations {
    const r = Ray.init(Tuple.point(0, 0, -5), Tuple.vector(0, 0, 1));
    const shape = Object.sphere();
    const i = init(4, &shape);
    const comps = i.init_computations(r, &[_]Intersection{i});
    try Tuple.expectEqual(Tuple.point(0, 0, -1), comps.point);
    try Tuple.expectEqual(Tuple.vector(0, 0, -1), comps.eyev);
    try Tuple.expectEqual(Tuple.vector(0, 0, -1), comps.normalv);
}

test "The hit, when an intersection occurs on the outside" {
    const r = Ray.init(Tuple.point(0, 0, -5), Tuple.vector(0, 0, 1));
    const shape = Object.sphere();
    const i = init(4, &shape);
    const comps = i.init_computations(r, &[_]Intersection{i});
    try std.testing.expectEqual(false, comps.inside);
}

test "The hit, when an intersection occurs on the inside" {
    const r = Ray.init(Tuple.point(0, 0, 0), Tuple.vector(0, 0, 1));
    const shape = Object.sphere();
    const i = init(1, &shape);
    const comps = i.init_computations(r, &[_]Intersection{i});
    try std.testing.expectEqual(true, comps.inside);
    try Tuple.expectEqual(Tuple.point(0, 0, 1), comps.point);
    try Tuple.expectEqual(Tuple.vector(0, 0, -1), comps.eyev);
    try Tuple.expectEqual(Tuple.vector(0, 0, -1), comps.normalv);
}

test "The hit should offset the point" {
    const r = Ray.init(Tuple.point(0, 0, -5), Tuple.vector(0, 0, 1));
    var shape = Object.sphere().with_transform(transformations.translation(0, 0, 1));
    const i = init(5, &shape);
    const comps = i.init_computations(r, &[_]Intersection{i});
    try std.testing.expect(comps.over_point.z < -floats.EPSILON / 2);
    try std.testing.expect(comps.point.z > comps.over_point.z);
}

test "Precomputing the reflection vector" {
    const shape = Object.plane();
    const r = Ray.init(Tuple.point(0, 1, -1), Tuple.vector(0, -floats.sqrt2 / 2, floats.sqrt2 / 2));
    const i = Intersection.init(floats.sqrt2, &shape);
    const comps = i.init_computations(r, &[_]Intersection{i});
    try Tuple.expectEqual(Tuple.vector(0, floats.sqrt2 / 2, floats.sqrt2 / 2), comps.reflectv);
}

test "Finding n1 and n2 at various intersections" {
    var a = Object.sphere().made_of_glass().with_transform(transformations.scaling(2, 2, 2));
    a.material.refractive_index = 1.5;
    var b = Object.sphere().made_of_glass().with_transform(transformations.translation(0, 0, -0.25));
    b.material.refractive_index = 2.0;
    var c = Object.sphere().made_of_glass().with_transform(transformations.translation(0, 0, 0.25));
    c.material.refractive_index = 2.5;

    const r = Ray.init(Tuple.point(0, 0, -4), Tuple.vector(0, 0, 1));
    const xs = [_]Intersection{
        Intersection.init(2, &a),
        Intersection.init(2.75, &b),
        Intersection.init(3.25, &c),
        Intersection.init(4.75, &b),
        Intersection.init(5.25, &c),
        Intersection.init(6, &a),
    };
    for ([_]struct { usize, Float, Float }{
        .{ 0, 1.0, 1.5 },
        .{ 1, 1.5, 2.0 },
        .{ 2, 2.0, 2.5 },
        .{ 3, 2.5, 2.5 },
        .{ 4, 2.5, 1.5 },
        .{ 5, 1.5, 1.0 },
    }) |example| {
        const i = &xs[example[0]];
        const comps = i.init_computations(r, &xs);
        try floats.expectEqual(example[1], comps.n1);
        try floats.expectEqual(example[2], comps.n2);
    }
}

test "The under point is offset below the surface" {
    const r = Ray.init(Tuple.point(0, 0, -5), Tuple.vector(0, 0, 1));
    const shape = Object.sphere().made_of_glass().with_transform(transformations.translation(0, 0, 1));
    const xs = [_]Intersection{Intersection.init(5, &shape)};
    const comps = xs[0].init_computations(r, &xs);
    try std.testing.expect(comps.under_point.z > floats.EPSILON / 2);
    try std.testing.expect(comps.point.z < comps.under_point.z);
}

test "The Schlick approximation under total internal reflection" {
    const shape = Object.sphere().made_of_glass();
    const r = Ray.init(Tuple.point(0, 0, floats.sqrt2 / 2), Tuple.vector(0, 1, 0));
    const xs = [_]Intersection{ Intersection.init(-floats.sqrt2 / 2, &shape), Intersection.init(floats.sqrt2 / 2, &shape) };
    const comps = xs[1].init_computations(r, &xs);
    const reflectance = comps.schlick();
    try floats.expectEqual(1.0, reflectance);
}

test "The Schlick approximation with a perpendicular viewing angle" {
    const shape = Object.sphere().made_of_glass();
    const r = Ray.init(Tuple.point(0, 0, 0), Tuple.vector(0, 1, 0));
    const xs = [_]Intersection{ Intersection.init(-1, &shape), Intersection.init(1, &shape) };
    const comps = xs[1].init_computations(r, &xs);
    const reflectance = comps.schlick();
    try floats.expectEqual(0.04, reflectance);
}

test "The Schlick approximation with a small angle and n2 > n1" {
    const shape = Object.sphere().made_of_glass();
    const r = Ray.init(Tuple.point(0, 0.99, -2), Tuple.vector(0, 0, 1));
    const xs = [_]Intersection{Intersection.init(1.8589, &shape)};
    const comps = xs[0].init_computations(r, &xs);
    const reflectance = comps.schlick();
    try floats.expectEqual(0.48873, reflectance);
}

test "An intersection can encapsulate `u` and `v`" {
    const s = Object.triangle(Tuple.point(0, 1, 0), Tuple.point(-1, 0, 0), Tuple.point(1, 0, 0));
    const i = Intersection.init_with_uv(3.5, &s, 0.2, 0.4);
    try floats.expectEqual(0.2, i.u);
    try floats.expectEqual(0.4, i.v);
}
