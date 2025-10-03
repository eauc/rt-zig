const std = @import("std");
const Color = @import("Color.zig");
const floats = @import("floats.zig");
const Float = floats.Float;
const Intersection = @import("Intersection.zig");
const PointLight = @import("Light.zig");
const Material = @import("Material.zig");
const Object = @import("Object.zig");
const Pattern = @import("Pattern.zig");
const Ray = @import("Ray.zig");
const transformations = @import("transformations.zig");
const Tuple = @import("Tuple.zig");
const World = @This();

allocator: std.mem.Allocator,
objects: std.ArrayList(Object),
ambient_light: Color,
lights: std.ArrayList(PointLight),

pub fn init(allocator: std.mem.Allocator) World {
    return World{
        .allocator = allocator,
        .objects = std.ArrayList(Object){},
        .ambient_light = Color.WHITE,
        .lights = std.ArrayList(PointLight){},
    };
}

pub fn deinit(self: *World) void {
    self.objects.deinit(self.allocator);
    self.lights.deinit(self.allocator);
}

pub fn add_object(self: *World, o: Object) void {
    self.objects.append(self.allocator, o) catch unreachable;
}

pub fn add_light(self: *World, l: PointLight) void {
    self.lights.append(self.allocator, l) catch unreachable;
}

test "Creating a world" {
    const allocator = std.testing.allocator;

    var w = init(allocator);
    defer w.deinit();

    try std.testing.expectEqual(0, w.objects.items.len);
    try std.testing.expectEqual(0, w.lights.items.len);
}

pub fn default(allocator: std.mem.Allocator) World {
    var w = init(allocator);

    const light = PointLight.init(Tuple.point(-10, 10, -10), Color.WHITE);
    var s1 = Object.sphere();
    s1.material.color = Color.init(0.8, 1.0, 0.6);
    s1.material.diffuse = 0.7;
    s1.material.specular = 0.2;
    const s2 = Object.sphere().with_transform(transformations.scaling(0.5, 0.5, 0.5));

    add_object(&w, s1);
    add_object(&w, s2);
    add_light(&w, light);

    return w;
}

test default {
    const allocator = std.testing.allocator;

    const light = PointLight.init(Tuple.point(-10, 10, -10), Color.WHITE);
    var s1 = Object.sphere();
    s1.material.color = Color.init(0.8, 1.0, 0.6);
    s1.material.diffuse = 0.7;
    s1.material.specular = 0.2;
    const s2 = Object.sphere().with_transform(transformations.scaling(0.5, 0.5, 0.5));

    var w = default(allocator);
    defer w.deinit();

    try std.testing.expectEqual(light, w.lights.items[0]);
    try std.testing.expectEqual(s1, w.objects.items[0]);
    try std.testing.expectEqual(s2, w.objects.items[1]);
}

pub fn prepare(self: *World) void {
    for (self.objects.items) |*object| {
        object.prepare();
    }
}

pub fn intersect(w: World, r: Ray, buf: []Intersection) []Intersection {
    var count: usize = 0;
    for (w.objects.items) |*object| {
        const xs = object.intersect(r, buf[count..]);
        count += xs.len;
    }
    Intersection.sort(buf[0..count]);
    return buf[0..count];
}

test intersect {
    const allocator = std.testing.allocator;
    var w = default(allocator);
    defer w.deinit();

    const r = Ray.init(Tuple.point(0, 0, -5), Tuple.vector(0, 0, 1));
    var buf = [_]Intersection{undefined} ** 10;
    const xs = intersect(w, r, &buf);

    try std.testing.expectEqual(4, xs.len);
    try std.testing.expectEqual(4.0, xs[0].t);
    try std.testing.expectEqual(4.5, xs[1].t);
    try std.testing.expectEqual(5.5, xs[2].t);
    try std.testing.expectEqual(6.0, xs[3].t);
}

/// Shade an intersection
pub fn shade_hit(self: World, hit: Intersection, comps: Intersection.Computations, depth: usize) Color {
    var shadowed_lights = [_]PointLight{undefined} ** 10;
    std.debug.assert(self.lights.items.len <= shadowed_lights.len);
    for (self.lights.items, 0..) |light, i| {
        const in_shadow = self.is_shadowed(comps.over_point, light);
        shadowed_lights[i] = light;
        if (in_shadow) {
            shadowed_lights[i].intensity = Color.BLACK;
        }
    }
    const surface = hit.object.material.lighting(hit.object.*, self.ambient_light, shadowed_lights[0..self.lights.items.len], comps.over_point, comps.eyev, comps.normalv);
    const reflected = self.reflected_color(hit, comps, depth);
    const refracted = self.refracted_color(hit, comps, depth);

    const material = hit.object.material;
    if (material.reflective > 0 and material.transparency > 0) {
        const reflectance = comps.schlick();
        return surface.add(reflected.muls(reflectance)).add(refracted.muls(1 - reflectance));
    }
    return surface.add(reflected).add(refracted);
}

test shade_hit {
    var w = default(std.testing.allocator);
    defer w.deinit();

    const r = Ray.init(Tuple.point(0, 0, -5), Tuple.vector(0, 0, 1));
    const shape = &w.objects.items[0];
    const i = Intersection.init(4, shape);
    const comps = i.init_computations(r, &[_]Intersection{i});
    const c = shade_hit(w, i, comps, 1);
    try Color.expectEqual(Color.init(0.38066, 0.47583, 0.2855), c);
}

test "Shading an intersection from the inside" {
    var w = default(std.testing.allocator);
    defer w.deinit();
    w.lights.items[0] = PointLight.init(Tuple.point(0, 0.25, 0), Color.WHITE);

    const r = Ray.init(Tuple.point(0, 0, 0), Tuple.vector(0, 0, 1));
    const shape = &w.objects.items[1];
    const i = Intersection.init(0.5, shape);
    const comps = i.init_computations(r, &[_]Intersection{i});
    const c = shade_hit(w, i, comps, 1);
    try Color.expectEqual(Color.init(0.90495, 0.90495, 0.90495), c);
}

test "Shading when the intersection is in shadow" {
    var w = default(std.testing.allocator);
    defer w.deinit();
    w.lights.items[0] = PointLight.init(Tuple.point(0, 0, -10), Color.WHITE);
    const s1 = Object.sphere();
    w.add_object(s1);
    var s2 = Object.sphere().with_transform(transformations.translation(0, 0, 10));
    w.add_object(s2);

    const r = Ray.init(Tuple.point(0, 0, 5), Tuple.vector(0, 0, 1));
    const i = Intersection.init(4, &s2);
    const comps = i.init_computations(r, &[_]Intersection{i});
    const c = shade_hit(w, i, comps, 1);
    try Color.expectEqual(Color.init(0.1, 0.1, 0.1), c);
}

test "Shading with a reflective material" {
    var w = default(std.testing.allocator);
    defer w.deinit();
    var shape = Object.plane().with_transform(transformations.translation(0, -1, 0));
    shape.material.reflective = 0.5;
    w.add_object(shape);

    const r = Ray.init(Tuple.point(0, 0, -3), Tuple.vector(0, -floats.sqrt2 / 2, floats.sqrt2 / 2));
    const i = Intersection.init(floats.sqrt2, &shape);
    const comps = i.init_computations(r, &[_]Intersection{i});
    const color = w.shade_hit(i, comps, 1);
    try Color.expectEqual(Color.init(0.87677, 0.92436, 0.82918), color);
}

test "Shading with a transparent material" {
    var w = default(std.testing.allocator);
    defer w.deinit();

    var floor = Object.plane().with_transform(transformations.translation(0, -1, 0));
    floor.material.transparency = 0.5;
    floor.material.refractive_index = 1.5;
    w.add_object(floor);

    var ball = Object.sphere().with_transform(transformations.translation(0, -3.5, -0.5));
    ball.material.color = Color.init(1, 0, 0);
    ball.material.ambient = 0.5;
    w.add_object(ball);

    const r = Ray.init(Tuple.point(0, 0, -3), Tuple.vector(0, -floats.sqrt2 / 2, floats.sqrt2 / 2));
    const xs = [_]Intersection{
        Intersection.init(floats.sqrt2, &floor),
    };
    const comps = xs[0].init_computations(r, &xs);
    const color = w.shade_hit(xs[0], comps, 5);
    try Color.expectEqual(Color.init(0.93642, 0.68642, 0.68642), color);
}

test "Shade hit with a reflective, transparent material" {
    var w = default(std.testing.allocator);
    defer w.deinit();

    var floor = Object.plane().with_transform(transformations.translation(0, -1, 0));
    floor.material.reflective = 0.5;
    floor.material.transparency = 0.5;
    floor.material.refractive_index = 1.5;
    w.add_object(floor);

    var ball = Object.sphere().with_transform(transformations.translation(0, -3.5, -0.5));
    ball.material.color = Color.init(1, 0, 0);
    ball.material.ambient = 0.5;
    w.add_object(ball);

    const r = Ray.init(Tuple.point(0, 0, -3), Tuple.vector(0, -floats.sqrt2 / 2, floats.sqrt2 / 2));
    const xs = [_]Intersection{
        Intersection.init(floats.sqrt2, &floor),
    };
    const comps = xs[0].init_computations(r, &xs);
    const color = w.shade_hit(xs[0], comps, 5);
    try Color.expectEqual(Color.init(0.93391, 0.69643, 0.69243), color);
}

/// Compute the color of a ray
pub fn color_at(self: World, r: Ray, depth: usize) Color {
    var buf = [_]Intersection{undefined} ** 100;
    const xs = intersect(self, r, &buf);
    if (xs.len == 0) return Color.BLACK;
    if (Intersection.hit(xs)) |hit| {
        const comps = hit.init_computations(r, xs);
        return shade_hit(self, hit, comps, depth);
    }
    return Color.BLACK;
}

test color_at {
    var w = default(std.testing.allocator);
    defer w.deinit();

    const r = Ray.init(Tuple.point(0, 0, -5), Tuple.vector(0, 0, 1));
    const c = color_at(w, r, 1);
    try Color.expectEqual(Color.init(0.38066, 0.47583, 0.2855), c);
}

test "The color when a ray misses" {
    var w = default(std.testing.allocator);
    defer w.deinit();

    const r = Ray.init(Tuple.point(0, 0, -5), Tuple.vector(0, 1, 0));
    const c = color_at(w, r, 1);
    try Color.expectEqual(Color.init(0, 0, 0), c);
}

test "The color with an intersection behind the ray" {
    var w = default(std.testing.allocator);
    defer w.deinit();
    w.objects.items[0].material.ambient = 1;
    w.objects.items[1].material.ambient = 1;

    const r = Ray.init(Tuple.point(0, 0, 0.75), Tuple.vector(0, 0, -1));
    const c = color_at(w, r, 1);
    try Color.expectEqual(w.objects.items[1].material.color, c);
}

fn is_shadowed(self: World, point: Tuple, light: PointLight) bool {
    var buf = [_]Intersection{undefined} ** 100;
    const v = light.position.sub(point);
    const distance = v.magnitude();
    const direction = v.normalize();
    const ray = Ray.init(point, direction);
    const xs = self.intersect(ray, &buf);
    if (Intersection.hit(xs)) |hit| {
        return hit.t < distance;
    }
    return false;
}

test "There is no shadow when nothing is collinear with point and light" {
    var w = default(std.testing.allocator);
    defer w.deinit();

    const p = Tuple.point(0, 10, 0);
    try std.testing.expectEqual(false, w.is_shadowed(p, w.lights.items[0]));
}

test "The shadow when an object is between the point and the light" {
    var w = default(std.testing.allocator);
    defer w.deinit();

    const p = Tuple.point(10, -10, 10);
    try std.testing.expectEqual(true, w.is_shadowed(p, w.lights.items[0]));
}

test "There is no shadow when an object is behind the light" {
    var w = default(std.testing.allocator);
    defer w.deinit();

    const p = Tuple.point(-20, 20, -20);
    try std.testing.expectEqual(false, w.is_shadowed(p, w.lights.items[0]));
}

test "There is no shadow when an object is behind the point" {
    var w = default(std.testing.allocator);
    defer w.deinit();

    const p = Tuple.point(-2, 2, -2);
    try std.testing.expectEqual(false, w.is_shadowed(p, w.lights.items[0]));
}

fn reflected_color(self: World, hit: Intersection, comps: Intersection.Computations, depth: usize) Color {
    if (depth == 0 or floats.equals(hit.object.material.reflective, 0)) return Color.BLACK;
    const reflect_ray = Ray.init(comps.over_point, comps.reflectv);
    const color = self.color_at(reflect_ray, depth - 1);
    return color.muls(hit.object.material.reflective);
}

test "The reflected color for a nonreflective material" {
    var world = default(std.testing.allocator);
    defer world.deinit();

    const r = Ray.init(Tuple.point(0, 0, 0), Tuple.vector(0, 0, 1));
    const shape = &world.objects.items[1];
    shape.material.ambient = 1;
    const i = Intersection.init(1, shape);
    const comps = i.init_computations(r, &[_]Intersection{i});
    const color = world.reflected_color(i, comps, 1);
    try Color.expectEqual(Color.BLACK, color);
}

test "The reflected color for a reflective material" {
    var world = default(std.testing.allocator);
    defer world.deinit();

    var shape = Object.plane().with_transform(transformations.translation(0, -1, 0));
    shape.material.reflective = 0.5;
    world.add_object(shape);

    const r = Ray.init(Tuple.point(0, 0, -3), Tuple.vector(0, -floats.sqrt2 / 2, floats.sqrt2 / 2));
    const i = Intersection.init(floats.sqrt2, &shape);
    const comps = i.init_computations(r, &[_]Intersection{i});
    const color = world.reflected_color(i, comps, 1);
    try Color.expectEqual(Color.init(0.19034, 0.23793, 0.14275), color);
}

test "The reflected color at maximum recursion depth" {
    var world = default(std.testing.allocator);
    defer world.deinit();

    var shape = Object.plane().with_transform(transformations.translation(0, -1, 0));
    shape.material.reflective = 0.5;
    world.add_object(shape);

    const r = Ray.init(Tuple.point(0, 0, -3), Tuple.vector(0, -floats.sqrt2 / 2, floats.sqrt2 / 2));
    const i = Intersection.init(floats.sqrt2, &shape);
    const comps = i.init_computations(r, &[_]Intersection{i});
    const color = world.reflected_color(i, comps, 0);
    try Color.expectEqual(Color.BLACK, color);
}

fn refracted_color(self: World, hit: Intersection, comps: Intersection.Computations, depth: usize) Color {
    if (depth == 0 or floats.equals(hit.object.material.transparency, 0)) {
        return Color.BLACK;
    }
    const n_ratio = comps.n1 / comps.n2;
    const cos_i = comps.eyev.dot(comps.normalv);
    const sin2_t = std.math.pow(Float, n_ratio, 2) * (1 - std.math.pow(Float, cos_i, 2));
    if (sin2_t > 1) {
        return Color.BLACK;
    }
    const cos_t = @sqrt(1 - sin2_t);
    const direction = comps.normalv.muls(n_ratio * cos_i - cos_t).sub(comps.eyev.muls(n_ratio));
    const refract_ray = Ray.init(comps.under_point, direction);
    return self.color_at(refract_ray, depth - 1).muls(hit.object.material.transparency);
}

test "The refracted color with an opaque surface" {
    var w = default(std.testing.allocator);
    defer w.deinit();

    const r = Ray.init(Tuple.point(0, 0, -5), Tuple.vector(0, 0, 1));
    const shape = &w.objects.items[0];
    const xs = [_]Intersection{ Intersection.init(4, shape), Intersection.init(6, shape) };
    const comps = xs[0].init_computations(r, &xs);
    const c = w.refracted_color(xs[0], comps, 5);
    try Color.expectEqual(Color.BLACK, c);
}

test "The refracted color at the maximum recursive depth" {
    var w = default(std.testing.allocator);
    defer w.deinit();

    const r = Ray.init(Tuple.point(0, 0, -5), Tuple.vector(0, 0, 1));
    const shape = &w.objects.items[0];
    shape.material.transparency = 1.0;
    shape.material.refractive_index = 1.5;
    const xs = [_]Intersection{ Intersection.init(4, shape), Intersection.init(6, shape) };
    const comps = xs[0].init_computations(r, &xs);
    const c = w.refracted_color(xs[0], comps, 0);
    try Color.expectEqual(Color.BLACK, c);
}

test "The refracted color under total internal reflection" {
    var w = default(std.testing.allocator);
    defer w.deinit();

    const r = Ray.init(Tuple.point(0, 0, floats.sqrt2 / 2), Tuple.vector(0, 1, 0));
    const shape = &w.objects.items[0];
    shape.material.transparency = 1.0;
    shape.material.refractive_index = 1.5;
    const xs = [_]Intersection{ Intersection.init(-floats.sqrt2 / 2, shape), Intersection.init(floats.sqrt2 / 2, shape) };
    const comps = xs[1].init_computations(r, &xs);
    const c = w.refracted_color(xs[1], comps, 5);
    try Color.expectEqual(Color.BLACK, c);
}

test "The refracted color with a refracted ray" {
    var w = default(std.testing.allocator);
    defer w.deinit();

    const a = &w.objects.items[0];
    a.material.ambient = 1.0;
    a.material.pattern = Pattern._test();
    const b = &w.objects.items[1];
    b.material.transparency = 1.0;
    b.material.refractive_index = 1.5;

    const r = Ray.init(Tuple.point(0, 0, 0.1), Tuple.vector(0, 1, 0));
    const xs = [_]Intersection{ Intersection.init(-0.9899, a), Intersection.init(-0.4899, b), Intersection.init(0.4899, b), Intersection.init(0.9899, a) };
    const comps = xs[2].init_computations(r, &xs);
    const c = w.refracted_color(xs[2], comps, 5);
    try Color.expectEqual(Color.init(0, 0.99878, 0.04725), c);
}
