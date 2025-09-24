const floats = @import("floats.zig");
const Float = floats.Float;
const Matrix = @import("Matrix.zig");
const Ray = @This();
const transformations = @import("transformations.zig");
const Tuple = @import("Tuple.zig");

origin: Tuple,
direction: Tuple,

pub fn init(origin: Tuple, direction: Tuple) Ray {
    return Ray{
        .origin = origin,
        .direction = direction,
    };
}

test init {
    const origin = Tuple.point(1, 2, 3);
    const direction = Tuple.vector(4, 5, 6);
    const r = init(origin, direction);
    try Tuple.expectEqual(origin, r.origin);
    try Tuple.expectEqual(direction, r.direction);
}

/// Returns the position of a ray at a given distance from its origin
pub fn position(self: Ray, t: Float) Tuple {
    return Tuple.add(self.origin, Tuple.muls(self.direction, t));
}

test position {
    const r = init(Tuple.point(2, 3, 4), Tuple.vector(1, 0, 0));
    try Tuple.expectEqual(Tuple.point(2, 3, 4), position(r, 0));
    try Tuple.expectEqual(Tuple.point(3, 3, 4), position(r, 1));
    try Tuple.expectEqual(Tuple.point(1, 3, 4), position(r, -1));
    try Tuple.expectEqual(Tuple.point(4.5, 3, 4), position(r, 2.5));
}

pub fn transform(self: Ray, transformation: Matrix) Ray {
    return init(
        transformation.mult(self.origin),
        transformation.mult(self.direction),
    );
}

test "Translating a ray" {
    const r = init(Tuple.point(1, 2, 3), Tuple.vector(0, 1, 0));
    const m = transformations.translation(3, 4, 5);
    const r2 = transform(r, m);
    try Tuple.expectEqual(Tuple.point(4, 6, 8), r2.origin);
    try Tuple.expectEqual(Tuple.vector(0, 1, 0), r2.direction);
}

test "Scaling a ray" {
    const r = init(Tuple.point(1, 2, 3), Tuple.vector(0, 1, 0));
    const m = transformations.scaling(2, 3, 4);
    const r2 = transform(r, m);
    try Tuple.expectEqual(Tuple.point(2, 6, 12), r2.origin);
    try Tuple.expectEqual(Tuple.vector(0, 3, 0), r2.direction);
}
