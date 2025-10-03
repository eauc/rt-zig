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

    const floor = rt_zig.Object.plane()
        .with_transform(translation(0, -1, 0));

    const sphere = rt_zig.Object.sphere()
        .with_transform(translation(0, 1, 0));

    var world = rt_zig.World.init(allocator);
    world.add_light(rt_zig.Light.spot(
        rt_zig.Tuple.point(5, 7, -7),
        rt_zig.Color.RED,
        rt_zig.Tuple.vector(0, 0, 0).sub(rt_zig.Tuple.point(5, 7, -7)),
        std.math.pi / 8.0,
        0.5,
    ));
    world.add_light(rt_zig.Light.spot(
        rt_zig.Tuple.point(5, 7, 0),
        rt_zig.Color.GREEN,
        rt_zig.Tuple.vector(0, 0, 0).sub(rt_zig.Tuple.point(5, 7, 0)),
        std.math.pi / 8.0,
        0.5,
    ));
    world.add_light(rt_zig.Light.spot(
        rt_zig.Tuple.point(5, 7, 7),
        rt_zig.Color.BLUE,
        rt_zig.Tuple.vector(0, 0, 0).sub(rt_zig.Tuple.point(5, 7, 7)),
        std.math.pi / 8.0,
        0.5,
    ));
    world.add_object(floor);
    world.add_object(sphere);

    var camera = rt_zig.Camera.init(800, 600, 1, std.math.pi / 3.0);
    camera.transform = view_transform(
        rt_zig.Tuple.point(6, 2, 0),
        rt_zig.Tuple.point(0, 1, 0),
        rt_zig.Tuple.vector(0, 1, 0),
    );

    std.debug.print("Lights\n", .{});
    const image = camera.render(world, allocator);
    const ppm = image.to_ppm(allocator);

    try std.fs.cwd().writeFile(.{
        .sub_path = "examples/lights.ppm",
        .data = ppm,
    });
}
