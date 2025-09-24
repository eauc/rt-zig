const std = @import("std");
const floats = @import("floats.zig");
const Float = floats.Float;
const matrices = @import("matrices.zig");
const Matrix = matrices.Matrix;
const tuples = @import("tuples.zig");

/// Translates a point or vector
pub fn translation(dx: Float, dy: Float, dz: Float) Matrix {
    return matrices.matrix([4][4]Float{
        [_]Float{ 1, 0, 0, dx },
        [_]Float{ 0, 1, 0, dy },
        [_]Float{ 0, 0, 1, dz },
        [_]Float{ 0, 0, 0, 1 },
    });
}

test translation {
    const transform = translation(5, -3, 2);
    const p = tuples.point(-3, 4, 5);
    try tuples.expectEqual(tuples.point(2, 1, 7), matrices.mult(transform, p));
}

test "Multiplying by the inverse of a translation matrix" {
    const transform = translation(5, -3, 2);
    const inv = matrices.inverse(transform);
    const p = tuples.point(-3, 4, 5);
    try tuples.expectEqual(tuples.point(-8, 7, 3), matrices.mult(inv, p));
}

test "Translation does not affect vectors" {
    const transform = translation(5, -3, 2);
    const v = tuples.vector(-3, 4, 5);
    try tuples.expectEqual(v, matrices.mult(transform, v));
}

/// Scales a point or vector
pub fn scaling(sx: Float, sy: Float, sz: Float) Matrix {
    return matrices.matrix([4][4]Float{
        [_]Float{ sx, 0, 0, 0 },
        [_]Float{ 0, sy, 0, 0 },
        [_]Float{ 0, 0, sz, 0 },
        [_]Float{ 0, 0, 0, 1 },
    });
}

test scaling {
    // scaling a point
    const transform = scaling(2, 3, 4);
    const p = tuples.point(-4, 6, 8);
    try tuples.expectEqual(tuples.point(-8, 18, 32), matrices.mult(transform, p));

    // scaling a vector
    const v = tuples.vector(-4, 6, 8);
    try tuples.expectEqual(tuples.vector(-8, 18, 32), matrices.mult(transform, v));
}

test "Multiplying by the inverse of a scaling matrix" {
    const transform = scaling(2, 3, 4);
    const inv = matrices.inverse(transform);
    const v = tuples.vector(-4, 6, 8);
    try tuples.expectEqual(tuples.vector(-2, 2, 2), matrices.mult(inv, v));
}

/// Rotates a point around the x axis
pub fn rotation_x(theta: Float) Matrix {
    return matrices.matrix([4][4]Float{
        [_]Float{ 1, 0, 0, 0 },
        [_]Float{ 0, std.math.cos(theta), -std.math.sin(theta), 0 },
        [_]Float{ 0, std.math.sin(theta), std.math.cos(theta), 0 },
        [_]Float{ 0, 0, 0, 1 },
    });
}

test rotation_x {
    const p = tuples.point(0, 1, 0);
    const half_quarter = rotation_x(floats.pi / 4);
    const full_quarter = rotation_x(floats.pi / 2);
    try tuples.expectEqual(tuples.point(0, floats.sqrt2 / 2, floats.sqrt2 / 2), matrices.mult(half_quarter, p));
    try tuples.expectEqual(tuples.point(0, 0, 1), matrices.mult(full_quarter, p));
}

test "The inverse of an x-rotation rotates in the opposite direction" {
    const p = tuples.point(0, 1, 0);
    const half_quarter = rotation_x(floats.pi / 4);
    const inv = matrices.inverse(half_quarter);
    try tuples.expectEqual(tuples.point(0, floats.sqrt2 / 2, -floats.sqrt2 / 2), matrices.mult(inv, p));
}

/// Rotates a point around the y axis
pub fn rotation_y(theta: Float) Matrix {
    return matrices.matrix([4][4]Float{
        [_]Float{ std.math.cos(theta), 0, std.math.sin(theta), 0 },
        [_]Float{ 0, 1, 0, 0 },
        [_]Float{ -std.math.sin(theta), 0, std.math.cos(theta), 0 },
        [_]Float{ 0, 0, 0, 1 },
    });
}

test rotation_y {
    const p = tuples.point(0, 0, 1);
    const half_quarter = rotation_y(floats.pi / 4);
    const full_quarter = rotation_y(floats.pi / 2);
    try tuples.expectEqual(tuples.point(floats.sqrt2 / 2, 0, floats.sqrt2 / 2), matrices.mult(half_quarter, p));
    try tuples.expectEqual(tuples.point(1, 0, 0), matrices.mult(full_quarter, p));
}

/// Rotates a point around the z axis
pub fn rotation_z(theta: Float) Matrix {
    return matrices.matrix([4][4]Float{
        [_]Float{ std.math.cos(theta), -std.math.sin(theta), 0, 0 },
        [_]Float{ std.math.sin(theta), std.math.cos(theta), 0, 0 },
        [_]Float{ 0, 0, 1, 0 },
        [_]Float{ 0, 0, 0, 1 },
    });
}

test rotation_z {
    const p = tuples.point(0, 1, 0);
    const half_quarter = rotation_z(floats.pi / 4);
    const full_quarter = rotation_z(floats.pi / 2);
    try tuples.expectEqual(tuples.point(-floats.sqrt2 / 2, floats.sqrt2 / 2, 0), matrices.mult(half_quarter, p));
    try tuples.expectEqual(tuples.point(-1, 0, 0), matrices.mult(full_quarter, p));
}

/// Creates a shearing transformation
pub fn shearing(dxy: Float, dxz: Float, dyx: Float, dyz: Float, dzx: Float, dzy: Float) Matrix {
    return matrices.matrix([4][4]Float{
        [_]Float{ 1, dxy, dxz, 0 },
        [_]Float{ dyx, 1, dyz, 0 },
        [_]Float{ dzx, dzy, 1, 0 },
        [_]Float{ 0, 0, 0, 1 },
    });
}

test "A shearing transformation moves x in proportion to y" {
    const transform = shearing(1, 0, 0, 0, 0, 0);
    const p = tuples.point(2, 3, 4);
    try tuples.expectEqual(tuples.point(5, 3, 4), matrices.mult(transform, p));
}

test "A shearing transformation moves x in proportion to z" {
    const transform = shearing(0, 1, 0, 0, 0, 0);
    const p = tuples.point(2, 3, 4);
    try tuples.expectEqual(tuples.point(6, 3, 4), matrices.mult(transform, p));
}

test "A shearing transformation moves y in proportion to x" {
    const transform = shearing(0, 0, 1, 0, 0, 0);
    const p = tuples.point(2, 3, 4);
    try tuples.expectEqual(tuples.point(2, 5, 4), matrices.mult(transform, p));
}

test "A shearing transformation moves y in proportion to z" {
    const transform = shearing(0, 0, 0, 1, 0, 0);
    const p = tuples.point(2, 3, 4);
    try tuples.expectEqual(tuples.point(2, 7, 4), matrices.mult(transform, p));
}

test "A shearing transformation moves z in proportion to x" {
    const transform = shearing(0, 0, 0, 0, 1, 0);
    const p = tuples.point(2, 3, 4);
    try tuples.expectEqual(tuples.point(2, 3, 6), matrices.mult(transform, p));
}

test "A shearing transformation moves z in proportion to y" {
    const transform = shearing(0, 0, 0, 0, 0, 1);
    const p = tuples.point(2, 3, 4);
    try tuples.expectEqual(tuples.point(2, 3, 7), matrices.mult(transform, p));
}

test "Individual transformations are applied in sequence" {
    const p = tuples.point(1, 0, 1);
    const a = rotation_x(floats.pi / 2);
    const b = scaling(5, 5, 5);
    const c = translation(10, 5, 7);

    const p2 = matrices.mult(a, p);
    try tuples.expectEqual(tuples.point(1, -1, 0), p2);
    const p3 = matrices.mult(b, p2);
    try tuples.expectEqual(tuples.point(5, -5, 0), p3);
    const p4 = matrices.mult(c, p3);
    try tuples.expectEqual(tuples.point(15, 0, 7), p4);
}

/// Creates a view transformation
pub fn view_transform(from: tuples.Tuple, to: tuples.Tuple, up: tuples.Tuple) Matrix {
    const forward = tuples.normalize(tuples.sub(to, from));
    const left = tuples.cross(forward, tuples.normalize(up));
    const true_up = tuples.cross(left, forward);
    const orientation = matrices.matrix([4][4]Float{
        [_]Float{ tuples.x(left), tuples.y(left), tuples.z(left), 0 },
        [_]Float{ tuples.x(true_up), tuples.y(true_up), tuples.z(true_up), 0 },
        [_]Float{ -tuples.x(forward), -tuples.y(forward), -tuples.z(forward), 0 },
        [_]Float{ 0, 0, 0, 1 },
    });
    return matrices.mul(orientation, translation(-tuples.x(from), -tuples.y(from), -tuples.z(from)));
}

test "An arbitrary view transformation" {
    const from = tuples.point(1, 3, 2);
    const to = tuples.point(4, -2, 8);
    const up = tuples.vector(1, 1, 0);
    const t = view_transform(from, to, up);
    try matrices.expectEqual(matrices.matrix([4][4]Float{
        [_]Float{ -0.50709, 0.50709, 0.67612, -2.36643 },
        [_]Float{ 0.76772, 0.60609, 0.12122, -2.82843 },
        [_]Float{ -0.35857, 0.59761, -0.71714, 0.00000 },
        [_]Float{ 0.00000, 0.00000, 0.00000, 1.00000 },
    }), t);
}
test "The transformation matrix for the default orientation" {
    const from = tuples.point(0, 0, 0);
    const to = tuples.point(0, 0, -1);
    const up = tuples.vector(0, 1, 0);
    const t = view_transform(from, to, up);
    try matrices.expectEqual(matrices.identity(), t);
}

test "The view transformation matrix looking in positive z direction" {
    const from = tuples.point(0, 0, 0);
    const to = tuples.point(0, 0, 1);
    const up = tuples.vector(0, 1, 0);
    const t = view_transform(from, to, up);
    try matrices.expectEqual(scaling(-1, 1, -1), t);
}

test "The view transformation moves the world" {
    const from = tuples.point(0, 0, 8);
    const to = tuples.point(0, 0, 0);
    const up = tuples.vector(0, 1, 0);
    const t = view_transform(from, to, up);
    try matrices.expectEqual(translation(0, 0, -8), t);
}
