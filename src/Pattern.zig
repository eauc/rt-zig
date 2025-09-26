const std = @import("std");
const Color = @import("Color.zig");
const Matrix = @import("Matrix.zig");
const Object = @import("Object.zig");
const Pattern = @This();
const patterns = @import("patterns.zig");
const Stripe = @import("patterns/Stripe.zig");
const transformations = @import("transformations.zig");
const scaling = transformations.scaling;
const translation = transformations.translation;
const Tuple = @import("Tuple.zig");

transform: Matrix,
transform_inverse: Matrix,
pattern: patterns.Pattern,

fn init(pattern: patterns.Pattern) Pattern {
    return Pattern{
        .transform = Matrix.identity(),
        .transform_inverse = Matrix.identity(),
        .pattern = pattern,
    };
}

pub fn checker(a: Color, b: Color) Pattern {
    return init(patterns.Pattern.init_checker(a, b));
}
pub fn gradient(a: Color, b: Color) Pattern {
    return init(patterns.Pattern.init_gradient(a, b));
}
pub fn ring(a: Color, b: Color) Pattern {
    return init(patterns.Pattern.init_ring(a, b));
}
pub fn stripe(a: Color, b: Color) Pattern {
    return init(patterns.Pattern.init_stripe(a, b));
}
pub fn _test() Pattern {
    return init(patterns.Pattern.init_test());
}

pub fn with_transform(self: Pattern, transform: Matrix) Pattern {
    return Pattern{
        .transform = transform,
        .transform_inverse = transform.inverse(),
        .pattern = self.pattern,
    };
}

pub fn color_at(self: Pattern, object: Object, world_point: Tuple) Color {
    const object_point = object.transform_inverse.mult(world_point);
    const pattern_point = self.transform_inverse.mult(object_point);
    return self.pattern.color_at(pattern_point);
}

test "Pattern with an object transformation" {
    const object = Object.sphere().with_transform(scaling(2, 2, 2));
    const pattern = stripe(Color.WHITE, Color.BLACK);
    const c = pattern.color_at(object, Tuple.point(1.5, 0, 0));
    try Color.expectEqual(Color.WHITE, c);
}

test "Pattern with a pattern transformation" {
    const object = Object.sphere();
    const pattern = stripe(Color.WHITE, Color.BLACK).with_transform(scaling(2, 2, 2));
    const c = pattern.color_at(object, Tuple.point(1.5, 0, 0));
    try Color.expectEqual(Color.WHITE, c);
}

test "Pattern with both an object and a pattern transformation" {
    const object = Object.sphere().with_transform(scaling(2, 2, 2));
    const pattern = stripe(Color.WHITE, Color.BLACK).with_transform(translation(0.5, 0, 0));
    const c = pattern.color_at(object, Tuple.point(2.5, 0, 0));
    try Color.expectEqual(Color.WHITE, c);
}
