const std = @import("std");
const Checker = @import("patterns/Checker.zig");
const Color = @import("Color.zig");
const Gradient = @import("patterns/Gradient.zig");
const Object = @import("Object.zig");
const Ring = @import("patterns/Ring.zig");
const Stripe = @import("patterns/Stripe.zig");
const Tuple = @import("Tuple.zig");

pub const Pattern = union(enum) {
    checker: Checker,
    gradient: Gradient,
    ring: Ring,
    stripe: Stripe,
    _test: Test,

    pub fn init_checker(a: Color, b: Color) Pattern {
        return Pattern{ .checker = Checker.init(a, b) };
    }
    pub fn init_gradient(a: Color, b: Color) Pattern {
        return Pattern{ .gradient = Gradient.init(a, b) };
    }
    pub fn init_ring(a: Color, b: Color) Pattern {
        return Pattern{ .ring = Ring.init(a, b) };
    }
    pub fn init_stripe(a: Color, b: Color) Pattern {
        return Pattern{ .stripe = Stripe.init(a, b) };
    }
    pub fn init_test() Pattern {
        return Pattern{ ._test = Test.init() };
    }

    pub fn color_at(self: Pattern, point: Tuple) Color {
        return switch (self) {
            inline else => |p| p.color_at(point),
        };
    }
};

const Test = struct {
    pub fn init() Test {
        return Test{};
    }
    pub fn color_at(_: Test, point: Tuple) Color {
        return Color.init(point.x, point.y, point.z);
    }
};
