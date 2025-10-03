const std = @import("std");
const floats = @import("../floats.zig");
const Float = floats.Float;
const CubeLight = @This();
const Tuple = @import("../Tuple.zig");
const World = @import("../World.zig");

radius: Float,
oversampling: usize,

pub fn init(size: Float, oversampling: usize) CubeLight {
    return CubeLight{ .radius = size, .oversampling = oversampling };
}

pub fn shadow_factor(self: CubeLight, to: Tuple, from: Tuple, world: World) Float {
    var factor: Float = 0;
    for (0..self.oversampling) |_| {
        const dv = Tuple.random_vector(self.radius);
        factor += if (world.is_shadowed(to, from.add(dv))) 0 else 1;
    }
    const oversampling_f: Float = @floatFromInt(self.oversampling);
    return factor / oversampling_f;
}
