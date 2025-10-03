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

    var red = rt_zig.Material.init();
    red.color = rt_zig.Color.RED;
    var blue = rt_zig.Material.init();
    blue.color = rt_zig.Color.BLUE;
    var green = rt_zig.Material.init();
    green.color = rt_zig.Color.GREEN;

    const csg = rt_zig.Object.csg(
        allocator,
        ._intersection,
        rt_zig.Object.sphere().with_transform(scaling(1.4, 1.4, 1.4)).with_material(red),
        rt_zig.Object.csg(
            allocator,
            ._difference,
            rt_zig.Object.cube().with_material(blue),
            rt_zig.Object.csg(
                allocator,
                ._union,
                rt_zig.Object.cylinder().truncate(-2, 2, false).with_transform(rotation_z(std.math.pi / 2.0).mul(scaling(0.5, 1, 0.5))).with_material(green),
                rt_zig.Object.csg(
                    allocator,
                    ._union,
                    rt_zig.Object.cylinder().truncate(-2, 2, false).with_transform(rotation_x(std.math.pi / 2.0).mul(scaling(0.5, 1, 0.5))).with_material(green),
                    rt_zig.Object.cylinder().truncate(-2, 2, false).with_transform(scaling(0.5, 1, 0.5)).with_material(green),
                ),
            ),
        ),
    );

    var world = rt_zig.World.init(allocator);
    world.add_light(rt_zig.Light.point(rt_zig.Tuple.point(15, 15, 5), rt_zig.Color.WHITE));
    world.add_object(csg);

    var camera = rt_zig.Camera.init(800, 600, 1, std.math.pi / 3.0);
    camera.transform = view_transform(
        rt_zig.Tuple.point(4, 4, 4),
        rt_zig.Tuple.point(0, 0, 0),
        rt_zig.Tuple.vector(0, 1, 0),
    );

    std.debug.print("CSG\n", .{});
    const image = camera.render(world, allocator);
    const ppm = image.to_ppm(allocator);

    try std.fs.cwd().writeFile(.{
        .sub_path = "examples/csg.ppm",
        .data = ppm,
    });
}
