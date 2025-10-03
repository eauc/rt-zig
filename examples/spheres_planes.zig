const std = @import("std");
const rt_zig = @import("rt_zig");
const rotation_x = rt_zig.transformations.rotation_x;
const rotation_y = rt_zig.transformations.rotation_y;
const scaling = rt_zig.transformations.scaling;
const translation = rt_zig.transformations.translation;
const view_transform = rt_zig.transformations.view_transform;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var floor = rt_zig.Object.plane();
    floor.material.color = rt_zig.Color.init(1, 0.9, 0.9);
    floor.material.specular = 0;

    var left_wall = rt_zig.Object.plane()
        .with_transform(translation(0, 0, 5)
        .mul(rotation_y(-std.math.pi / 4.0))
        .mul(rotation_x(std.math.pi / 2.0)));
    left_wall.material = floor.material;

    var right_wall = rt_zig.Object.plane()
        .with_transform(translation(0, 0, 5)
        .mul(rotation_y(std.math.pi / 4.0))
        .mul(rotation_x(std.math.pi / 2.0)));
    right_wall.material = floor.material;

    var middle = rt_zig.Object.sphere()
        .with_transform(translation(-0.5, 1, 0.5));
    middle.material.color = rt_zig.Color.init(0.1, 1, 0.5);
    middle.material.diffuse = 0.7;
    middle.material.specular = 0.3;

    var right = rt_zig.Object.sphere()
        .with_transform(translation(1.5, 0.5, -0.5)
        .mul(scaling(0.5, 0.5, 0.5)));
    right.material.color = rt_zig.Color.init(0.5, 1, 0.1);
    right.material.diffuse = 0.7;
    right.material.specular = 0.3;

    var left = rt_zig.Object.sphere()
        .with_transform(translation(-1.5, 0.33, -0.75)
        .mul(scaling(0.33, 0.33, 0.33)));
    left.material.color = rt_zig.Color.init(1, 0.8, 0.1);
    left.material.diffuse = 0.7;
    left.material.specular = 0.3;

    var world = rt_zig.World.init(allocator);
    world.add_light(rt_zig.Light.point(rt_zig.Tuple.point(-10, 10, -10), rt_zig.Color.WHITE));
    world.add_object(floor);
    world.add_object(left_wall);
    world.add_object(right_wall);
    world.add_object(middle);
    world.add_object(right);
    world.add_object(left);

    var camera = rt_zig.Camera.init(400, 200, std.math.pi / 3.0);
    camera.transform = view_transform(
        rt_zig.Tuple.point(0, 1.5, -5),
        rt_zig.Tuple.point(0, 1, 0),
        rt_zig.Tuple.vector(0, 1, 0),
    );

    const image = camera.render(world, allocator);
    const ppm = image.to_ppm(allocator);

    try std.fs.cwd().writeFile(.{
        .sub_path = "examples/spheres_planes.ppm",
        .data = ppm,
    });
}
