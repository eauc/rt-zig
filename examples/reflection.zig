const std = @import("std");
const rt_zig = @import("rt_zig");
const rotation_x = rt_zig.transformations.rotation_x;
const rotation_y = rt_zig.transformations.rotation_y;
const rotation_z = rt_zig.transformations.rotation_z;
const scaling = rt_zig.transformations.scaling;
const translation = rt_zig.transformations.translation;
const view_transform = rt_zig.transformations.view_transform;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var floor = rt_zig.Object.plane();
    floor.material.pattern = rt_zig.Pattern.checker(rt_zig.Color.WHITE, rt_zig.Color.BLACK);
    floor.material.specular = 0;
    floor.material.reflective = 0.2;

    var wall = rt_zig.Object.plane()
        .with_transform(translation(-10, 0, 0)
        .mul(rotation_z(std.math.pi / 2.0)));
    wall.material.color = rt_zig.Color.init(0.3, 1, 1);
    wall.material.specular = 0;
    wall.material.shininess = 0;

    var sphere = rt_zig.Object.sphere()
        .with_transform(translation(0, 1, 0));
    sphere.material.reflective = 0.9;

    var world = rt_zig.World.init(allocator);
    world.add_light(rt_zig.Light.point(rt_zig.Tuple.point(10, 10, 10), rt_zig.Color.WHITE));
    world.add_object(floor);
    world.add_object(wall);
    world.add_object(sphere);

    var camera = rt_zig.Camera.init(800, 600, std.math.pi / 3.0);
    camera.transform = view_transform(
        rt_zig.Tuple.point(5, 2, 0),
        rt_zig.Tuple.point(0, 1, 0),
        rt_zig.Tuple.vector(0, 1, 0),
    );

    const image = camera.render(world, allocator);
    const ppm = image.to_ppm(allocator);

    try std.fs.cwd().writeFile(.{
        .sub_path = "examples/reflection.ppm",
        .data = ppm,
    });
}
