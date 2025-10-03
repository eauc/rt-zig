const std = @import("std");

pub const Float = f32;

pub const EPSILON: Float = 0.00001;
pub const pi: Float = std.math.pi;
pub const sqrt2: Float = std.math.sqrt2;
pub const sqrt3: Float = 1.7320508075688772935;

pub fn random(magnitude: Float) Float {
    return std.crypto.random.float(Float) * magnitude;
}

pub fn equals(a: Float, b: Float) bool {
    return std.math.approxEqAbs(Float, a, b, EPSILON);
}

pub fn expectEqual(a: Float, b: Float) !void {
    return std.testing.expectApproxEqAbs(a, b, EPSILON);
}
