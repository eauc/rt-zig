const std = @import("std");
const rt_zig = @import("rt_zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var floor = rt_zig.spheres.sphere();
    floor.transform = rt_zig.transformations.scaling(10, 0.01, 10);
    floor.material.color = rt_zig.colors.color(1, 0.9, 0.9);
    floor.material.specular = 0;

    var left_wall = rt_zig.spheres.sphere();
    left_wall.transform = rt_zig.matrices.mul(rt_zig.transformations.translation(0, 0, 5), rt_zig.matrices.mul(rt_zig.transformations.rotation_y(-std.math.pi / 4.0), rt_zig.matrices.mul(rt_zig.transformations.rotation_x(std.math.pi / 2.0), rt_zig.transformations.scaling(10, 0.01, 10))));
    left_wall.material = floor.material;

    var right_wall = rt_zig.spheres.sphere();
    right_wall.transform = rt_zig.matrices.mul(rt_zig.matrices.mul(rt_zig.matrices.mul(rt_zig.transformations.translation(0, 0, 5), rt_zig.transformations.rotation_y(std.math.pi / 4.0)), rt_zig.transformations.rotation_x(std.math.pi / 2.0)), rt_zig.transformations.scaling(10, 0.01, 10));
    right_wall.material = floor.material;

    var middle = rt_zig.spheres.sphere();
    middle.transform = rt_zig.transformations.translation(-0.5, 1, 0.5);
    middle.material.color = rt_zig.colors.color(0.1, 1, 0.5);
    middle.material.diffuse = 0.7;
    middle.material.specular = 0.3;

    var right = rt_zig.spheres.sphere();
    right.transform = rt_zig.matrices.mul(rt_zig.transformations.translation(1.5, 0.5, -0.5), rt_zig.transformations.scaling(0.5, 0.5, 0.5));
    right.material.color = rt_zig.colors.color(0.5, 1, 0.1);
    right.material.diffuse = 0.7;
    right.material.specular = 0.3;

    var left = rt_zig.spheres.sphere();
    left.transform = rt_zig.matrices.mul(rt_zig.transformations.translation(-1.5, 0.33, -0.75), rt_zig.transformations.scaling(0.33, 0.33, 0.33));
    left.material.color = rt_zig.colors.color(1, 0.8, 0.1);
    left.material.diffuse = 0.7;
    left.material.specular = 0.3;

    var world = rt_zig.worlds.world(allocator);
    rt_zig.worlds.add_light(&world, rt_zig.lights.point_light(rt_zig.tuples.point(-10, 10, -10), rt_zig.colors.WHITE));
    rt_zig.worlds.add_object(&world, floor);
    rt_zig.worlds.add_object(&world, left_wall);
    rt_zig.worlds.add_object(&world, right_wall);
    rt_zig.worlds.add_object(&world, middle);
    rt_zig.worlds.add_object(&world, right);
    rt_zig.worlds.add_object(&world, left);

    var camera = rt_zig.cameras.camera(400, 200, std.math.pi / 3.0);
    camera.transform = rt_zig.transformations.view_transform(
        rt_zig.tuples.point(0, 1.5, -5),
        rt_zig.tuples.point(0, 1, 0),
        rt_zig.tuples.vector(0, 1, 0),
    );

    const image = rt_zig.cameras.render(camera, world, allocator);
    const ppm = rt_zig.canvas.to_ppm(image, allocator);

    try std.fs.cwd().writeFile(.{
        .sub_path = "examples/spheres_scene.ppm",
        .data = ppm,
    });
}
