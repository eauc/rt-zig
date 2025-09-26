const std = @import("std");
const Camera = @This();
const Canvas = @import("Canvas.zig");
const Color = @import("Color.zig");
const floats = @import("floats.zig");
const Float = floats.Float;
const Matrix = @import("Matrix.zig");
const Ray = @import("Ray.zig");
const transformations = @import("transformations.zig");
const Tuple = @import("Tuple.zig");
const World = @import("World.zig");

hsize: usize,
vsize: usize,
field_of_view: Float,
half_width: Float,
half_height: Float,
pixel_size: Float,
transform: Matrix,
reflection_depth: usize,

pub fn init(hsize: usize, vsize: usize, field_of_view: Float) Camera {
    const half_view = std.math.tan(field_of_view / 2);
    const hsize_f: Float = @floatFromInt(hsize);
    const vsize_f: Float = @floatFromInt(vsize);
    const aspect: Float = hsize_f / vsize_f;
    var c = Camera{
        .hsize = hsize,
        .vsize = vsize,
        .field_of_view = field_of_view,
        .half_width = 0,
        .half_height = 0,
        .pixel_size = 0,
        .transform = Matrix.identity(),
        .reflection_depth = 5,
    };
    if (aspect > 1) {
        c.half_width = half_view;
        c.half_height = half_view / aspect;
    } else {
        c.half_width = half_view * aspect;
        c.half_height = half_view;
    }
    c.pixel_size = c.half_width * 2 / hsize_f;
    return c;
}

test init {
    const c = init(160, 120, floats.pi / 2);
    try std.testing.expectEqual(160, c.hsize);
    try std.testing.expectEqual(120, c.vsize);
    try std.testing.expectEqual(floats.pi / 2, c.field_of_view);
    try std.testing.expectEqual(Matrix.identity(), c.transform);
}

test "The pixel size for a horizontal canvas" {
    const c = init(200, 125, floats.pi / 2);
    try std.testing.expectEqual(0.01, c.pixel_size);
}

test "The pixel size for a vertical canvas" {
    const c = init(125, 200, floats.pi / 2);
    try std.testing.expectEqual(0.01, c.pixel_size);
}

/// Construct a ray for a pixel
pub fn ray_for_pixel(self: Camera, x: usize, y: usize) Ray {
    const x_f: Float = @floatFromInt(x);
    const y_f: Float = @floatFromInt(y);
    const offset_x = (x_f + 0.5) * self.pixel_size;
    const offset_y = (y_f + 0.5) * self.pixel_size;
    const world_x = self.half_width - offset_x;
    const world_y = self.half_height - offset_y;
    const pixel = self.transform.inverse().mult(Tuple.point(world_x, world_y, -1));
    const origin = self.transform.inverse().mult(Tuple.point(0, 0, 0));
    const direction = Tuple.normalize(Tuple.sub(pixel, origin));
    return Ray.init(origin, direction);
}

test "Constructing a ray through the center of the canvas" {
    const c = init(201, 101, floats.pi / 2);
    const r = ray_for_pixel(c, 100, 50);
    try Tuple.expectEqual(Tuple.point(0, 0, 0), r.origin);
    try Tuple.expectEqual(Tuple.vector(0, 0, -1), r.direction);
}

test "Constructing a ray through a corner of the canvas" {
    const c = init(201, 101, floats.pi / 2);
    const r = ray_for_pixel(c, 0, 0);
    try Tuple.expectEqual(Tuple.point(0, 0, 0), r.origin);
    try Tuple.expectEqual(Tuple.vector(0.66519, 0.33259, -0.66851), r.direction);
}

test "Constructing a ray when the camera is transformed" {
    var c = init(201, 101, floats.pi / 2);
    c.transform = transformations.rotation_y(floats.pi / 4).mul(transformations.translation(0, -2, 5));
    const r = ray_for_pixel(c, 100, 50);
    try Tuple.expectEqual(Tuple.point(0, 2, -5), r.origin);
    try Tuple.expectEqual(Tuple.vector(floats.sqrt2 / 2, 0, -floats.sqrt2 / 2), r.direction);
}

pub fn render(self: Camera, w: World, allocator: std.mem.Allocator) Canvas {
    var image = Canvas.init(allocator, self.hsize, self.vsize);
    var progress = std.Progress.start(.{
        .root_name = "Rendering",
        .estimated_total_items = self.vsize * self.hsize,
        .initial_delay_ns = 0,
    });
    for (0..self.vsize) |y| {
        for (0..self.hsize) |x| {
            const ray = ray_for_pixel(self, x, y);
            const color = w.color_at(ray, self.reflection_depth);
            image.write_pixel(x, y, color);
            progress.completeOne();
        }
    }
    progress.end();
    return image;
}

test "Rendering a world with a camera" {
    var w = World.default(std.testing.allocator);
    defer w.deinit();

    var c = init(11, 11, floats.pi / 2);
    const from = Tuple.point(0, 0, -5);
    const to = Tuple.point(0, 0, 0);
    const up = Tuple.vector(0, 1, 0);
    c.transform = transformations.view_transform(from, to, up);

    const image = render(c, w, std.testing.allocator);
    defer image.deinit();

    try Color.expectEqual(Color.init(0.38066, 0.47583, 0.2855), image.pixel(5, 5));
}
