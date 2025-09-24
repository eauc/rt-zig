const std = @import("std");
const Color = @import("Color.zig");
const Intersection = @import("Intersection.zig");
const PointLight = @import("Light.zig");
const Material = @import("Material.zig");
const Object = @import("Object.zig");
const Ray = @import("Ray.zig");
const transformations = @import("transformations.zig");
const Tuple = @import("Tuple.zig");
const World = @This();

allocator: std.mem.Allocator,
objects: std.ArrayList(Object),
lights: std.ArrayList(PointLight),

pub fn init(allocator: std.mem.Allocator) World {
    return World{
        .allocator = allocator,
        .objects = std.ArrayList(Object){},
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
    var s2 = Object.sphere();
    s2.transform = transformations.scaling(0.5, 0.5, 0.5);

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
    var s2 = Object.sphere();
    s2.transform = transformations.scaling(0.5, 0.5, 0.5);

    var w = default(allocator);
    defer w.deinit();

    try std.testing.expectEqual(light, w.lights.items[0]);
    try std.testing.expectEqual(s1, w.objects.items[0]);
    try std.testing.expectEqual(s2, w.objects.items[1]);
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
pub fn shade_hit(w: World, hit: Intersection, comps: Intersection.Computations) Color {
    const in_shadow = w.is_shadowed(comps.over_point);
    return hit.object.material.lighting(w.lights.items[0], comps.over_point, comps.eyev, comps.normalv, in_shadow);
}

test shade_hit {
    var w = default(std.testing.allocator);
    defer w.deinit();

    const r = Ray.init(Tuple.point(0, 0, -5), Tuple.vector(0, 0, 1));
    const shape = &w.objects.items[0];
    const i = Intersection.init(4, shape);
    const comps = i.prepare_computations(r);
    const c = shade_hit(w, i, comps);
    try Color.expectEqual(Color.init(0.38066, 0.47583, 0.2855), c);
}

test "Shading an intersection from the inside" {
    var w = default(std.testing.allocator);
    defer w.deinit();
    w.lights.items[0] = PointLight.init(Tuple.point(0, 0.25, 0), Color.WHITE);

    const r = Ray.init(Tuple.point(0, 0, 0), Tuple.vector(0, 0, 1));
    const shape = &w.objects.items[1];
    const i = Intersection.init(0.5, shape);
    const comps = i.prepare_computations(r);
    const c = shade_hit(w, i, comps);
    try Color.expectEqual(Color.init(0.90495, 0.90495, 0.90495), c);
}

test "Shading when the intersection is in shadow" {
    var w = default(std.testing.allocator);
    defer w.deinit();
    w.lights.items[0] = PointLight.init(Tuple.point(0, 0, -10), Color.WHITE);
    const s1 = Object.sphere();
    w.add_object(s1);
    var s2 = Object.sphere();
    s2.transform = transformations.translation(0, 0, 10);
    w.add_object(s2);

    const r = Ray.init(Tuple.point(0, 0, 5), Tuple.vector(0, 0, 1));
    const i = Intersection.init(4, &s2);
    const comps = i.prepare_computations(r);
    const c = shade_hit(w, i, comps);
    try Color.expectEqual(Color.init(0.1, 0.1, 0.1), c);
}

/// Compute the color of a ray
pub fn color_at(self: World, r: Ray) Color {
    var buf = [_]Intersection{undefined} ** 100;
    const xs = intersect(self, r, &buf);
    if (xs.len == 0) return Color.BLACK;
    if (Intersection.hit(xs)) |hit| {
        const comps = hit.prepare_computations(r);
        return shade_hit(self, hit, comps);
    }
    return Color.BLACK;
}

test color_at {
    var w = default(std.testing.allocator);
    defer w.deinit();

    const r = Ray.init(Tuple.point(0, 0, -5), Tuple.vector(0, 0, 1));
    const c = color_at(w, r);
    try Color.expectEqual(Color.init(0.38066, 0.47583, 0.2855), c);
}

test "The color when a ray misses" {
    var w = default(std.testing.allocator);
    defer w.deinit();

    const r = Ray.init(Tuple.point(0, 0, -5), Tuple.vector(0, 1, 0));
    const c = color_at(w, r);
    try Color.expectEqual(Color.init(0, 0, 0), c);
}

test "The color with an intersection behind the ray" {
    var w = default(std.testing.allocator);
    defer w.deinit();
    w.objects.items[0].material.ambient = 1;
    w.objects.items[1].material.ambient = 1;

    const r = Ray.init(Tuple.point(0, 0, 0.75), Tuple.vector(0, 0, -1));
    const c = color_at(w, r);
    try Color.expectEqual(w.objects.items[1].material.color, c);
}

fn is_shadowed(self: World, point: Tuple) bool {
    var buf = [_]Intersection{undefined} ** 100;
    const v = self.lights.items[0].position.sub(point);
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
    try std.testing.expectEqual(false, w.is_shadowed(p));
}

test "The shadow when an object is between the point and the light" {
    var w = default(std.testing.allocator);
    defer w.deinit();

    const p = Tuple.point(10, -10, 10);
    try std.testing.expectEqual(true, w.is_shadowed(p));
}

test "There is no shadow when an object is behind the light" {
    var w = default(std.testing.allocator);
    defer w.deinit();

    const p = Tuple.point(-20, 20, -20);
    try std.testing.expectEqual(false, w.is_shadowed(p));
}

test "There is no shadow when an object is behind the point" {
    var w = default(std.testing.allocator);
    defer w.deinit();

    const p = Tuple.point(-2, 2, -2);
    try std.testing.expectEqual(false, w.is_shadowed(p));
}
