const std = @import("std");
const Color = @import("../Color.zig");
const Ring = @This();
const Tuple = @import("../Tuple.zig");

a: Color,
b: Color,

pub fn init(a: Color, b: Color) Ring {
    return Ring{ .a = a, .b = b };
}

pub fn color_at(self: Ring, point: Tuple) Color {
    const h = std.math.hypot(point.x, point.z);
    return if (@mod(std.math.floor(h), 2) == 0) self.a else self.b;
}

test "A ring should extend in both x and z" {
    const pattern = init(Color.WHITE, Color.BLACK);

    try Color.expectEqual(Color.WHITE, pattern.color_at(Tuple.point(0, 0, 0)));
    try Color.expectEqual(Color.BLACK, pattern.color_at(Tuple.point(1, 0, 0)));
    try Color.expectEqual(Color.BLACK, pattern.color_at(Tuple.point(0, 0, 1)));
    try Color.expectEqual(Color.BLACK, pattern.color_at(Tuple.point(0.708, 0, 0.708)));
}
