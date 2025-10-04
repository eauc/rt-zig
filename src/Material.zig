const std = @import("std");
const Color = @import("Color.zig");
const floats = @import("floats.zig");
const Float = floats.Float;
const Material = @This();
const Object = @import("Object.zig");
const Pattern = @import("Pattern.zig");
const Light = @import("Light.zig");
const Tuple = @import("Tuple.zig");

pattern: ?Pattern,
color: Color,
ambient: Float,
diffuse: Float,
specular: Float,
shininess: Float,
reflective: Float,
transparency: Float,
refractive_index: Float,

pub fn init() Material {
    return Material{
        .pattern = null,
        .color = Color.WHITE,
        .ambient = 0.1,
        .diffuse = 0.9,
        .specular = 0.9,
        .shininess = 200.0,
        .reflective = 0.0,
        .transparency = 0.0,
        .refractive_index = 1.0,
    };
}

test "The default material" {
    const m = init();
    try Color.expectEqual(Color.WHITE, m.color);
    try floats.expectEqual(0.1, m.ambient);
    try floats.expectEqual(0.9, m.diffuse);
    try floats.expectEqual(0.9, m.specular);
    try floats.expectEqual(200.0, m.shininess);
    try floats.expectEqual(0.0, m.reflective);
    try floats.expectEqual(0.0, m.transparency);
    try floats.expectEqual(1.0, m.refractive_index);
}

pub fn glass() Material {
    return Material{
        .pattern = null,
        .color = Color.WHITE,
        .ambient = 0.0,
        .diffuse = 0.1,
        .specular = 0.9,
        .shininess = 500.0,
        .reflective = 0.1,
        .transparency = 1.0,
        .refractive_index = 1.5,
    };
}

test "Glass" {
    const m = glass();
    try Color.expectEqual(Color.WHITE, m.color);
    try floats.expectEqual(0.1, m.reflective);
    try floats.expectEqual(1.0, m.transparency);
    try floats.expectEqual(1.5, m.refractive_index);
}

/// Calculate the lighting for a given material, light, and position
pub fn lighting(m: Material, object: Object, ambient_light: Color, lights: []const Light, point: Tuple, eyev: Tuple, normalv: Tuple) Color {
    var color = m.color;
    if (m.pattern) |pattern| {
        color = pattern.color_at(object, point);
    }
    var effective_color = color.mul(ambient_light);
    const ambient = effective_color.muls(m.ambient);

    var diffuse: Color = Color.BLACK;
    var specular: Color = Color.BLACK;
    for (lights) |light| {
        if (light.intensity.equal(Color.BLACK)) continue;

        effective_color = color.mul(light.intensity);
        const lightv = light.position.sub(point).normalize();
        const light_dot_normal = lightv.dot(normalv);
        if (light_dot_normal > 0) {
            diffuse = diffuse.add(effective_color.muls(m.diffuse).muls(light_dot_normal));
            const reflectv = lightv.neg().reflect(normalv);
            const reflect_dot_eye = reflectv.dot(eyev);
            if (reflect_dot_eye > 0) {
                const factor = std.math.pow(Float, reflect_dot_eye, m.shininess);
                specular = specular.add(light.intensity.muls(m.specular).muls(factor));
            }
        }
    }
    return ambient.add(diffuse).add(specular);
}

test "Lighting with the eye between the light and the surface" {
    const m = init();
    const position = Tuple.point(0, 0, 0);
    const eyev = Tuple.vector(0, 0, -1);
    const normalv = Tuple.vector(0, 0, -1);
    const light = Light.point(Tuple.point(0, 0, -10), Color.WHITE);
    const object = Object.sphere();
    const result = m.lighting(object, Color.WHITE, &[_]Light{light}, position, eyev, normalv);
    try Color.expectEqual(Color.init(1.9, 1.9, 1.9), result);
}

test "Lighting with the eye between light and surface, eye offset 45°" {
    const m = init();
    const position = Tuple.point(0, 0, 0);
    const eyev = Tuple.vector(0, floats.sqrt2 / 2, -floats.sqrt2 / 2);
    const normalv = Tuple.vector(0, 0, -1);
    const light = Light.point(Tuple.point(0, 0, -10), Color.init(1, 1, 1));
    const object = Object.sphere();
    const result = m.lighting(object, Color.WHITE, &[_]Light{light}, position, eyev, normalv);
    try Color.expectEqual(Color.init(1.0, 1.0, 1.0), result);
}

test "Lighting with eye opposite surface, light offset 45°" {
    const m = init();
    const position = Tuple.point(0, 0, 0);
    const eyev = Tuple.vector(0, 0, -1);
    const normalv = Tuple.vector(0, 0, -1);
    const light = Light.point(Tuple.point(0, 10, -10), Color.init(1, 1, 1));
    const object = Object.sphere();
    const result = m.lighting(object, Color.WHITE, &[_]Light{light}, position, eyev, normalv);
    try Color.expectEqual(Color.init(0.7364, 0.7364, 0.7364), result);
}

test "Lighting with eye in the path of the reflection vector" {
    const m = init();
    const position = Tuple.point(0, 0, 0);
    const eyev = Tuple.vector(0, -floats.sqrt2 / 2, -floats.sqrt2 / 2);
    const normalv = Tuple.vector(0, 0, -1);
    const light = Light.point(Tuple.point(0, 10, -10), Color.init(1, 1, 1));
    const object = Object.sphere();
    const result = m.lighting(object, Color.WHITE, &[_]Light{light}, position, eyev, normalv);
    try Color.expectEqual(Color.init(1.63639, 1.63639, 1.63639), result);
}

test "Lighting with the light behind the surface" {
    const m = init();
    const position = Tuple.point(0, 0, 0);
    const eyev = Tuple.vector(0, 0, -1);
    const normalv = Tuple.vector(0, 0, -1);
    const light = Light.point(Tuple.point(0, 0, 10), Color.init(1, 1, 1));
    const object = Object.sphere();
    const result = m.lighting(object, Color.WHITE, &[_]Light{light}, position, eyev, normalv);
    try Color.expectEqual(Color.init(0.1, 0.1, 0.1), result);
}

test "Lighting with the surface in shadow" {
    const m = init();
    const position = Tuple.point(0, 0, 0);
    const eyev = Tuple.vector(0, 0, -1);
    const normalv = Tuple.vector(0, 0, -1);
    // when in shadow, light intensity is BLACK
    const light = Light.point(Tuple.point(0, 0, -10), Color.BLACK);
    const object = Object.sphere();
    const result = m.lighting(object, Color.WHITE, &[_]Light{light}, position, eyev, normalv);
    try Color.expectEqual(Color.init(0.1, 0.1, 0.1), result);
}

test "Lighting with a pattern applied" {
    var m = init();
    m.pattern = Pattern.stripe(Color.WHITE, Color.BLACK);
    m.ambient = 1;
    m.diffuse = 0;
    m.specular = 0;
    const eyev = Tuple.vector(0, 0, -1);
    const normalv = Tuple.vector(0, 0, -1);
    const light = Light.point(Tuple.point(0, 0, -10), Color.WHITE);
    const object = Object.sphere();
    const c1 = m.lighting(object, Color.WHITE, &[_]Light{light}, Tuple.point(0.9, 0, 0), eyev, normalv);
    const c2 = m.lighting(object, Color.WHITE, &[_]Light{light}, Tuple.point(1.1, 0, 0), eyev, normalv);
    try Color.expectEqual(Color.WHITE, c1);
    try Color.expectEqual(Color.BLACK, c2);
}
