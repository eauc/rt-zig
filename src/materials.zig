const std = @import("std");
const colors = @import("colors.zig");
const Color = colors.Color;
const floats = @import("floats.zig");
const Float = floats.Float;
const lights = @import("lights.zig");
const PointLight = lights.PointLight;
const tuples = @import("tuples.zig");
const Tuple = tuples.Tuple;

pub const Material = struct {
    color: Color,
    ambient: Float,
    diffuse: Float,
    specular: Float,
    shininess: Float,
};

pub fn material() Material {
    return Material{
        .color = colors.WHITE,
        .ambient = 0.1,
        .diffuse = 0.9,
        .specular = 0.9,
        .shininess = 200.0,
    };
}

test "The default material" {
    const m = material();
    try colors.expectEqual(colors.color(1, 1, 1), m.color);
    try floats.expectEqual(0.1, m.ambient);
    try floats.expectEqual(0.9, m.diffuse);
    try floats.expectEqual(0.9, m.specular);
    try floats.expectEqual(200.0, m.shininess);
}

/// Calculate the lighting for a given material, light, and position
pub fn lighting(m: Material, light: PointLight, point: Tuple, eyev: Tuple, normalv: Tuple) Color {
    const effective_color = colors.mul(m.color, light.intensity);
    const lightv = tuples.normalize(tuples.sub(light.position, point));
    const ambient = colors.muls(effective_color, m.ambient);
    const light_dot_normal = tuples.dot(lightv, normalv);
    var diffuse: Color = colors.BLACK;
    var specular: Color = colors.BLACK;
    if (light_dot_normal > 0) {
        diffuse = colors.muls(colors.muls(effective_color, m.diffuse), light_dot_normal);
        const reflectv = tuples.reflect(tuples.neg(lightv), normalv);
        const reflect_dot_eye = tuples.dot(reflectv, eyev);
        if (reflect_dot_eye > 0) {
            const factor = std.math.pow(Float, reflect_dot_eye, m.shininess);
            specular = colors.muls(colors.muls(light.intensity, m.specular), factor);
        }
    }
    return colors.add(ambient, colors.add(diffuse, specular));
}

test "Lighting with the eye between the light and the surface" {
    const m = material();
    const position = tuples.point(0, 0, 0);
    const eyev = tuples.vector(0, 0, -1);
    const normalv = tuples.vector(0, 0, -1);
    const light = lights.point_light(tuples.point(0, 0, -10), colors.color(1, 1, 1));
    const result = lighting(m, light, position, eyev, normalv);
    try colors.expectEqual(colors.color(1.9, 1.9, 1.9), result);
}

test "Lighting with the eye between light and surface, eye offset 45°" {
    const m = material();
    const position = tuples.point(0, 0, 0);
    const eyev = tuples.vector(0, floats.sqrt2 / 2, -floats.sqrt2 / 2);
    const normalv = tuples.vector(0, 0, -1);
    const light = lights.point_light(tuples.point(0, 0, -10), colors.color(1, 1, 1));
    const result = lighting(m, light, position, eyev, normalv);
    try colors.expectEqual(colors.color(1.0, 1.0, 1.0), result);
}

test "Lighting with eye opposite surface, light offset 45°" {
    const m = material();
    const position = tuples.point(0, 0, 0);
    const eyev = tuples.vector(0, 0, -1);
    const normalv = tuples.vector(0, 0, -1);
    const light = lights.point_light(tuples.point(0, 10, -10), colors.color(1, 1, 1));
    const result = lighting(m, light, position, eyev, normalv);
    try colors.expectEqual(colors.color(0.7364, 0.7364, 0.7364), result);
}

test "Lighting with eye in the path of the reflection vector" {
    const m = material();
    const position = tuples.point(0, 0, 0);
    const eyev = tuples.vector(0, -floats.sqrt2 / 2, -floats.sqrt2 / 2);
    const normalv = tuples.vector(0, 0, -1);
    const light = lights.point_light(tuples.point(0, 10, -10), colors.color(1, 1, 1));
    const result = lighting(m, light, position, eyev, normalv);
    try colors.expectEqual(colors.color(1.63638, 1.63638, 1.63638), result);
}

test "Lighting with the light behind the surface" {
    const m = material();
    const position = tuples.point(0, 0, 0);
    const eyev = tuples.vector(0, 0, -1);
    const normalv = tuples.vector(0, 0, -1);
    const light = lights.point_light(tuples.point(0, 0, 10), colors.color(1, 1, 1));
    const result = lighting(m, light, position, eyev, normalv);
    try colors.expectEqual(colors.color(0.1, 0.1, 0.1), result);
}
