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

    var floor = rt_zig.Object.plane().with_transform(translation(0, -1, 0));
    floor.material.pattern = rt_zig.Pattern.checker(rt_zig.Color.WHITE, rt_zig.Color.BLACK);
    floor.material.specular = 0;
    floor.material.reflective = 0.5;

    var middle = rt_zig.Object.cone()
        .truncate(1, 2, true)
        .with_transform(translation(0, -0.5, 0));
    middle.material.color = rt_zig.Color.init(0.1, 1, 0.5);
    middle.material.diffuse = 0.7;
    middle.material.specular = 0.3;
    middle.material.reflective = 0.3;

    const right = rt_zig.Object.cone()
        .truncate(-100, 0, false)
        .made_of_glass()
        .with_transform(rotation_z(-rt_zig.floats.pi / 6).mul(translation(1, 5, 3)).mul(scaling(1, 4, 1)));

    var left = rt_zig.Object.cone()
        .truncate(-1, 1, false)
        .with_transform(translation(3, 1, 0)
        .mul(rotation_x(rt_zig.floats.pi / 6))
        .mul(rotation_z(rt_zig.floats.pi / 6))
        .mul(scaling(0.5, 0.5, 0.5)));
    left.material.color = rt_zig.Color.init(1, 0.8, 0.1);
    left.material.diffuse = 0.7;
    left.material.specular = 0.3;
    left.material.reflective = 0.3;

    var world = rt_zig.World.init(allocator);
    world.add_light(rt_zig.PointLight.init(rt_zig.Tuple.point(15, 2.2, 15), rt_zig.Color.WHITE));
    world.add_object(floor);
    world.add_object(middle);
    world.add_object(right);
    world.add_object(left);

    var camera = rt_zig.Camera.init(800, 600, std.math.pi / 3.0);
    camera.transform = view_transform(
        rt_zig.Tuple.point(7, 2, 7),
        rt_zig.Tuple.point(0, 1, 0),
        rt_zig.Tuple.vector(0, 1, 0),
    );

    const image = camera.render(world, allocator);
    const ppm = image.to_ppm(allocator);

    try std.fs.cwd().writeFile(.{
        .sub_path = "examples/cones.ppm",
        .data = ppm,
    });
}
