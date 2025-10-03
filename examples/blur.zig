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
    floor.material.ambient = 0;
    floor.material.diffuse = 0.8;
    floor.material.specular = 0.5;

    var red = rt_zig.Object.sphere().with_transform(translation(0, 1.5, 0));
    red.material.color = rt_zig.Color.RED;

    var green = rt_zig.Object.sphere().with_transform(translation(2, 1, 1).mul(scaling(0.5, 0.5, 0.5)));
    green.material.color = rt_zig.Color.GREEN;

    var blue = rt_zig.Object.sphere().with_transform(translation(-3, 1.5, -4));
    blue.material.color = rt_zig.Color.BLUE;

    var world = rt_zig.World.init(allocator);
    world.add_light(rt_zig.Light.point(rt_zig.Tuple.point(5, 5, 0), rt_zig.Color.WHITE));
    world.add_object(floor);
    world.add_object(red);
    world.add_object(green);
    world.add_object(blue);

    var camera = rt_zig.Camera.init(1000, 800, 4, std.math.pi / 2.0);
    camera.transform = view_transform(
        rt_zig.Tuple.point(0, 1, 0).add(rt_zig.Tuple.vector(1, 0.1, 0).muls(4)),
        rt_zig.Tuple.point(0, 1, 0),
        rt_zig.Tuple.vector(0, 1, 0),
    );
    camera.aperture = 0.05;
    camera.blur_oversampling = 20;

    std.debug.print("Blur\n", .{});
    const image = camera.render(world, allocator);
    const ppm = image.to_ppm(allocator);

    try std.fs.cwd().writeFile(.{
        .sub_path = "examples/blur.ppm",
        .data = ppm,
    });
}
