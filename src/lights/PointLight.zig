const floats = @import("../floats.zig");
const Float = floats.Float;
const PointLight = @This();
const Tuple = @import("../Tuple.zig");
const World = @import("../World.zig");

pub fn init() PointLight {
    return PointLight{};
}

pub fn shadow_factor(_: PointLight, to: Tuple, from: Tuple, world: World) Float {
    return if (world.is_shadowed(to, from)) 0 else 1;
}
