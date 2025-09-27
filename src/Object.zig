const std = @import("std");
const floats = @import("floats.zig");
const Float = floats.Float;
const Intersection = @import("Intersection.zig");
const Material = @import("Material.zig");
const Matrix = @import("Matrix.zig");
const Object = @This();
const Ray = @import("Ray.zig");
const Shape = @import("shapes.zig").Shape;
const transformations = @import("transformations.zig");
const Tuple = @import("Tuple.zig");

material: Material,
shape: Shape,
transform: Matrix,
transform_inverse: Matrix,
transform_inverse_transpose: Matrix,

fn init(shape: Shape) Object {
    return Object{
        .material = Material.init(),
        .transform = Matrix.identity(),
        .transform_inverse = Matrix.identity(),
        .transform_inverse_transpose = Matrix.identity(),
        .shape = shape,
    };
}

pub fn cylinder() Object {
    return init(Shape._cylinder());
}
pub fn cube() Object {
    return init(Shape._cube());
}
pub fn plane() Object {
    return init(Shape._plane());
}
pub fn sphere() Object {
    return init(Shape._sphere());
}

pub fn made_of_glass(self: Object) Object {
    return Object{
        .material = Material.glass(),
        .shape = self.shape,
        .transform = self.transform,
        .transform_inverse = self.transform_inverse,
        .transform_inverse_transpose = self.transform_inverse_transpose,
    };
}

pub fn truncate(self: Object, minimum: Float, maximum: Float, is_closed: bool) Object {
    return Object{
        .material = self.material,
        .shape = self.shape.truncate(minimum, maximum, is_closed),
        .transform = self.transform,
        .transform_inverse = self.transform_inverse,
        .transform_inverse_transpose = self.transform_inverse_transpose,
    };
}

pub fn with_transform(self: Object, transform: Matrix) Object {
    const transform_inverse = transform.inverse();
    return Object{
        .material = self.material,
        .shape = self.shape,
        .transform = transform,
        .transform_inverse = transform_inverse,
        .transform_inverse_transpose = transform_inverse.transpose(),
    };
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

pub fn normal_at(self: Object, world_point: Tuple) Tuple {
    const local_point = self.transform_inverse.mult(world_point);
    const local_normal = self.shape.local_normal_at(local_point);
    var world_normal = self.transform_inverse_transpose.mult(local_normal);
    world_normal.to_vector();
    return world_normal.normalize();
}

test "The normal is a normalized vector" {
    const s = Object.sphere();
    const n = s.normal_at(Tuple.point(floats.sqrt3 / 3, floats.sqrt3 / 3, floats.sqrt3 / 3));
    try Tuple.expectEqual(n, n.normalize());
}

test "Computing the normal on a translated sphere" {
    var s = Object.sphere().with_transform(transformations.translation(0, 1, 0));
    const n = s.normal_at(Tuple.point(0, 1.70711, -0.70711));
    try Tuple.expectEqual(Tuple.vector(0, 0.70711, -0.70711), n);
}

test "Computing the normal on a transformed sphere" {
    var s = Object.sphere().with_transform(transformations.scaling(1, 0.5, 1).mul(transformations.rotation_z(floats.pi / 5)));
    const n = s.normal_at(Tuple.point(0, floats.sqrt2 / 2, -floats.sqrt2 / 2));
    try Tuple.expectEqual(Tuple.vector(0, 0.97014, -0.24254), n);
}
