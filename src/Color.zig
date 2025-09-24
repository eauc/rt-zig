const Color = @This();
const floats = @import("floats.zig");
const Float = floats.Float;

red: Float,
green: Float,
blue: Float,

/// Colors are (red, green, blue) tuples
pub fn init(new_red: Float, new_green: Float, new_blue: Float) Color {
    return Color{
        .red = new_red,
        .green = new_green,
        .blue = new_blue,
    };
}

pub const BLACK = init(0, 0, 0);
pub const WHITE = init(1, 1, 1);
pub const RED = init(1, 0, 0);
pub const GREEN = init(0, 1, 0);
pub const BLUE = init(0, 0, 1);

test init {
    const c = init(-0.5, 0.4, 1.7);
    try floats.expectEqual(-0.5, c.red);
    try floats.expectEqual(0.4, c.green);
    try floats.expectEqual(1.7, c.blue);
}

pub fn expectEqual(a: Color, b: Color) !void {
    try floats.expectEqual(a.red, b.red);
    try floats.expectEqual(a.green, b.green);
    try floats.expectEqual(a.blue, b.blue);
}

/// Add two colors
pub fn add(self: Color, b: Color) Color {
    return init(self.red + b.red, self.green + b.green, self.blue + b.blue);
}

test add {
    const c1 = init(0.9, 0.6, 0.75);
    const c2 = init(0.7, 0.1, 0.25);
    try expectEqual(init(1.6, 0.7, 1.0), add(c1, c2));
}

/// Subtract two colors
pub fn sub(self: Color, b: Color) Color {
    return init(self.red - b.red, self.green - b.green, self.blue - b.blue);
}

test sub {
    const c1 = init(0.9, 0.6, 0.75);
    const c2 = init(0.7, 0.1, 0.25);
    try expectEqual(init(0.2, 0.5, 0.5), sub(c1, c2));
}

/// Multiply a color by a scalar
pub fn muls(self: Color, scalar: Float) Color {
    return init(self.red * scalar, self.green * scalar, self.blue * scalar);
}

test muls {
    const c = init(0.2, 0.3, 0.4);
    try expectEqual(init(0.4, 0.6, 0.8), muls(c, 2.0));
}

/// Multiply two colors
pub fn mul(self: Color, b: Color) Color {
    return init(self.red * b.red, self.green * b.green, self.blue * b.blue);
}

test mul {
    const c1 = init(1.0, 0.2, 0.4);
    const c2 = init(0.9, 1.0, 0.1);
    try expectEqual(init(0.9, 0.2, 0.04), mul(c1, c2));
}
