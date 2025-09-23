const std = @import("std");
const rt_zig = @import("rt_zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ray_origin = rt_zig.tuples.point(0, 0, -5);
    const wall_z: rt_zig.floats.Float = 10.0;
    const wall_size: rt_zig.floats.Float = 7.0;
    const canvas_pixels = 400;
    const canvas_pixel_f: rt_zig.floats.Float = @floatFromInt(canvas_pixels);
    const pixel_size = wall_size / canvas_pixel_f;
    const half = wall_size / 2.0;
    const canvas = rt_zig.canvas.canvas(allocator, canvas_pixels, canvas_pixels);
    var shape = rt_zig.spheres.sphere();
    shape.material.color = rt_zig.colors.color(1, 0.2, 1);
    const light = rt_zig.lights.point_light(rt_zig.tuples.point(-10, 10, -10), rt_zig.colors.WHITE);

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
            const position = rt_zig.tuples.point(world_x, world_y, wall_z);
            const direction = rt_zig.tuples.sub(position, ray_origin);
            const r = rt_zig.rays.ray(ray_origin, rt_zig.tuples.normalize(direction));

            var buf = [_]rt_zig.intersections.Intersection{undefined} ** 10;
            const xs = rt_zig.spheres.intersect(&shape, r, &buf);
            if (rt_zig.intersections.hit(xs)) |hit| {
                const point = rt_zig.rays.position(r, hit.t);
                const normal = rt_zig.spheres.normal_at(shape, point);
                const eyev = rt_zig.tuples.neg(r.direction);
                const color = rt_zig.materials.lighting(shape.material, light, point, eyev, normal);
                rt_zig.canvas.write_pixel(canvas, x, y, color);
            }
            progress.completeOne();
        }
    }

    const ppm = rt_zig.canvas.to_ppm(canvas, allocator);
    try std.fs.cwd().writeFile(.{
        .sub_path = "examples/light_shading.ppm",
        .data = ppm,
    });
}
