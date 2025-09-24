const std = @import("std");
const floats = @import("floats.zig");
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

fn init(shape: Shape) Object {
    return Object{
        .material = Material.init(),
        .transform = Matrix.identity(),
        .shape = shape,
    };
}

pub fn sphere() Object {
    return init(Shape._sphere());
}

test "A object has a default transformation" {
    const s = Object.sphere();
    try Matrix.expectEqual(Matrix.identity(), s.transform);
}

test "Changing a object's transformation" {
    var s = Object.sphere();
    const t = transformations.translation(2, 3, 4);
    s.transform = t;
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
    const local_ray = ray.transform(self.transform.inverse());
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
    var s = Object.sphere();
    s.transform = transformations.scaling(2, 2, 2);

    var buf = [_]Intersection{undefined} ** 10;
    const xs = s.intersect(r, &buf);
    try std.testing.expectEqual(2, xs.len);
    try floats.expectEqual(3, xs[0].t);
    try floats.expectEqual(7, xs[1].t);
}

test "Intersecting a translated sphere with a ray" {
    const r = Ray.init(Tuple.point(0, 0, -5), Tuple.vector(0, 0, 1));
    var s = Object.sphere();
    s.transform = transformations.translation(5, 0, 0);

    var buf = [_]Intersection{undefined} ** 10;
    const xs = s.intersect(r, &buf);
    try std.testing.expectEqual(0, xs.len);
}

pub fn normal_at(self: Object, world_point: Tuple) Tuple {
    const local_point = self.transform.inverse().mult(world_point);
    const local_normal = self.shape.local_normal_at(local_point);
    var world_normal = self.transform.inverse().transpose().mult(local_normal);
    world_normal.to_vector();
    return world_normal.normalize();
}

test "The normal is a normalized vector" {
    const s = Object.sphere();
    const n = s.normal_at(Tuple.point(floats.sqrt3 / 3, floats.sqrt3 / 3, floats.sqrt3 / 3));
    try Tuple.expectEqual(n, n.normalize());
}

test "Computing the normal on a translated sphere" {
    var s = Object.sphere();
    s.transform = transformations.translation(0, 1, 0);
    const n = s.normal_at(Tuple.point(0, 1.70711, -0.70711));
    try Tuple.expectEqual(Tuple.vector(0, 0.70711, -0.70711), n);
}

test "Computing the normal on a transformed sphere" {
    var s = Object.sphere();
    s.transform = Matrix.mul(transformations.scaling(1, 0.5, 1), transformations.rotation_z(floats.pi / 5));
    const n = s.normal_at(Tuple.point(0, floats.sqrt2 / 2, -floats.sqrt2 / 2));
    try Tuple.expectEqual(Tuple.vector(0, 0.97014, -0.24254), n);
}
