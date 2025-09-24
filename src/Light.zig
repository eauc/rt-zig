const Tuple = @import("Tuple.zig");
const Color = @import("Color.zig");
const PointLight = @This();

position: Tuple,
intensity: Color,

pub fn init(position: Tuple, intensity: Color) PointLight {
    return PointLight{
        .position = position,
        .intensity = intensity,
    };
}

test "A point light has a position and intensity" {
    const position = Tuple.point(0, 0, 0);
    const intensity = Color.WHITE;
    const light = init(position, intensity);
    try Tuple.expectEqual(position, light.position);
    try Color.expectEqual(intensity, light.intensity);
}
