const std = @import("std");
const rt_zig = @import("rt_zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ray_origin = rt_zig.Tuple.point(0, 0, -5);
    const wall_z: rt_zig.floats.Float = 10.0;
    const wall_size: rt_zig.floats.Float = 7.0;
    const canvas_pixels = 400;
    const canvas_pixel_f: rt_zig.floats.Float = @floatFromInt(canvas_pixels);
    const pixel_size = wall_size / canvas_pixel_f;
    const half = wall_size / 2.0;
    var canvas = rt_zig.Canvas.init(allocator, canvas_pixels, canvas_pixels);
    var shape = rt_zig.Sphere.init();
    shape.material.color = rt_zig.Color.init(1, 0.2, 1);
    const light = rt_zig.PointLight.init(rt_zig.Tuple.point(-10, 10, -10), rt_zig.Color.WHITE);

    const progress = std.Progress.start(.{
        .root_name = "rendering",
        .estimated_total_items = canvas_pixels * canvas_pixels,
        .initial_delay_ns = 0,
    });
    defer progress.end();

    for (0..canvas_pixels) |y| {
        const y_f: rt_zig.floats.Float = @floatFromInt(y);
        const world_y = half - pixel_size * y_f;
        for (0..canvas_pixels) |x| {
            const x_f: rt_zig.floats.Float = @floatFromInt(x);
            const world_x = -half + pixel_size * x_f;
            const position = rt_zig.Tuple.point(world_x, world_y, wall_z);
            const direction = rt_zig.Tuple.sub(position, ray_origin);
            const r = rt_zig.Ray.init(ray_origin, direction.normalize());

            var buf = [_]rt_zig.Intersection{undefined} ** 10;
            const xs = shape.intersect(r, &buf);
            if (rt_zig.Intersection.hit(xs)) |hit| {
                const point = r.position(hit.t);
                const normal = shape.normal_at(point);
                const eyev = r.direction.neg();
                const color = shape.material.lighting(light, point, eyev, normal, false);
                canvas.write_pixel(x, y, color);
            }
            progress.completeOne();
        }
    }

    const ppm = canvas.to_ppm(allocator);
    try std.fs.cwd().writeFile(.{
        .sub_path = "examples/light_shading.ppm",
        .data = ppm,
    });
}
