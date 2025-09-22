const std = @import("std");
const floats = @import("floats.zig");
const Float = floats.Float;
const spheres = @import("spheres.zig");
const Sphere = spheres.Sphere;

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

/// Finds the first hit in a set of intersections
pub fn hit(intersections: []const Intersection) ?*const Intersection {
    var h: ?*const Intersection = null;
    var t_min: Float = std.math.inf(Float);
    for (intersections) |*i| {
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
    try std.testing.expectEqual(&xs[1], i);
}

test "The hit, when some intersections have negative t" {
    const s = spheres.sphere();
    const int1 = intersection(-1, &s);
    const int2 = intersection(1, &s);
    const xs = [_]Intersection{ int2, int1 };
    const i = hit(&xs);
    try std.testing.expectEqual(&xs[0], i);
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
    try std.testing.expectEqual(&xs[3], i);
}
