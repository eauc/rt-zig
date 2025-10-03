const std = @import("std");
const floats = @import("../floats.zig");
const Float = floats.Float;
const SpotLight = @This();
const Tuple = @import("../Tuple.zig");
const World = @import("../World.zig");

direction: Tuple,
width: Float,
fade_factor: Float,

pub fn init(direction: Tuple, width: Float, fade_factor: Float) SpotLight {
    return SpotLight{
        .direction = direction.normalize(),
        .width = width,
        .fade_factor = fade_factor,
    };
}

pub fn shadow_factor(self: SpotLight, to: Tuple, from: Tuple, world: World) Float {
    const is_shadowed = world.is_shadowed(to, from);
    if (is_shadowed) return 0;
    const light_to_point = to.sub(from);
    const f = light_to_point.dot(self.direction);
    const d = light_to_point.magnitude();
    const cos = f / d;
    const angle = std.math.acos(cos);
    if (angle > self.width) return 0;
    if (angle > self.width * self.fade_factor) return 1 - std.math.pow(Float, (angle - self.width * self.fade_factor) / (self.width * (1 - self.fade_factor)), 2);
    return 1;
}
