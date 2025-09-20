const std = @import("std");

pub const Float = f32;

pub const EPSILON: Float = 0.00001;

pub fn equals(a: Float, b: Float) bool {
    return std.math.approxEqAbs(Float, a, b, EPSILON);
}

pub fn expectEqual(a: Float, b: Float) !void {
    return std.testing.expectApproxEqAbs(a, b, EPSILON);
}
