const std = @import("std");
const BoundingBox = @import("BoundingBox.zig");
const floats = @import("floats.zig");
const Float = floats.Float;
const Intersection = @import("Intersection.zig");
const Material = @import("Material.zig");
const Matrix = @import("Matrix.zig");
const Object = @This();
const Ray = @import("Ray.zig");
const shapes = @import("shapes.zig");
const Shape = shapes.Shape;
const transformations = @import("transformations.zig");
const Tuple = @import("Tuple.zig");

material: Material,
shape: Shape,
bounding_box: BoundingBox,
transform: Matrix,
transform_inverse: Matrix,
world_to_object: Matrix,
object_to_world: Matrix,

fn init(shape: Shape) Object {
    return Object{
        .material = Material.init(),
        .shape = shape,
        .bounding_box = BoundingBox.default(),
        .transform = Matrix.identity(),
        .transform_inverse = Matrix.identity(),
        .world_to_object = Matrix.identity(),
        .object_to_world = Matrix.identity(),
    };
}

pub fn deinit(self: *Object) void {
    self.shape.deinit();
}

pub fn cone() Object {
    return init(Shape._cone());
}
pub fn cube() Object {
    return init(Shape._cube());
}
pub fn cylinder() Object {
    return init(Shape._cylinder());
}
pub fn group(allocator: std.mem.Allocator) Object {
    return init(Shape._group(allocator));
}
pub fn plane() Object {
    return init(Shape._plane());
}
pub fn smooth_triangle(p1: Tuple, p2: Tuple, p3: Tuple, n1: Tuple, n2: Tuple, n3: Tuple) Object {
    return init(Shape._smooth_triangle(p1, p2, p3, n1, n2, n3));
}
pub fn sphere() Object {
    return init(Shape._sphere());
}
pub fn triangle(p1: Tuple, p2: Tuple, p3: Tuple) Object {
    return init(Shape._triangle(p1, p2, p3));
}

pub fn as_group(self: *Object) *shapes.Group {
    return &self.shape.group;
}
pub fn as_smooth_triangle(self: *Object) *shapes.SmoothTriangle {
    return &self.shape.smooth_triangle;
}
pub fn as_triangle(self: *Object) *shapes.Triangle {
    return &self.shape.triangle;
}

pub fn made_of_glass(self: Object) Object {
    return Object{
        .material = Material.glass(),
        .shape = self.shape,
        .bounding_box = self.bounding_box,
        .transform = self.transform,
        .transform_inverse = self.transform_inverse,
        .world_to_object = self.world_to_object,
        .object_to_world = self.object_to_world,
    };
}

pub fn truncate(self: Object, minimum: Float, maximum: Float, is_closed: bool) Object {
    return Object{
        .material = self.material,
        .shape = self.shape.truncate(minimum, maximum, is_closed),
        .bounding_box = self.bounding_box,
        .transform = self.transform,
        .transform_inverse = self.transform_inverse,
        .world_to_object = self.world_to_object,
        .object_to_world = self.object_to_world,
    };
}

pub fn with_transform(self: Object, transform: Matrix) Object {
    const transform_inverse = transform.inverse();
    return Object{
        .material = self.material,
        .shape = self.shape,
        .bounding_box = self.bounding_box,
        .transform = transform,
        .transform_inverse = transform_inverse,
        .world_to_object = transform_inverse,
        .object_to_world = transform_inverse.transpose(),
    };
}

pub fn prepare(self: *Object) void {
    self.prepare_bounding_box();
    self.prepare_transform();
}

pub fn prepare_bounding_box(self: *Object) void {
    self.bounding_box = self.shape.prepare_bounding_box();
}

pub fn prepare_transform(self: *Object) void {
    self.shape.prepare_transform(self.world_to_object, self.object_to_world);
}

test "A object has a default transformation" {
    const s = Object.sphere();
    try Matrix.expectEqual(Matrix.identity(), s.transform);
}

test "Changing a object's transformation" {
    const t = transformations.translation(2, 3, 4);
    const s = Object.sphere().with_transform(t);
    try Matrix.expectEqual(t, s.transform);
}

test "A object has a default material" {
    const s = Object.sphere();
    try std.testing.expectEqual(Material.init(), s.material);
}

test "A object may be assigned a material" {
    var s = Object.sphere();
    var m = Material.init();
    m.ambient = 1;
    s.material = m;
    try std.testing.expectEqual(m, s.material);
}

pub fn intersect(self: *const Object, ray: Ray, buf: []Intersection) []Intersection {
    const local_ray = ray.transform(self.transform_inverse);
    return self.shape.local_intersect(local_ray, self, buf);
}

test "Intersect sets the object on the intersection" {
    const r = Ray.init(Tuple.point(0, 0, -5), Tuple.vector(0, 0, 1));
    const s = Object.sphere();

    var buf = [_]Intersection{undefined} ** 10;
    const xs = s.intersect(r, &buf);
    try std.testing.expectEqual(2, xs.len);
    try std.testing.expectEqual(&s, xs[0].object);
    try std.testing.expectEqual(&s, xs[1].object);
}

test "Intersecting a scaled sphere with a ray" {
    const r = Ray.init(Tuple.point(0, 0, -5), Tuple.vector(0, 0, 1));
    var s = Object.sphere().with_transform(transformations.scaling(2, 2, 2));

    var buf = [_]Intersection{undefined} ** 10;
    const xs = s.intersect(r, &buf);
    try std.testing.expectEqual(2, xs.len);
    try floats.expectEqual(3, xs[0].t);
    try floats.expectEqual(7, xs[1].t);
}

test "Intersecting a translated sphere with a ray" {
    const r = Ray.init(Tuple.point(0, 0, -5), Tuple.vector(0, 0, 1));
    var s = Object.sphere().with_transform(transformations.translation(5, 0, 0));

    var buf = [_]Intersection{undefined} ** 10;
    const xs = s.intersect(r, &buf);
    try std.testing.expectEqual(0, xs.len);
}

pub fn normal_at(self: Object, world_point: Tuple, hit: Intersection) Tuple {
    const local_point = self.world_to_object.mult(world_point);
    const local_normal = self.shape.local_normal_at(local_point, hit);
    var world_normal = self.object_to_world.mult(local_normal);
    world_normal.to_vector();
    return world_normal.normalize();
}

test "The normal is a normalized vector" {
    const s = Object.sphere();
    const n = s.normal_at(Tuple.point(floats.sqrt3 / 3, floats.sqrt3 / 3, floats.sqrt3 / 3), Intersection.init(0, &s));
    try Tuple.expectEqual(n, n.normalize());
}

test "Computing the normal on a translated sphere" {
    var s = Object.sphere().with_transform(transformations.translation(0, 1, 0));
    const n = s.normal_at(Tuple.point(0, 1.70711, -0.70711), Intersection.init(0, &s));
    try Tuple.expectEqual(Tuple.vector(0, 0.70711, -0.70711), n);
}

test "Computing the normal on a transformed sphere" {
    var s = Object.sphere().with_transform(transformations.scaling(1, 0.5, 1).mul(transformations.rotation_z(floats.pi / 5)));
    const n = s.normal_at(Tuple.point(0, floats.sqrt2 / 2, -floats.sqrt2 / 2), Intersection.init(0, &s));
    try Tuple.expectEqual(Tuple.vector(0, 0.97014, -0.24254), n);
}

test "Converting a point from world to object space" {
    const allocator = std.testing.allocator;

    var g2 = Object.group(allocator).with_transform(transformations.scaling(2, 2, 2));
    const s = g2.as_group().add_child(Object.sphere().with_transform(transformations.translation(5, 0, 0)));

    var g1 = Object.group(allocator).with_transform(transformations.rotation_y(std.math.pi / 2.0));
    defer g1.as_group().deinit();
    _ = g1.as_group().add_child(g2);

    g1.prepare();
    const p = s.world_to_object.mult(Tuple.point(-2, 0, -10));
    try Tuple.expectEqual(Tuple.point(0, 0, -1), p);
}

test "Converting a normal from object to world space" {
    const allocator = std.testing.allocator;

    var g2 = Object.group(allocator).with_transform(transformations.scaling(1, 2, 3));
    const s = g2.as_group().add_child(Object.sphere().with_transform(transformations.translation(5, 0, 0)));

    var g1 = Object.group(allocator).with_transform(transformations.rotation_y(std.math.pi / 2.0));
    defer g1.as_group().deinit();
    _ = g1.as_group().add_child(g2);

    g1.prepare();
    var n = s.object_to_world.mult(Tuple.vector(floats.sqrt3 / 3, floats.sqrt3 / 3, floats.sqrt3 / 3));
    n.to_vector();
    try Tuple.expectEqual(Tuple.vector(0.28571, 0.42857, -0.85714), n.normalize());
}

test "Finding the normal on a child object" {
    const allocator = std.testing.allocator;

    var g2 = Object.group(allocator).with_transform(transformations.scaling(1, 2, 3));
    var s = g2.as_group().add_child(Object.sphere().with_transform(transformations.translation(5, 0, 0)));

    var g1 = Object.group(allocator).with_transform(transformations.rotation_y(std.math.pi / 2.0));
    defer g1.as_group().deinit();
    _ = g1.as_group().add_child(g2);

    g1.prepare();
    const n = s.normal_at(Tuple.point(1.7321, 1.1547, -5.5774), Intersection.init(0, s));
    try Tuple.expectEqual(Tuple.vector(0.2857, 0.42854, -0.85716), n);
}
