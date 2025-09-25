const std = @import("std");
const Color = @import("../Color.zig");
const Stripe = @This();
const Tuple = @import("../Tuple.zig");

a: Color,
b: Color,

pub fn init(a: Color, b: Color) Stripe {
    return Stripe{ .a = a, .b = b };
}

test init {
    const pattern = init(Color.WHITE, Color.BLACK);
    try Color.expectEqual(Color.WHITE, pattern.a);
    try Color.expectEqual(Color.BLACK, pattern.b);
}

pub fn color_at(self: Stripe, point: Tuple) Color {
    return if (@mod(std.math.floor(point.x), 2) == 0) self.a else self.b;
}

test "A stripe pattern is constant in y" {
    const pattern = init(Color.WHITE, Color.BLACK);

    try Color.expectEqual(Color.WHITE, pattern.color_at(Tuple.point(0, 0, 0)));
    try Color.expectEqual(Color.WHITE, pattern.color_at(Tuple.point(0, 1, 0)));
    try Color.expectEqual(Color.WHITE, pattern.color_at(Tuple.point(0, 2, 0)));
}

test "A stripe pattern is constant in z" {
    const pattern = init(Color.WHITE, Color.BLACK);

    try Color.expectEqual(Color.WHITE, pattern.color_at(Tuple.point(0, 0, 0)));
    try Color.expectEqual(Color.WHITE, pattern.color_at(Tuple.point(0, 0, 1)));
    try Color.expectEqual(Color.WHITE, pattern.color_at(Tuple.point(0, 0, 2)));
}

test "A stripe pattern alternates in x" {
    const pattern = init(Color.WHITE, Color.BLACK);

    try Color.expectEqual(Color.WHITE, pattern.color_at(Tuple.point(0, 0, 0)));
    try Color.expectEqual(Color.WHITE, pattern.color_at(Tuple.point(0.9, 0, 0)));
    try Color.expectEqual(Color.BLACK, pattern.color_at(Tuple.point(1, 0, 0)));
    try Color.expectEqual(Color.BLACK, pattern.color_at(Tuple.point(-0.1, 0, 0)));
    try Color.expectEqual(Color.BLACK, pattern.color_at(Tuple.point(-1, 0, 0)));
    try Color.expectEqual(Color.WHITE, pattern.color_at(Tuple.point(-1.1, 0, 0)));
}
