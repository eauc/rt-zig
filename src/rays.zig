const floats = @import("floats.zig");
const Float = floats.Float;
const matrices = @import("matrices.zig");
const Matrix = matrices.Matrix;
const transformations = @import("transformations.zig");
const tuples = @import("tuples.zig");
const Tuple = tuples.Tuple;

pub const Ray = struct {
    origin: Tuple,
    direction: Tuple,
};

pub fn ray(origin: Tuple, direction: Tuple) Ray {
    return Ray{
        .origin = origin,
        .direction = direction,
    };
}

test ray {
    const origin = tuples.point(1, 2, 3);
    const direction = tuples.vector(4, 5, 6);
    const r = ray(origin, direction);
    try tuples.expectEqual(origin, r.origin);
    try tuples.expectEqual(direction, r.direction);
}

/// Returns the position of a ray at a given distance from its origin
pub fn position(r: Ray, t: Float) Tuple {
    return tuples.add(r.origin, tuples.muls(r.direction, t));
}

test position {
    const r = ray(tuples.point(2, 3, 4), tuples.vector(1, 0, 0));
    try tuples.expectEqual(tuples.point(2, 3, 4), position(r, 0));
    try tuples.expectEqual(tuples.point(3, 3, 4), position(r, 1));
    try tuples.expectEqual(tuples.point(1, 3, 4), position(r, -1));
    try tuples.expectEqual(tuples.point(4.5, 3, 4), position(r, 2.5));
}

pub fn transform(r: Ray, transformation: Matrix) Ray {
    return ray(
        matrices.mult(transformation, r.origin),
        matrices.mult(transformation, r.direction),
    );
}

test "Translating a ray" {
    const r = ray(tuples.point(1, 2, 3), tuples.vector(0, 1, 0));
    const m = transformations.translation(3, 4, 5);
    const r2 = transform(r, m);
    try tuples.expectEqual(tuples.point(4, 6, 8), r2.origin);
    try tuples.expectEqual(tuples.vector(0, 1, 0), r2.direction);
}

test "Scaling a ray" {
    const r = ray(tuples.point(1, 2, 3), tuples.vector(0, 1, 0));
    const m = transformations.scaling(2, 3, 4);
    const r2 = transform(r, m);
    try tuples.expectEqual(tuples.point(2, 6, 12), r2.origin);
    try tuples.expectEqual(tuples.vector(0, 3, 0), r2.direction);
}
