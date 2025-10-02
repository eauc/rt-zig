const std = @import("std");
const BoundingBox = @This();
const floats = @import("floats.zig");
const Float = floats.Float;
const Matrix = @import("Matrix.zig");
const Ray = @import("Ray.zig");
const Tuple = @import("Tuple.zig");

min: Tuple,
max: Tuple,

pub fn init(min: Tuple, max: Tuple) BoundingBox {
    return BoundingBox{ .min = min, .max = max };
}

pub fn default() BoundingBox {
    return init(Tuple.point(-1, -1, -1), Tuple.point(1, 1, 1));
}

pub fn infinite() BoundingBox {
    const inf = std.math.inf(Float);
    return init(Tuple.point(-inf, -inf, -inf), Tuple.point(inf, inf, inf));
}

pub fn transform(self: BoundingBox, t: Matrix) BoundingBox {
    const min = t.mult(self.min);
    const max = t.mult(self.max);
    return init(Tuple.point(
        @min(min.x, max.x),
        @min(min.y, max.y),
        @min(min.z, max.z),
    ), Tuple.point(
        @max(min.x, max.x),
        @max(min.y, max.y),
        @max(min.z, max.z),
    ));
}

pub fn merge(self: BoundingBox, other: BoundingBox) BoundingBox {
    return init(Tuple.point(
        @min(self.min.x, other.min.x),
        @min(self.min.y, other.min.y),
        @min(self.min.z, other.min.z),
    ), Tuple.point(
        @max(self.max.x, other.max.x),
        @max(self.max.y, other.max.y),
        @max(self.max.z, other.max.z),
    ));
}

pub fn intersect(self: BoundingBox, ray: Ray) bool {
    const xtmin, const xtmax = check_axis(self.min.x, self.max.x, ray.origin.x, ray.direction.x);
    const ytmin, const ytmax = check_axis(self.min.y, self.max.y, ray.origin.y, ray.direction.y);
    const ztmin, const ztmax = check_axis(self.min.z, self.max.z, ray.origin.z, ray.direction.z);

    const tmin = @max(xtmin, @max(ytmin, ztmin));
    const tmax = @min(xtmax, @min(ytmax, ztmax));
    return tmin <= tmax;
}

fn check_axis(min: Float, max: Float, origin: Float, direction: Float) struct { Float, Float } {
    const tmin_numerator = min - origin;
    const tmax_numerator = max - origin;
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
