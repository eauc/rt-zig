const std = @import("std");
const floats = @import("floats.zig");
const Float = floats.Float;
const Tuple = @This();

x: Float,
y: Float,
z: Float,
w: Float,

pub fn init(new_x: Float, new_y: Float, new_z: Float, new_w: Float) Tuple {
    return .{
        .x = new_x,
        .y = new_y,
        .z = new_z,
        .w = new_w,
    };
}

fn equal(self: Tuple, b: Tuple) bool {
    return floats.equal(self[0], b[0]) and floats.equal(self[1], b[1]) and floats.equal(self[2], b[2]) and floats.equal(self[3], b[3]);
}

pub fn expectEqual(expected: Tuple, actual: Tuple) !void {
    try floats.expectEqual(expected.x, actual.x);
    try floats.expectEqual(expected.y, actual.y);
    try floats.expectEqual(expected.z, actual.z);
    try floats.expectEqual(expected.w, actual.w);
}

/// A tuple with w=1.0 is a point
pub fn point(new_x: Float, new_y: Float, new_z: Float) Tuple {
    return init(new_x, new_y, new_z, 1.0);
}

test point {
    const tuple = point(4.3, -4.2, 3.1);
    try std.testing.expectEqual(4.3, tuple.x);
    try std.testing.expectEqual(-4.2, tuple.y);
    try std.testing.expectEqual(3.1, tuple.z);
    try std.testing.expectEqual(1.0, tuple.w);
}

/// A tuple with w=0.0 is a vector
pub fn vector(new_x: Float, new_y: Float, new_z: Float) Tuple {
    return init(new_x, new_y, new_z, 0.0);
}

/// Forces a tuple to be a vector
pub fn to_vector(self: *Tuple) void {
    self.w = 0.0;
}

test vector {
    const tuple = vector(4.3, -4.2, 3.1);
    try std.testing.expectEqual(4.3, tuple.x);
    try std.testing.expectEqual(-4.2, tuple.y);
    try std.testing.expectEqual(3.1, tuple.z);
    try std.testing.expectEqual(0.0, tuple.w);
}

/// Performs vector addition
pub fn add(self: Tuple, b: Tuple) Tuple {
    return init(self.x + b.x, self.y + b.y, self.z + b.z, self.w + b.w);
}

test add {
    const a1 = point(3.0, -2.0, 5.0);
    const a2 = vector(-2.0, 3.0, 1.0);
    const result = add(a1, a2);
    try expectEqual(point(1.0, 1.0, 6.0), result);
}

/// Performs vector subtraction
pub fn sub(self: Tuple, b: Tuple) Tuple {
    return init(self.x - b.x, self.y - b.y, self.z - b.z, self.w - b.w);
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
pub fn neg(self: Tuple) Tuple {
    return init(-self.x, -self.y, -self.z, -self.w);
}

test neg {
    const v = vector(1.0, -2.0, 3.0);
    try expectEqual(vector(-1.0, 2.0, -3.0), neg(v));
}

/// Multiplies a tuple by a scalar
pub fn muls(self: Tuple, scalar: Float) Tuple {
    return init(self.x * scalar, self.y * scalar, self.z * scalar, self.w * scalar);
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
pub fn divs(self: Tuple, scalar: Float) Tuple {
    return init(self.x / scalar, self.y / scalar, self.z / scalar, self.w / scalar);
}

test divs {
    const v = vector(1.0, -2.0, 3.0);
    try expectEqual(vector(0.5, -1, 1.5), divs(v, 2.0));
}

/// Computes the magnitude of a vector
pub fn magnitude(self: Tuple) Float {
    return @sqrt(self.x * self.x + self.y * self.y + self.z * self.z + self.w * self.w);
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
pub fn normalize(self: Tuple) Tuple {
    if (magnitude(self) == 0.0) return self;
    return self.divs(magnitude(self));
}

test normalize {
    const v = vector(4.0, 0.0, 0.0);
    try expectEqual(vector(1.0, 0.0, 0.0), normalize(v));

    const v2 = vector(1.0, 2.0, 3.0);
    try expectEqual(vector(0.26726, 0.53452, 0.80178), normalize(v2));
}

/// Computes the dot product of two vectors
pub fn dot(self: Tuple, b: Tuple) Float {
    return self.x * b.x + self.y * b.y + self.z * b.z + self.w * b.w;
}

test dot {
    const a = vector(1.0, 2.0, 3.0);
    const b = vector(2.0, 3.0, 4.0);
    try floats.expectEqual(20.0, dot(a, b));
}

/// Computes the cross product of two vectors
pub fn cross(self: Tuple, b: Tuple) Tuple {
    return vector(
        self.y * b.z - self.z * b.y,
        self.z * b.x - self.x * b.z,
        self.x * b.y - self.y * b.x,
    );
}

test cross {
    const a = vector(1.0, 2.0, 3.0);
    const b = vector(2.0, 3.0, 4.0);
    try expectEqual(vector(-1.0, 2.0, -1.0), cross(a, b));
    try expectEqual(vector(1.0, -2.0, 1.0), cross(b, a));
}

/// Reflects a vector against a surface's normal
pub fn reflect(self: Tuple, normal: Tuple) Tuple {
    return self.sub(normal.muls(2.0 * self.dot(normal)));
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
