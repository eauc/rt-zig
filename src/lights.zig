const tuples = @import("tuples.zig");
const Tuple = tuples.Tuple;
const colors = @import("colors.zig");
const Color = colors.Color;

pub const PointLight = struct {
    position: Tuple,
    intensity: Color,
};

pub fn point_light(position: Tuple, intensity: Color) PointLight {
    return PointLight{
        .position = position,
        .intensity = intensity,
    };
}

test "A point light has a position and intensity" {
    const position = tuples.point(0, 0, 0);
    const intensity = colors.WHITE;
    const light = point_light(position, intensity);
    try tuples.expectEqual(position, light.position);
    try colors.expectEqual(intensity, light.intensity);
}
