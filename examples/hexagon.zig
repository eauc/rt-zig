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

    const hex = hexagon(allocator);

    var world = rt_zig.World.init(allocator);
    world.add_light(rt_zig.Light.point(rt_zig.Tuple.point(15, 15, 15), rt_zig.Color.init(1, 0.2, 1)));
    world.add_object(hex);

    var camera = rt_zig.Camera.init(800, 600, 1, std.math.pi / 3.0);
    camera.transform = view_transform(
        rt_zig.Tuple.point(4, 4, 4),
        rt_zig.Tuple.point(0, 0, 0),
        rt_zig.Tuple.vector(0, 1, 0),
    );

    std.debug.print("Hexagon\n", .{});
    const image = camera.render(world, allocator);
    const ppm = image.to_ppm(allocator);

    try std.fs.cwd().writeFile(.{
        .sub_path = "examples/hexagon.ppm",
        .data = ppm,
    });
}

fn hexagon_corner() rt_zig.Object {
    return rt_zig.Object.sphere()
        .with_transform(translation(0, 0, -1)
        .mul(scaling(0.25, 0.25, 0.25)));
}

fn hexagon_edge() rt_zig.Object {
    return rt_zig.Object.cylinder()
        .truncate(0, 1, false)
        .with_transform(translation(0, 0, -1)
        .mul(rotation_y(-std.math.pi / 6.0))
        .mul(rotation_z(-std.math.pi / 2.0))
        .mul(scaling(0.25, 1, 0.25)));
}

fn hexagon_side(allocator: std.mem.Allocator) rt_zig.Object {
    var side = rt_zig.Object.group(allocator);
    _ = side.as_group().add_child(hexagon_corner());
    _ = side.as_group().add_child(hexagon_edge());
    return side;
}

fn hexagon(allocator: std.mem.Allocator) rt_zig.Object {
    var hex = rt_zig.Object.group(allocator);
    for (0..6) |i| {
        const i_f: rt_zig.floats.Float = @floatFromInt(i);
        const side = hexagon_side(allocator).with_transform(rotation_y(i_f * std.math.pi / 3.0));
        _ = hex.as_group().add_child(side);
    }
    return hex;
}
