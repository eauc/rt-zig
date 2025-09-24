const std = @import("std");
const floats = @import("floats.zig");
const Float = floats.Float;
const Matrix = @import("Matrix.zig");
const Tuple = @import("Tuple.zig");

/// Translates a point or vector
pub fn translation(dx: Float, dy: Float, dz: Float) Matrix {
    return Matrix.init([4][4]Float{
        [_]Float{ 1, 0, 0, dx },
        [_]Float{ 0, 1, 0, dy },
        [_]Float{ 0, 0, 1, dz },
        [_]Float{ 0, 0, 0, 1 },
    });
}

test translation {
    const transform = translation(5, -3, 2);
    const p = Tuple.point(-3, 4, 5);
    try Tuple.expectEqual(Tuple.point(2, 1, 7), Matrix.mult(transform, p));
}

test "Multiplying by the inverse of a translation matrix" {
    const transform = translation(5, -3, 2);
    const inv = Matrix.inverse(transform);
    const p = Tuple.point(-3, 4, 5);
    try Tuple.expectEqual(Tuple.point(-8, 7, 3), Matrix.mult(inv, p));
}

test "Translation does not affect vectors" {
    const transform = translation(5, -3, 2);
    const v = Tuple.vector(-3, 4, 5);
    try Tuple.expectEqual(v, Matrix.mult(transform, v));
}

/// Scales a point or vector
pub fn scaling(sx: Float, sy: Float, sz: Float) Matrix {
    return Matrix.init([4][4]Float{
        [_]Float{ sx, 0, 0, 0 },
        [_]Float{ 0, sy, 0, 0 },
        [_]Float{ 0, 0, sz, 0 },
        [_]Float{ 0, 0, 0, 1 },
    });
}

test scaling {
    // scaling a point
    const transform = scaling(2, 3, 4);
    const p = Tuple.point(-4, 6, 8);
    try Tuple.expectEqual(Tuple.point(-8, 18, 32), Matrix.mult(transform, p));

    // scaling a vector
    const v = Tuple.vector(-4, 6, 8);
    try Tuple.expectEqual(Tuple.vector(-8, 18, 32), Matrix.mult(transform, v));
}

test "Multiplying by the inverse of a scaling matrix" {
    const transform = scaling(2, 3, 4);
    const inv = Matrix.inverse(transform);
    const v = Tuple.vector(-4, 6, 8);
    try Tuple.expectEqual(Tuple.vector(-2, 2, 2), Matrix.mult(inv, v));
}

/// Rotates a point around the x axis
pub fn rotation_x(theta: Float) Matrix {
    return Matrix.init([4][4]Float{
        [_]Float{ 1, 0, 0, 0 },
        [_]Float{ 0, std.math.cos(theta), -std.math.sin(theta), 0 },
        [_]Float{ 0, std.math.sin(theta), std.math.cos(theta), 0 },
        [_]Float{ 0, 0, 0, 1 },
    });
}

test rotation_x {
    const p = Tuple.point(0, 1, 0);
    const half_quarter = rotation_x(floats.pi / 4);
    const full_quarter = rotation_x(floats.pi / 2);
    try Tuple.expectEqual(Tuple.point(0, floats.sqrt2 / 2, floats.sqrt2 / 2), Matrix.mult(half_quarter, p));
    try Tuple.expectEqual(Tuple.point(0, 0, 1), Matrix.mult(full_quarter, p));
}

test "The inverse of an x-rotation rotates in the opposite direction" {
    const p = Tuple.point(0, 1, 0);
    const half_quarter = rotation_x(floats.pi / 4);
    const inv = Matrix.inverse(half_quarter);
    try Tuple.expectEqual(Tuple.point(0, floats.sqrt2 / 2, -floats.sqrt2 / 2), Matrix.mult(inv, p));
}

/// Rotates a point around the y axis
pub fn rotation_y(theta: Float) Matrix {
    return Matrix.init([4][4]Float{
        [_]Float{ std.math.cos(theta), 0, std.math.sin(theta), 0 },
        [_]Float{ 0, 1, 0, 0 },
        [_]Float{ -std.math.sin(theta), 0, std.math.cos(theta), 0 },
        [_]Float{ 0, 0, 0, 1 },
    });
}

test rotation_y {
    const p = Tuple.point(0, 0, 1);
    const half_quarter = rotation_y(floats.pi / 4);
    const full_quarter = rotation_y(floats.pi / 2);
    try Tuple.expectEqual(Tuple.point(floats.sqrt2 / 2, 0, floats.sqrt2 / 2), Matrix.mult(half_quarter, p));
    try Tuple.expectEqual(Tuple.point(1, 0, 0), Matrix.mult(full_quarter, p));
}

/// Rotates a point around the z axis
pub fn rotation_z(theta: Float) Matrix {
    return Matrix.init([4][4]Float{
        [_]Float{ std.math.cos(theta), -std.math.sin(theta), 0, 0 },
        [_]Float{ std.math.sin(theta), std.math.cos(theta), 0, 0 },
        [_]Float{ 0, 0, 1, 0 },
        [_]Float{ 0, 0, 0, 1 },
    });
}

test rotation_z {
    const p = Tuple.point(0, 1, 0);
    const half_quarter = rotation_z(floats.pi / 4);
    const full_quarter = rotation_z(floats.pi / 2);
    try Tuple.expectEqual(Tuple.point(-floats.sqrt2 / 2, floats.sqrt2 / 2, 0), Matrix.mult(half_quarter, p));
    try Tuple.expectEqual(Tuple.point(-1, 0, 0), Matrix.mult(full_quarter, p));
}

/// Creates a shearing transformation
pub fn shearing(dxy: Float, dxz: Float, dyx: Float, dyz: Float, dzx: Float, dzy: Float) Matrix {
    return Matrix.init([4][4]Float{
        [_]Float{ 1, dxy, dxz, 0 },
        [_]Float{ dyx, 1, dyz, 0 },
        [_]Float{ dzx, dzy, 1, 0 },
        [_]Float{ 0, 0, 0, 1 },
    });
}

test "A shearing transformation moves x in proportion to y" {
    const transform = shearing(1, 0, 0, 0, 0, 0);
    const p = Tuple.point(2, 3, 4);
    try Tuple.expectEqual(Tuple.point(5, 3, 4), Matrix.mult(transform, p));
}

test "A shearing transformation moves x in proportion to z" {
    const transform = shearing(0, 1, 0, 0, 0, 0);
    const p = Tuple.point(2, 3, 4);
    try Tuple.expectEqual(Tuple.point(6, 3, 4), Matrix.mult(transform, p));
}

test "A shearing transformation moves y in proportion to x" {
    const transform = shearing(0, 0, 1, 0, 0, 0);
    const p = Tuple.point(2, 3, 4);
    try Tuple.expectEqual(Tuple.point(2, 5, 4), Matrix.mult(transform, p));
}

test "A shearing transformation moves y in proportion to z" {
    const transform = shearing(0, 0, 0, 1, 0, 0);
    const p = Tuple.point(2, 3, 4);
    try Tuple.expectEqual(Tuple.point(2, 7, 4), Matrix.mult(transform, p));
}

test "A shearing transformation moves z in proportion to x" {
    const transform = shearing(0, 0, 0, 0, 1, 0);
    const p = Tuple.point(2, 3, 4);
    try Tuple.expectEqual(Tuple.point(2, 3, 6), Matrix.mult(transform, p));
}

test "A shearing transformation moves z in proportion to y" {
    const transform = shearing(0, 0, 0, 0, 0, 1);
    const p = Tuple.point(2, 3, 4);
    try Tuple.expectEqual(Tuple.point(2, 3, 7), Matrix.mult(transform, p));
}

test "Individual transformations are applied in sequence" {
    const p = Tuple.point(1, 0, 1);
    const a = rotation_x(floats.pi / 2);
    const b = scaling(5, 5, 5);
    const c = translation(10, 5, 7);

    const p2 = Matrix.mult(a, p);
    try Tuple.expectEqual(Tuple.point(1, -1, 0), p2);
    const p3 = Matrix.mult(b, p2);
    try Tuple.expectEqual(Tuple.point(5, -5, 0), p3);
    const p4 = Matrix.mult(c, p3);
    try Tuple.expectEqual(Tuple.point(15, 0, 7), p4);
}

/// Creates a view transformation
pub fn view_transform(from: Tuple, to: Tuple, up: Tuple) Matrix {
    const forward = Tuple.normalize(Tuple.sub(to, from));
    const left = Tuple.cross(forward, Tuple.normalize(up));
    const true_up = Tuple.cross(left, forward);
    const orientation = Matrix.init([4][4]Float{
        [_]Float{ left.x, left.y, left.z, 0 },
        [_]Float{ true_up.x, true_up.y, true_up.z, 0 },
        [_]Float{ -forward.x, -forward.y, -forward.z, 0 },
        [_]Float{ 0, 0, 0, 1 },
    });
    return Matrix.mul(orientation, translation(-from.x, -from.y, -from.z));
}

test "An arbitrary view transformation" {
    const from = Tuple.point(1, 3, 2);
    const to = Tuple.point(4, -2, 8);
    const up = Tuple.vector(1, 1, 0);
    const t = view_transform(from, to, up);
    try Matrix.expectEqual(Matrix.init([4][4]Float{
        [_]Float{ -0.50709, 0.50709, 0.67612, -2.36643 },
        [_]Float{ 0.76772, 0.60609, 0.12122, -2.82843 },
        [_]Float{ -0.35857, 0.59761, -0.71714, 0.00000 },
        [_]Float{ 0.00000, 0.00000, 0.00000, 1.00000 },
    }), t);
}
test "The transformation matrix for the default orientation" {
    const from = Tuple.point(0, 0, 0);
    const to = Tuple.point(0, 0, -1);
    const up = Tuple.vector(0, 1, 0);
    const t = view_transform(from, to, up);
    try Matrix.expectEqual(Matrix.identity(), t);
}

test "The view transformation matrix looking in positive z direction" {
    const from = Tuple.point(0, 0, 0);
    const to = Tuple.point(0, 0, 1);
    const up = Tuple.vector(0, 1, 0);
    const t = view_transform(from, to, up);
    try Matrix.expectEqual(scaling(-1, 1, -1), t);
}

test "The view transformation moves the world" {
    const from = Tuple.point(0, 0, 8);
    const to = Tuple.point(0, 0, 0);
    const up = Tuple.vector(0, 1, 0);
    const t = view_transform(from, to, up);
    try Matrix.expectEqual(translation(0, 0, -8), t);
}
