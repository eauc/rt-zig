const std = @import("std");
const Checker = @This();
const Color = @import("../Color.zig");
const Tuple = @import("../Tuple.zig");

a: Color,
b: Color,

pub fn init(a: Color, b: Color) Checker {
    return Checker{ .a = a, .b = b };
}

pub fn color_at(self: Checker, point: Tuple) Color {
    return if (@mod(std.math.floor(point.x) + std.math.floor(point.y) + std.math.floor(point.z), 2) == 0) self.a else self.b;
}

test "Checkers should repeat in x" {
    const pattern = init(Color.WHITE, Color.BLACK);

    try Color.expectEqual(Color.WHITE, pattern.color_at(Tuple.point(0, 0, 0)));
    try Color.expectEqual(Color.WHITE, pattern.color_at(Tuple.point(0.99, 0, 0)));
    try Color.expectEqual(Color.BLACK, pattern.color_at(Tuple.point(1.01, 0, 0)));
}

test "Checkers should repeat in y" {
    const pattern = init(Color.WHITE, Color.BLACK);

    try Color.expectEqual(Color.WHITE, pattern.color_at(Tuple.point(0, 0, 0)));
    try Color.expectEqual(Color.WHITE, pattern.color_at(Tuple.point(0, 0.99, 0)));
    try Color.expectEqual(Color.BLACK, pattern.color_at(Tuple.point(0, 1.01, 0)));
}

test "Checkers should repeat in z" {
    const pattern = init(Color.WHITE, Color.BLACK);

    try Color.expectEqual(Color.WHITE, pattern.color_at(Tuple.point(0, 0, 0)));
    try Color.expectEqual(Color.WHITE, pattern.color_at(Tuple.point(0, 0, 0.99)));
    try Color.expectEqual(Color.BLACK, pattern.color_at(Tuple.point(0, 0, 1.01)));
}
