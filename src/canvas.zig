const std = @import("std");
const colors = @import("colors.zig");
const Color = colors.Color;
const BLACK = colors.BLACK;
const RED = colors.RED;
const floats = @import("floats.zig");
const Float = floats.Float;

pub const Canvas = struct {
    allocator: std.mem.Allocator,
    width: usize,
    height: usize,
    pixels: []Color,
};

/// Creates a new canvas with the given width and height
pub fn canvas(allocator: std.mem.Allocator, new_width: usize, new_height: usize) Canvas {
    return Canvas{
        .allocator = allocator,
        .width = new_width,
        .height = new_height,
        .pixels = allocator.alloc(Color, new_width * new_height) catch unreachable,
    };
}

pub fn deinit(c: Canvas) void {
    c.allocator.free(c.pixels);
}

/// Returns the width of the canvas
pub fn width(c: Canvas) usize {
    return c.width;
}

/// Returns the height of the canvas
pub fn height(c: Canvas) usize {
    return c.height;
}

/// Returns the color of the pixel at (x, y)
pub fn pixel(c: Canvas, x: usize, y: usize) Color {
    return c.pixels[y * c.width + x];
}

test canvas {
    const allocator = std.testing.allocator;
    const c = canvas(allocator, 10, 20);
    defer deinit(c);

    try std.testing.expectEqual(10, width(c));
    try std.testing.expectEqual(20, height(c));
    for (0..height(c)) |h| {
        for (0..width(c)) |w| {
            try colors.expectEqual(BLACK, pixel(c, w, h));
        }
    }
}

/// Sets the color of the pixel at (x, y)
pub fn write_pixel(c: *Canvas, x: usize, y: usize, color: Color) void {
    c.pixels[y * c.width + x] = color;
}

test write_pixel {
    const allocator = std.testing.allocator;
    var c = canvas(allocator, 10, 20);
    defer deinit(c);

    write_pixel(&c, 2, 3, RED);
    try colors.expectEqual(RED, pixel(c, 2, 3));
}

/// Converts the canvas to a PPM string
pub fn to_ppm(c: Canvas, allocator: std.mem.Allocator) []const u8 {
    var str_buf = [_]u8{0} ** 256;
    var result = std.ArrayList(u8){};
    const header = printPPMHeader(c, &str_buf);
    result.appendSlice(allocator, header) catch unreachable;
    for (0..height(c)) |y| {
        for (0..width(c)) |x| {
            const color = pixel(c, x, y);
            const pixel_string = std.fmt.bufPrint(&str_buf, "{} {} {}{s}", .{
                colorComponentToInteger(color[0]),
                colorComponentToInteger(color[1]),
                colorComponentToInteger(color[2]),
                if (x == width(c) - 1) "\n" else " ",
            }) catch unreachable;
            // TODO : split line every 70 chars
            result.appendSlice(allocator, pixel_string) catch unreachable;
        }
    }
    return result.toOwnedSlice(allocator) catch unreachable;
}

fn printPPMHeader(c: Canvas, buf: []u8) []const u8 {
    return std.fmt.bufPrint(buf, "P3\n{} {}\n255\n", .{ width(c), height(c) }) catch unreachable;
}

fn colorComponentToInteger(c: Float) u8 {
    return @intFromFloat(std.math.clamp(std.math.round(c * 255), 0, 255));
}

test "Constructing the PPM header" {
    const allocator = std.testing.allocator;
    const c = canvas(allocator, 5, 3);
    defer deinit(c);

    const ppm = to_ppm(c, allocator);
    defer allocator.free(ppm);

    var it = std.mem.splitAny(u8, ppm, "\n");
    try std.testing.expectEqualStrings("P3", it.next().?);
    try std.testing.expectEqualStrings("5 3", it.next().?);
    try std.testing.expectEqualStrings("255", it.next().?);
}

test "Constructing the PPM pixel data" {
    const allocator = std.testing.allocator;
    var c = canvas(allocator, 5, 3);
    defer deinit(c);
    write_pixel(&c, 0, 0, colors.color(1.5, 0, 0));
    write_pixel(&c, 2, 1, colors.color(0, 0.5, 0));
    write_pixel(&c, 4, 2, colors.color(-0.5, 0, 1));

    const ppm = to_ppm(c, allocator);
    defer allocator.free(ppm);

    var it = std.mem.splitAny(u8, ppm, "\n");
    _ = it.next();
    _ = it.next();
    _ = it.next();
    try std.testing.expectEqualStrings("255 0 0 0 0 0 0 0 0 0 0 0 0 0 0", it.next().?);
    try std.testing.expectEqualStrings("0 0 0 0 0 0 0 128 0 0 0 0 0 0 0", it.next().?);
    try std.testing.expectEqualStrings("0 0 0 0 0 0 0 0 0 0 0 0 0 0 255", it.next().?);
}

test "PPM files are terminated by a newline" {
    const allocator = std.testing.allocator;
    const c = canvas(allocator, 5, 3);
    defer deinit(c);

    const ppm = to_ppm(c, allocator);
    defer allocator.free(ppm);

    try std.testing.expectEqual('\n', ppm[ppm.len - 1]);
}
