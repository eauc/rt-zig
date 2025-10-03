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

    const obj_file_low = try rt_zig.ObjFile.parse_file(allocator, "examples/teapot_low.obj");
    const obj_file = try rt_zig.ObjFile.parse_file(allocator, "examples/teapot.obj");

    var world_low = rt_zig.World.init(allocator);
    world_low.add_light(rt_zig.Light.point(rt_zig.Tuple.point(50, 50, 50), rt_zig.Color.WHITE));
    world_low.add_object(obj_file_low.default_group);

    var world = rt_zig.World.init(allocator);
    world.add_light(rt_zig.Light.point(rt_zig.Tuple.point(50, 50, 50), rt_zig.Color.WHITE));
    world.add_object(obj_file.default_group);

    var camera = rt_zig.Camera.init(1000, 800, 1, std.math.pi / 3.0);
    camera.transform = view_transform(
        rt_zig.Tuple.point(25, 25, 25),
        rt_zig.Tuple.point(0, 0, 10),
        rt_zig.Tuple.vector(0, 0, 1),
    );

    std.debug.print("Teapot low\n", .{});
    const image_low = camera.render(world_low, allocator);
    const ppm_low = image_low.to_ppm(allocator);
    try std.fs.cwd().writeFile(.{
        .sub_path = "examples/teapot_low.ppm",
        .data = ppm_low,
    });

    std.debug.print("Teapot\n", .{});
    const image = camera.render(world, allocator);
    const ppm = image.to_ppm(allocator);
    try std.fs.cwd().writeFile(.{
        .sub_path = "examples/teapot.ppm",
        .data = ppm,
    });
}
