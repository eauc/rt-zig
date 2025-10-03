const std = @import("std");
const Color = @import("Color.zig");
const floats = @import("floats.zig");
const Float = floats.Float;
const Light = @This();
const CubeLight = @import("lights/CubeLight.zig");
const PointLight = @import("lights/PointLight.zig");
const SphereLight = @import("lights/SphereLight.zig");
const SpotLight = @import("lights/SpotLight.zig");
const Tuple = @import("Tuple.zig");
const World = @import("World.zig");

const Shape = union(enum) {
    cube: CubeLight,
    point: PointLight,
    sphere: SphereLight,
    spot: SpotLight,

    pub fn shadow_factor(self: Shape, to: Tuple, from: Tuple, world: World) Float {
        return switch (self) {
            inline else => |s| s.shadow_factor(to, from, world),
        };
    }
};

position: Tuple,
intensity: Color,
shape: Shape,

fn init(position: Tuple, intensity: Color, shape: Shape) Light {
    return Light{
        .position = position,
        .intensity = intensity,
        .shape = shape,
    };
}

pub fn cube(position: Tuple, intensity: Color, size: Float, oversampling: usize) Light {
    return init(position, intensity, Shape{ .cube = CubeLight.init(size, oversampling) });
}
pub fn point(position: Tuple, intensity: Color) Light {
    return init(position, intensity, Shape{ .point = PointLight.init() });
}
pub fn sphere(position: Tuple, intensity: Color, radius: Float, oversampling: usize) Light {
    return init(position, intensity, Shape{ .sphere = SphereLight.init(radius, oversampling) });
}
pub fn spot(position: Tuple, intensity: Color, direction: Tuple, width: Float, fade_factor: Float) Light {
    return init(position, intensity, Shape{ .spot = SpotLight.init(direction, width, fade_factor) });
}

test "A light has a position and intensity" {
    const position = Tuple.point(0, 0, 0);
    const intensity = Color.WHITE;
    const light = Light.point(position, intensity);
    try Tuple.expectEqual(position, light.position);
    try Color.expectEqual(intensity, light.intensity);
}

pub fn shadowed(self: Light, to: Tuple, world: World) Light {
    const factor = self.shape.shadow_factor(to, self.position, world);
    return Light{
        .position = self.position,
        .intensity = self.intensity.muls(factor),
        .shape = self.shape,
    };
}
