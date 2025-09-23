const std = @import("std");
const floats = @import("floats.zig");
const Float = floats.Float;

pub const Tuple = [4]Float;

pub fn init(new_x: Float, new_y: Float, new_z: Float, new_w: Float) Tuple {
    return [4]Float{ new_x, new_y, new_z, new_w };
}

fn equal(a: Tuple, b: Tuple) bool {
    return floats.equal(a[0], b[0]) and floats.equal(a[1], b[1]) and floats.equal(a[2], b[2]) and floats.equal(a[3], b[3]);
}

pub fn expectEqual(a: Tuple, b: Tuple) !void {
    try floats.expectEqual(a[0], b[0]);
    try floats.expectEqual(a[1], b[1]);
    try floats.expectEqual(a[2], b[2]);
    try floats.expectEqual(a[3], b[3]);
}

pub fn x(tuple: Tuple) Float {
    return tuple[0];
}

pub fn y(tuple: Tuple) Float {
    return tuple[1];
}

pub fn z(tuple: Tuple) Float {
    return tuple[2];
}

pub fn w(tuple: Tuple) Float {
    return tuple[3];
}

/// A tuple with w=1.0 is a point
pub fn point(new_x: Float, new_y: Float, new_z: Float) Tuple {
    return init(new_x, new_y, new_z, 1.0);
}

test point {
    const tuple = point(4.3, -4.2, 3.1);
    try std.testing.expectEqual(4.3, x(tuple));
    try std.testing.expectEqual(-4.2, y(tuple));
    try std.testing.expectEqual(3.1, z(tuple));
    try std.testing.expectEqual(1.0, w(tuple));
}

/// A tuple with w=0.0 is a vector
pub fn vector(new_x: Float, new_y: Float, new_z: Float) Tuple {
    return init(new_x, new_y, new_z, 0.0);
}

/// Forces a tuple to be a vector
pub fn to_vector(tuple: *Tuple) void {
    tuple.*[3] = 0.0;
}

test vector {
    const tuple = vector(4.3, -4.2, 3.1);
    try std.testing.expectEqual(4.3, x(tuple));
    try std.testing.expectEqual(-4.2, y(tuple));
    try std.testing.expectEqual(3.1, z(tuple));
    try std.testing.expectEqual(0.0, w(tuple));
}

/// Performs vector addition
pub fn add(a: Tuple, b: Tuple) Tuple {
    return init(a[0] + b[0], a[1] + b[1], a[2] + b[2], a[3] + b[3]);
}

test add {
    const a1 = point(3.0, -2.0, 5.0);
    const a2 = vector(-2.0, 3.0, 1.0);
    const result = add(a1, a2);
    try expectEqual(point(1.0, 1.0, 6.0), result);
}

/// Performs vector subtraction
pub fn sub(a: Tuple, b: Tuple) Tuple {
    return init(a[0] - b[0], a[1] - b[1], a[2] - b[2], a[3] - b[3]);
}

test sub {
    const p = point(3.0, 2.0, 1.0);
    const v = vector(5.0, 6.0, 7.0);
    try expectEqual(point(-2.0, -4.0, -6.0), sub(p, v));
}

test "Subtracting 2 points gives a vector" {
    const p1 = point(3.0, 2.0, 1.0);
    const p2 = point(5.0, 6.0, 7.0);
    const result = sub(p1, p2);
    try expectEqual(vector(-2.0, -4.0, -6.0), result);
}

test "Subtracting two vectors" {
    const v1 = vector(3.0, 2.0, 1.0);
    const v2 = vector(5.0, 6.0, 7.0);
    try expectEqual(vector(-2.0, -4.0, -6.0), sub(v1, v2));
}

/// Negates a tuple
pub fn neg(tuple: Tuple) Tuple {
    return init(-tuple[0], -tuple[1], -tuple[2], -tuple[3]);
}

test neg {
    const v = vector(1.0, -2.0, 3.0);
    try expectEqual(vector(-1.0, 2.0, -3.0), neg(v));
}

/// Multiplies a tuple by a scalar
pub fn muls(tuple: Tuple, scalar: Float) Tuple {
    return init(tuple[0] * scalar, tuple[1] * scalar, tuple[2] * scalar, tuple[3] * scalar);
}

test muls {
    const v = vector(1.0, -2.0, 3.0);
    try expectEqual(vector(3.0, -6.0, 9.0), muls(v, 3.0));
}

test "Multiplying a tuple by a fraction" {
    const v = vector(1.0, -2.0, 3.0);
    try expectEqual(vector(0.5, -1, 1.5), muls(v, 0.5));
}

/// Divides a tuple by a scalar
pub fn divs(tuple: Tuple, scalar: Float) Tuple {
    return init(tuple[0] / scalar, tuple[1] / scalar, tuple[2] / scalar, tuple[3] / scalar);
}

test divs {
    const v = vector(1.0, -2.0, 3.0);
    try expectEqual(vector(0.5, -1, 1.5), divs(v, 2.0));
}

/// Computes the magnitude of a vector
pub fn magnitude(tuple: Tuple) Float {
    return @sqrt(tuple[0] * tuple[0] + tuple[1] * tuple[1] + tuple[2] * tuple[2] + tuple[3] * tuple[3]);
}

test magnitude {
    const v = vector(1.0, 0.0, 0.0);
    try floats.expectEqual(1.0, magnitude(v));
    const v2 = vector(0.0, 1.0, 0.0);
    try floats.expectEqual(1.0, magnitude(v2));
    const v3 = vector(0.0, 0.0, 1.0);
    try floats.expectEqual(1.0, magnitude(v3));
    const v4 = vector(1.0, 2.0, 3.0);
    try floats.expectEqual(@sqrt(14.0), magnitude(v4));
    const v5 = vector(-1.0, -2.0, -3.0);
    try floats.expectEqual(@sqrt(14.0), magnitude(v5));
}

/// Normalizes a tuple
pub fn normalize(tuple: Tuple) Tuple {
    return divs(tuple, magnitude(tuple));
}

test normalize {
    const v = vector(4.0, 0.0, 0.0);
    try expectEqual(vector(1.0, 0.0, 0.0), normalize(v));

    const v2 = vector(1.0, 2.0, 3.0);
    try expectEqual(vector(0.26726, 0.53452, 0.80178), normalize(v2));
}

/// Computes the dot product of two vectors
pub fn dot(a: Tuple, b: Tuple) Float {
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2] + a[3] * b[3];
}

test dot {
    const a = vector(1.0, 2.0, 3.0);
    const b = vector(2.0, 3.0, 4.0);
    try floats.expectEqual(20.0, dot(a, b));
}

/// Computes the cross product of two vectors
pub fn cross(a: Tuple, b: Tuple) Tuple {
    return vector(a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]);
}

test cross {
    const a = vector(1.0, 2.0, 3.0);
    const b = vector(2.0, 3.0, 4.0);
    try expectEqual(vector(-1.0, 2.0, -1.0), cross(a, b));
    try expectEqual(vector(1.0, -2.0, 1.0), cross(b, a));
}

/// Reflects a vector against a surface's normal
pub fn reflect(in: Tuple, normal: Tuple) Tuple {
    return sub(in, muls(normal, 2.0 * dot(in, normal)));
}

test "Reflecting a vector approaching at 45°" {
    const v = vector(1.0, -1.0, 0.0);
    const n = vector(0.0, 1.0, 0.0);
    const r = reflect(v, n);
    try expectEqual(vector(1.0, 1.0, 0.0), r);
}

test "Reflecting a vector off a slanted surface" {
    const v = vector(0.0, -1.0, 0.0);
    const n = vector(floats.sqrt2 / 2, floats.sqrt2 / 2, 0.0);
    const r = reflect(v, n);
    try expectEqual(vector(1.0, 0.0, 0.0), r);
}
