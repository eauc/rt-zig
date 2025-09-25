const Color = @import("../Color.zig");
const Gradient = @This();
const Tuple = @import("../Tuple.zig");

a: Color,
b: Color,

pub fn init(a: Color, b: Color) Gradient {
    return Gradient{ .a = a, .b = b };
}

pub fn color_at(self: Gradient, point: Tuple) Color {
    return self.a.add(self.b.sub(self.a).muls(point.x));
}

test "A gradient linearly interpolates between colors" {
    const pattern = init(Color.WHITE, Color.BLACK);

    try Color.expectEqual(Color.WHITE, pattern.color_at(Tuple.point(0, 0, 0)));
    try Color.expectEqual(Color.init(0.75, 0.75, 0.75), pattern.color_at(Tuple.point(0.25, 0, 0)));
    try Color.expectEqual(Color.init(0.5, 0.5, 0.5), pattern.color_at(Tuple.point(0.5, 0, 0)));
    try Color.expectEqual(Color.init(0.25, 0.25, 0.25), pattern.color_at(Tuple.point(0.75, 0, 0)));
}
