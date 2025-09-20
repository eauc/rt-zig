const floats = @import("floats.zig");
const Float = floats.Float;

pub const Color = [3]Float;

/// Colors are (red, green, blue) tuples
pub fn color(new_red: Float, new_green: Float, new_blue: Float) Color {
    return Color{ new_red, new_green, new_blue };
}

pub const BLACK = color(0, 0, 0);
pub const WHITE = color(1, 1, 1);
pub const RED = color(1, 0, 0);
pub const GREEN = color(0, 1, 0);
pub const BLUE = color(0, 0, 1);

pub fn red(c: Color) Float {
    return c[0];
}

pub fn green(c: Color) Float {
    return c[1];
}

pub fn blue(c: Color) Float {
    return c[2];
}

test color {
    const c = color(-0.5, 0.4, 1.7);
    try floats.expectEqual(-0.5, red(c));
    try floats.expectEqual(0.4, green(c));
    try floats.expectEqual(1.7, blue(c));
}

pub fn expectEqual(a: Color, b: Color) !void {
    try floats.expectEqual(a[0], b[0]);
    try floats.expectEqual(a[1], b[1]);
    try floats.expectEqual(a[2], b[2]);
}

/// Add two colors
pub fn add(a: Color, b: Color) Color {
    return color(a[0] + b[0], a[1] + b[1], a[2] + b[2]);
}

test add {
    const c1 = color(0.9, 0.6, 0.75);
    const c2 = color(0.7, 0.1, 0.25);
    try expectEqual(color(1.6, 0.7, 1.0), add(c1, c2));
}

/// Subtract two colors
pub fn sub(a: Color, b: Color) Color {
    return color(a[0] - b[0], a[1] - b[1], a[2] - b[2]);
}

test sub {
    const c1 = color(0.9, 0.6, 0.75);
    const c2 = color(0.7, 0.1, 0.25);
    try expectEqual(color(0.2, 0.5, 0.5), sub(c1, c2));
}

/// Multiply a color by a scalar
pub fn muls(c: Color, scalar: Float) Color {
    return color(c[0] * scalar, c[1] * scalar, c[2] * scalar);
}

test muls {
    const c = color(0.2, 0.3, 0.4);
    try expectEqual(color(0.4, 0.6, 0.8), muls(c, 2.0));
}

/// Multiply two colors
pub fn mul(a: Color, b: Color) Color {
    return color(a[0] * b[0], a[1] * b[1], a[2] * b[2]);
}

test mul {
    const c1 = color(1.0, 0.2, 0.4);
    const c2 = color(0.9, 1.0, 0.1);
    try expectEqual(color(0.9, 0.2, 0.04), mul(c1, c2));
}
