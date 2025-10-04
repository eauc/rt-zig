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

focal_length: Float,
aperture: Float,
hsize: usize,
vsize: usize,
field_of_view: Float,
half_width: Float,
half_height: Float,
pixel_size: Float,
transform: Matrix,
reflection_depth: usize,
oversampling: usize,
blur_oversampling: usize,

pub fn init(hsize: usize, vsize: usize, focal_length: Float, field_of_view: Float) Camera {
    const half_view = focal_length * std.math.tan(field_of_view / 2);
    const hsize_f: Float = @floatFromInt(hsize);
    const vsize_f: Float = @floatFromInt(vsize);
    const aspect: Float = hsize_f / vsize_f;
    var c = Camera{
        .focal_length = focal_length,
        .aperture = 0,
        .hsize = hsize,
        .vsize = vsize,
        .field_of_view = field_of_view,
        .half_width = 0,
        .half_height = 0,
        .pixel_size = 0,
        .transform = Matrix.identity(),
        .reflection_depth = 5,
        .oversampling = 2,
        .blur_oversampling = 1,
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
    const c = init(160, 120, 1, floats.pi / 2);
    try std.testing.expectEqual(160, c.hsize);
    try std.testing.expectEqual(120, c.vsize);
    try std.testing.expectEqual(floats.pi / 2, c.field_of_view);
    try std.testing.expectEqual(Matrix.identity(), c.transform);
}

test "The pixel size for a horizontal canvas" {
    const c = init(200, 125, 1, floats.pi / 2);
    try floats.expectEqual(0.01, c.pixel_size);
}

test "The pixel size for a vertical canvas" {
    const c = init(125, 200, 1, floats.pi / 2);
    try floats.expectEqual(0.01, c.pixel_size);
}

/// Construct a ray for a pixel
pub fn rays_for_pixel(self: Camera, x: usize, y: usize, buf: []Ray) []Ray {
    const x_f: Float = @floatFromInt(x);
    const y_f: Float = @floatFromInt(y);

    const oversampling_f: Float = @floatFromInt(self.oversampling);
    const offset: Float = 1 / oversampling_f;
    const start_offset: Float = offset / 2;
    var ray_count: usize = 0;
    for (0..self.oversampling) |i| {
        for (0..self.oversampling) |j| {
            const i_f: Float = @floatFromInt(i);
            const j_f: Float = @floatFromInt(j);
            const offset_x = (x_f + start_offset + i_f * offset) * self.pixel_size;
            const offset_y = (y_f + start_offset + j_f * offset) * self.pixel_size;
            const rays = self.rays_for_coordinates(offset_x, offset_y, buf[ray_count..]);
            ray_count += rays.len;
        }
    }
    return buf[0..ray_count];
}

fn rays_for_coordinates(self: Camera, offset_x: Float, offset_y: Float, buf: []Ray) []Ray {
    const world_x = self.half_width - offset_x;
    const world_y = self.half_height - offset_y;
    const pixel = self.transform.inverse().mult(Tuple.point(world_x, world_y, -self.focal_length));
    const aperture = self.focal_length * self.aperture;
    for (0..self.blur_oversampling) |i| {
        const dv = if (self.blur_oversampling > 1) Tuple.vector(floats.random(aperture), floats.random(aperture), 0) else Tuple.vector(0, 0, 0);
        const lens_origin = Tuple.point(0, 0, 0).add(dv);
        const origin = self.transform.inverse().mult(lens_origin);
        const direction = Tuple.normalize(Tuple.sub(pixel, origin));
        buf[i] = Ray.init(origin, direction);
    }
    return buf[0..self.blur_oversampling];
}

test "Constructing a ray through the center of the canvas" {
    var c = init(201, 101, 1, floats.pi / 2);
    c.oversampling = 1;
    var buf = [_]Ray{undefined} ** 32;
    const rs = rays_for_pixel(c, 100, 50, &buf);
    try Tuple.expectEqual(Tuple.point(0, 0, 0), rs[0].origin);
    try Tuple.expectEqual(Tuple.vector(0, 0, -1), rs[0].direction);
}

test "Constructing a ray through a corner of the canvas" {
    var c = init(201, 101, 1, floats.pi / 2);
    c.oversampling = 1;
    var buf = [_]Ray{undefined} ** 32;
    const rs = rays_for_pixel(c, 0, 0, &buf);
    try Tuple.expectEqual(Tuple.point(0, 0, 0), rs[0].origin);
    try Tuple.expectEqual(Tuple.vector(0.66519, 0.33259, -0.66851), rs[0].direction);
}

test "Constructing a ray when the camera is transformed" {
    var c = init(201, 101, 1, floats.pi / 2);
    c.oversampling = 1;
    c.transform = transformations.rotation_y(floats.pi / 4).mul(transformations.translation(0, -2, 5));
    var buf = [_]Ray{undefined} ** 32;
    const rs = rays_for_pixel(c, 100, 50, &buf);
    try Tuple.expectEqual(Tuple.point(0, 2, -5), rs[0].origin);
    try Tuple.expectEqual(Tuple.vector(floats.sqrt2 / 2, 0, -floats.sqrt2 / 2), rs[0].direction);
}

const THREAD_COUNT = 8;

pub fn render(self: Camera, w: World, allocator: std.mem.Allocator) Canvas {
    var world = w;
    world.prepare();
    var image = Canvas.init(allocator, self.hsize, self.vsize);
    var progress = std.Progress.start(.{
        .root_name = "Rendering",
        .estimated_total_items = self.vsize * self.hsize,
        .initial_delay_ns = 0,
    });
    const chunk_size = self.vsize / THREAD_COUNT;
    var threads = [_]std.Thread{undefined} ** THREAD_COUNT;
    for (0..threads.len) |i| {
        threads[i] = std.Thread.spawn(.{}, _render, .{RenderParams{
            .camera = &self,
            .world = &world,
            .image = &image,
            .progress = &progress,
            .start = i * chunk_size,
            .chunk_size = chunk_size,
        }}) catch unreachable;
    }
    for (threads) |thread| {
        thread.join();
    }
    progress.end();
    return image;
}

const RenderParams = struct {
    camera: *const Camera,
    world: *const World,
    image: *Canvas,
    progress: *std.Progress.Node,
    start: usize,
    chunk_size: usize,
};

fn _render(args: RenderParams) void {
    for (args.start..args.start + args.chunk_size) |y| {
        for (0..args.camera.hsize) |x| {
            var buf = [_]Ray{undefined} ** 256;
            const rays = args.camera.rays_for_pixel(x, y, &buf);
            var color = Color.BLACK;
            for (rays) |ray| {
                color = color.add(args.world.color_at(ray, args.camera.reflection_depth));
            }
            const scale: Float = @floatFromInt(rays.len);
            color = color.muls(1 / scale);
            args.image.write_pixel(x, y, color);
            args.progress.completeOne();
        }
    }
}

test "Rendering a world with a camera" {
    var w = World.default(std.testing.allocator);
    defer w.deinit();

    var c = init(11, 11, 1, floats.pi / 2);
    c.oversampling = 1;
    const from = Tuple.point(0, 0, -5);
    const to = Tuple.point(0, 0, 0);
    const up = Tuple.vector(0, 1, 0);
    c.transform = transformations.view_transform(from, to, up);

    const image = render(c, w, std.testing.allocator);
    defer image.deinit();

    try Color.expectEqual(Color.init(0.38066, 0.47583, 0.2855), image.pixel(5, 5));
}
