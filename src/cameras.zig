const std = @import("std");
const canvas = @import("canvas.zig");
const Canvas = canvas.Canvas;
const colors = @import("colors.zig");
const floats = @import("floats.zig");
const Float = floats.Float;
const matrices = @import("matrices.zig");
const rays = @import("rays.zig");
const Ray = rays.Ray;
const transformations = @import("transformations.zig");
const tuples = @import("tuples.zig");
const worlds = @import("worlds.zig");
const World = worlds.World;

const Camera = struct {
    hsize: usize,
    vsize: usize,
    field_of_view: Float,
    half_width: Float,
    half_height: Float,
    pixel_size: Float,
    transform: matrices.Matrix,
};

pub fn camera(hsize: usize, vsize: usize, field_of_view: f32) Camera {
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
        .transform = matrices.identity(),
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

test camera {
    const c = camera(160, 120, floats.pi / 2);
    try std.testing.expectEqual(160, c.hsize);
    try std.testing.expectEqual(120, c.vsize);
    try std.testing.expectEqual(floats.pi / 2, c.field_of_view);
    try std.testing.expectEqual(matrices.identity(), c.transform);
}

test "The pixel size for a horizontal canvas" {
    const c = camera(200, 125, floats.pi / 2);
    try std.testing.expectEqual(0.01, c.pixel_size);
}

test "The pixel size for a vertical canvas" {
    const c = camera(125, 200, floats.pi / 2);
    try std.testing.expectEqual(0.01, c.pixel_size);
}

/// Construct a ray for a pixel
pub fn ray_for_pixel(c: Camera, x: usize, y: usize) Ray {
    const x_f: Float = @floatFromInt(x);
    const y_f: Float = @floatFromInt(y);
    const offset_x = (x_f + 0.5) * c.pixel_size;
    const offset_y = (y_f + 0.5) * c.pixel_size;
    const world_x = c.half_width - offset_x;
    const world_y = c.half_height - offset_y;
    const pixel = matrices.mult(matrices.inverse(c.transform), tuples.point(world_x, world_y, -1));
    const origin = matrices.mult(matrices.inverse(c.transform), tuples.point(0, 0, 0));
    const direction = tuples.normalize(tuples.sub(pixel, origin));
    return rays.ray(origin, direction);
}

test "Constructing a ray through the center of the canvas" {
    const c = camera(201, 101, floats.pi / 2);
    const r = ray_for_pixel(c, 100, 50);
    try tuples.expectEqual(tuples.point(0, 0, 0), r.origin);
    try tuples.expectEqual(tuples.vector(0, 0, -1), r.direction);
}

test "Constructing a ray through a corner of the canvas" {
    const c = camera(201, 101, floats.pi / 2);
    const r = ray_for_pixel(c, 0, 0);
    try tuples.expectEqual(tuples.point(0, 0, 0), r.origin);
    try tuples.expectEqual(tuples.vector(0.66519, 0.33259, -0.66851), r.direction);
}

test "Constructing a ray when the camera is transformed" {
    var c = camera(201, 101, floats.pi / 2);
    c.transform = matrices.mul(transformations.rotation_y(floats.pi / 4), transformations.translation(0, -2, 5));
    const r = ray_for_pixel(c, 100, 50);
    try tuples.expectEqual(tuples.point(0, 2, -5), r.origin);
    try tuples.expectEqual(tuples.vector(floats.sqrt2 / 2, 0, -floats.sqrt2 / 2), r.direction);
}

pub fn render(c: Camera, w: World, allocator: std.mem.Allocator) Canvas {
    var image = canvas.canvas(allocator, c.hsize, c.vsize);
    var progress = std.Progress.start(.{
        .root_name = "Rendering",
        .estimated_total_items = c.vsize * c.hsize,
        .initial_delay_ns = 0,
    });
    for (0..c.vsize) |y| {
        for (0..c.hsize) |x| {
            const ray = ray_for_pixel(c, x, y);
            const color = worlds.color_at(w, ray);
            canvas.write_pixel(&image, x, y, color);
            progress.completeOne();
        }
    }
    progress.end();
    return image;
}

test "Rendering a world with a camera" {
    var w = worlds.default_world(std.testing.allocator);
    defer worlds.deinit(&w);

    var c = camera(11, 11, floats.pi / 2);
    const from = tuples.point(0, 0, -5);
    const to = tuples.point(0, 0, 0);
    const up = tuples.vector(0, 1, 0);
    c.transform = transformations.view_transform(from, to, up);

    const image = render(c, w, std.testing.allocator);
    defer canvas.deinit(image);

    try colors.expectEqual(colors.color(0.38066, 0.47583, 0.2855), canvas.pixel(image, 5, 5));
}
