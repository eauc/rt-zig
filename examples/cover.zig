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

    var white_material = rt_zig.Material.init();
    white_material.color = rt_zig.Color.WHITE;
    white_material.diffuse = 0.7;
    white_material.ambient = 0.1;
    white_material.specular = 0.0;
    white_material.reflective = 0.1;
    var blue_material = white_material;
    blue_material.color = rt_zig.Color.init(0.537, 0.831, 0.914);
    var red_material = white_material;
    red_material.color = rt_zig.Color.init(0.941, 0.322, 0.388);
    var purple_material = white_material;
    purple_material.color = rt_zig.Color.init(0.373, 0.404, 0.550);

    const standard_transform = scaling(0.5, 0.5, 0.5).mul(translation(1.0, -1.0, 1.0));
    const large_object = scaling(3.5, 3.5, 3.5).mul(standard_transform);
    const medium_object = scaling(3.0, 3.0, 3.0).mul(standard_transform);
    const small_object = scaling(2.0, 2.0, 2.0).mul(standard_transform);

    var bg = rt_zig.Object.plane()
        .with_transform(translation(0.0, 0.0, 500.0).mul(rotation_x(1.5707963267948966)));
    bg.material.color = rt_zig.Color.WHITE;
    bg.material.ambient = 1.0;
    bg.material.diffuse = 0.0;
    bg.material.specular = 0.0;

    var sphere = rt_zig.Object.sphere().with_transform(large_object);
    sphere.material.color = rt_zig.Color.init(0.373, 0.404, 0.550);
    sphere.material.diffuse = 0.2;
    sphere.material.ambient = 0.0;
    sphere.material.specular = 1.0;
    sphere.material.shininess = 200.0;
    sphere.material.reflective = 0.7;
    sphere.material.transparency = 0.7;
    sphere.material.refractive_index = 1.5;

    var c1 = rt_zig.Object.cube().with_transform(translation(4.0, 0.0, 0.0).mul(medium_object));
    c1.material = white_material;
    var c2 = rt_zig.Object.cube().with_transform(translation(8.5, 1.5, -0.5).mul(large_object));
    c2.material = blue_material;
    var c3 = rt_zig.Object.cube().with_transform(translation(0.0, 0.0, 4.0).mul(large_object));
    c3.material = red_material;
    var c4 = rt_zig.Object.cube().with_transform(translation(4.0, 0.0, 4.0).mul(small_object));
    c4.material = white_material;
    var c5 = rt_zig.Object.cube().with_transform(translation(7.5, 0.5, 4.0).mul(medium_object));
    c5.material = purple_material;
    var c6 = rt_zig.Object.cube().with_transform(translation(-0.25, 0.25, 8.0).mul(medium_object));
    c6.material = white_material;
    var c7 = rt_zig.Object.cube().with_transform(translation(4.0, 1.0, 7.5).mul(large_object));
    c7.material = blue_material;
    var c8 = rt_zig.Object.cube().with_transform(translation(10.0, 2.0, 7.5).mul(medium_object));
    c8.material = red_material;
    var c9 = rt_zig.Object.cube().with_transform(translation(8.0, 2.0, 12.0).mul(small_object));
    c9.material = white_material;
    var c10 = rt_zig.Object.cube().with_transform(translation(20.0, 1.0, 9.0).mul(small_object));
    c10.material = white_material;
    var c11 = rt_zig.Object.cube().with_transform(translation(-0.5, -5.0, 0.25).mul(large_object));
    c11.material = blue_material;
    var c12 = rt_zig.Object.cube().with_transform(translation(4.0, -4.0, 0.0).mul(large_object));
    c12.material = red_material;
    var c13 = rt_zig.Object.cube().with_transform(translation(8.5, -4.0, 0.0).mul(large_object));
    c13.material = white_material;
    var c14 = rt_zig.Object.cube().with_transform(translation(0.0, -4.0, 4.0).mul(large_object));
    c14.material = white_material;
    var c15 = rt_zig.Object.cube().with_transform(translation(-0.5, -4.5, 8.0).mul(large_object));
    c15.material = purple_material;
    var c16 = rt_zig.Object.cube().with_transform(translation(0.0, -8.0, 4.0).mul(large_object));
    c16.material = white_material;
    var c17 = rt_zig.Object.cube().with_transform(translation(-0.5, -8.5, 8.0).mul(large_object));
    c17.material = white_material;

    const light1 = rt_zig.Light.point(rt_zig.Tuple.point(50, 100, -50), rt_zig.Color.WHITE);
    const light2 = rt_zig.Light.point(rt_zig.Tuple.point(-400, 50, -10), rt_zig.Color.init(0.2, 0.2, 0.2));

    var world = rt_zig.World.init(allocator);
    world.add_light(light1);
    world.add_light(light2);
    world.add_object(bg);
    world.add_object(sphere);
    world.add_object(c1);
    world.add_object(c2);
    world.add_object(c3);
    world.add_object(c4);
    world.add_object(c5);
    world.add_object(c6);
    world.add_object(c7);
    world.add_object(c8);
    world.add_object(c9);
    world.add_object(c10);
    world.add_object(c11);
    world.add_object(c12);
    world.add_object(c13);
    world.add_object(c14);
    world.add_object(c15);
    world.add_object(c16);
    world.add_object(c17);

    var camera = rt_zig.Camera.init(1000, 1000, 1, 0.785);
    camera.transform = view_transform(
        rt_zig.Tuple.point(-6, 6, -10),
        rt_zig.Tuple.point(6, 0, 6),
        rt_zig.Tuple.vector(-0.45, 1, 0),
    );

    std.debug.print("Cover\n", .{});
    const image = camera.render(world, allocator);
    const ppm = image.to_ppm(allocator);

    try std.fs.cwd().writeFile(.{
        .sub_path = "examples/cover.ppm",
        .data = ppm,
    });
}
