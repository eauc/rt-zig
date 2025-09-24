const std = @import("std");
const colors = @import("colors.zig");
const intersections = @import("intersections.zig");
const Intersection = intersections.Intersection;
const lights = @import("lights.zig");
const materials = @import("materials.zig");
const PointLight = lights.PointLight;
const rays = @import("rays.zig");
const Ray = rays.Ray;
const spheres = @import("spheres.zig");
const Sphere = spheres.Sphere;
const transformations = @import("transformations.zig");
const tuples = @import("tuples.zig");

pub const World = struct {
    allocator: std.mem.Allocator,
    objects: std.ArrayList(Sphere),
    lights: std.ArrayList(PointLight),
};

pub fn world(allocator: std.mem.Allocator) World {
    return World{
        .allocator = allocator,
        .objects = std.ArrayList(Sphere){},
        .lights = std.ArrayList(PointLight){},
    };
}

pub fn deinit(w: *World) void {
    w.objects.deinit(w.allocator);
    w.lights.deinit(w.allocator);
}

pub fn add_object(w: *World, s: Sphere) void {
    w.objects.append(w.allocator, s) catch unreachable;
}

pub fn add_light(w: *World, l: PointLight) void {
    w.lights.append(w.allocator, l) catch unreachable;
}

test "Creating a world" {
    const allocator = std.testing.allocator;

    var w = world(allocator);
    defer deinit(&w);

    try std.testing.expectEqual(0, w.objects.items.len);
    try std.testing.expectEqual(0, w.lights.items.len);
}

pub fn default_world(allocator: std.mem.Allocator) World {
    var w = world(allocator);

    const light = lights.point_light(tuples.point(-10, 10, -10), colors.WHITE);
    var s1 = spheres.sphere();
    s1.material.color = colors.color(0.8, 1.0, 0.6);
    s1.material.diffuse = 0.7;
    s1.material.specular = 0.2;
    var s2 = spheres.sphere();
    s2.transform = transformations.scaling(0.5, 0.5, 0.5);

    add_object(&w, s1);
    add_object(&w, s2);
    add_light(&w, light);

    return w;
}

test default_world {
    const allocator = std.testing.allocator;

    const light = lights.point_light(tuples.point(-10, 10, -10), colors.WHITE);
    var s1 = spheres.sphere();
    s1.material.color = colors.color(0.8, 1.0, 0.6);
    s1.material.diffuse = 0.7;
    s1.material.specular = 0.2;
    var s2 = spheres.sphere();
    s2.transform = transformations.scaling(0.5, 0.5, 0.5);

    var w = default_world(allocator);
    defer deinit(&w);

    try std.testing.expectEqual(light, w.lights.items[0]);
    try std.testing.expectEqual(s1, w.objects.items[0]);
    try std.testing.expectEqual(s2, w.objects.items[1]);
}

pub fn intersect(w: World, r: Ray, buf: []Intersection) []Intersection {
    var count: usize = 0;
    for (w.objects.items) |*object| {
        const xs = spheres.intersect(object, r, buf[count..]);
        count += xs.len;
    }
    intersections.sort(buf[0..count]);
    return buf[0..count];
}

test intersect {
    const allocator = std.testing.allocator;
    var w = default_world(allocator);
    defer deinit(&w);

    const r = rays.ray(tuples.point(0, 0, -5), tuples.vector(0, 0, 1));
    var buf = [_]Intersection{undefined} ** 10;
    const xs = intersect(w, r, &buf);

    try std.testing.expectEqual(4, xs.len);
    try std.testing.expectEqual(4.0, xs[0].t);
    try std.testing.expectEqual(4.5, xs[1].t);
    try std.testing.expectEqual(5.5, xs[2].t);
    try std.testing.expectEqual(6.0, xs[3].t);
}

/// Shade an intersection
pub fn shade_hit(w: World, hit: Intersection, comps: intersections.Computations) colors.Color {
    return materials.lighting(hit.object.material, w.lights.items[0], comps.point, comps.eyev, comps.normalv);
}

test shade_hit {
    var w = default_world(std.testing.allocator);
    defer deinit(&w);

    const r = rays.ray(tuples.point(0, 0, -5), tuples.vector(0, 0, 1));
    const shape = &w.objects.items[0];
    const i = intersections.intersection(4, shape);
    const comps = intersections.prepare_computations(i, r);
    const c = shade_hit(w, i, comps);
    try colors.expectEqual(colors.color(0.38066, 0.47583, 0.2855), c);
}

test "Shading an intersection from the inside" {
    var w = default_world(std.testing.allocator);
    defer deinit(&w);
    w.lights.items[0] = lights.point_light(tuples.point(0, 0.25, 0), colors.WHITE);

    const r = rays.ray(tuples.point(0, 0, 0), tuples.vector(0, 0, 1));
    const shape = &w.objects.items[1];
    const i = intersections.intersection(0.5, shape);
    const comps = intersections.prepare_computations(i, r);
    const c = shade_hit(w, i, comps);
    try colors.expectEqual(colors.color(0.90498, 0.90498, 0.90498), c);
}

/// Compute the color of a ray
pub fn color_at(w: World, r: Ray) colors.Color {
    var buf = [_]Intersection{undefined} ** 100;
    const xs = intersect(w, r, &buf);
    if (intersections.hit(xs)) |hit| {
        const comps = intersections.prepare_computations(hit, r);
        return shade_hit(w, hit, comps);
    }
    return colors.BLACK;
}

test color_at {
    var w = default_world(std.testing.allocator);
    defer deinit(&w);

    const r = rays.ray(tuples.point(0, 0, -5), tuples.vector(0, 0, 1));
    const c = color_at(w, r);
    try colors.expectEqual(colors.color(0.38066, 0.47583, 0.2855), c);
}

test "The color when a ray misses" {
    var w = default_world(std.testing.allocator);
    defer deinit(&w);

    const r = rays.ray(tuples.point(0, 0, -5), tuples.vector(0, 1, 0));
    const c = color_at(w, r);
    try colors.expectEqual(colors.color(0, 0, 0), c);
}

test "The color with an intersection behind the ray" {
    var w = default_world(std.testing.allocator);
    defer deinit(&w);
    w.objects.items[0].material.ambient = 1;
    w.objects.items[1].material.ambient = 1;

    const r = rays.ray(tuples.point(0, 0, 0.75), tuples.vector(0, 0, -1));
    const c = color_at(w, r);
    try colors.expectEqual(w.objects.items[1].material.color, c);
}
