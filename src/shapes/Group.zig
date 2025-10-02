const std = @import("std");
const BoundingBox = @import("../BoundingBox.zig");
const Group = @This();
const Intersection = @import("../Intersection.zig");
const Matrix = @import("../Matrix.zig");
const Object = @import("../Object.zig");
const Ray = @import("../Ray.zig");
const Shape = @import("../shapes.zig").Shape;
const transformations = @import("../transformations.zig");
const Tuple = @import("../Tuple.zig");

allocator: std.mem.Allocator,
children: std.ArrayList(Object),

pub fn init(allocator: std.mem.Allocator) Group {
    return Group{
        .allocator = allocator,
        .children = std.ArrayList(Object){},
    };
}

pub fn deinit(self: *Group) void {
    for (self.children.items) |*child| {
        child.deinit();
    }
    self.children.deinit(self.allocator);
}

pub fn is_empty(self: Group) bool {
    return self.children.items.len == 0;
}

test "Creating a new group" {
    const allocator = std.testing.allocator;
    var g = Object.group(allocator);
    defer g.as_group().deinit();

    try std.testing.expect(g.as_group().is_empty());
}

pub fn add_child(self: *Group, new_child: Object) *Object {
    self.children.append(self.allocator, new_child) catch unreachable;
    return &self.children.items[self.children.items.len - 1];
}

test "Adding a child to a group" {
    const allocator = std.testing.allocator;
    var g = Object.group(allocator);
    defer g.as_group().deinit();

    const s = Object.sphere();
    _ = g.as_group().add_child(s);

    try std.testing.expect(!g.as_group().is_empty());
}

pub fn prepare_transform(self: *Group, world_to_object: Matrix, object_to_world: Matrix) void {
    for (self.children.items) |*child| {
        child.world_to_object = child.transform_inverse.mul(world_to_object);
        child.object_to_world = object_to_world.mul(child.transform_inverse.transpose());
        child.prepare_transform();
    }
}

pub fn prepare_bounding_box(self: *Group) BoundingBox {
    var box = BoundingBox.infinite();
    for (self.children.items) |*child| {
        child.prepare_bounding_box();
        box = box.merge(child.bounding_box.transform(child.transform));
    }
    return box;
}

pub fn local_intersect(self: Group, ray: Ray, object: *const Object, buf: []Intersection) []Intersection {
    if (!object.bounding_box.intersect(ray)) {
        return buf[0..0];
    }
    var count: usize = 0;
    for (self.children.items) |*child| {
        const xs = child.intersect(ray, buf[count..]);
        count += xs.len;
    }
    Intersection.sort(buf[0..count]);
    return buf[0..count];
}

test "Intersecting a ray with an empty group" {
    const allocator = std.testing.allocator;
    var g = Object.group(allocator);
    defer g.as_group().deinit();

    g.prepare();
    const r = Ray.init(Tuple.point(0, 0, 0), Tuple.vector(0, 0, 1));

    var buf = [_]Intersection{undefined} ** 10;
    const xs = g.intersect(r, &buf);
    try std.testing.expectEqual(0, xs.len);
}

test "Intersecting a ray with a nonempty group" {
    const allocator = std.testing.allocator;
    var g = Object.group(allocator);
    defer g.as_group().deinit();

    const s1 = Object.sphere();
    const s2 = Object.sphere().with_transform(transformations.translation(0, 0, -3));
    const s3 = Object.sphere().with_transform(transformations.translation(5, 0, 0));
    _ = g.as_group().add_child(s1);
    _ = g.as_group().add_child(s2);
    _ = g.as_group().add_child(s3);

    g.prepare();
    const r = Ray.init(Tuple.point(0, 0, -5), Tuple.vector(0, 0, 1));

    var buf = [_]Intersection{undefined} ** 10;
    const xs = g.intersect(r, &buf);
    try std.testing.expectEqual(4, xs.len);
    try std.testing.expectEqual(&g.as_group().children.items[1], xs[0].object);
    try std.testing.expectEqual(&g.as_group().children.items[1], xs[1].object);
    try std.testing.expectEqual(&g.as_group().children.items[0], xs[2].object);
    try std.testing.expectEqual(&g.as_group().children.items[0], xs[3].object);
}

test "Intersecting a transformed group" {
    const allocator = std.testing.allocator;
    var g = Object.group(allocator).with_transform(transformations.scaling(2, 2, 2));
    defer g.as_group().deinit();

    const s = Object.sphere().with_transform(transformations.translation(5, 0, 0));
    _ = g.as_group().add_child(s);

    g.prepare();
    const r = Ray.init(Tuple.point(10, 0, -10), Tuple.vector(0, 0, 1));

    var buf = [_]Intersection{undefined} ** 10;
    const xs = g.intersect(r, &buf);
    try std.testing.expectEqual(2, xs.len);
}

pub fn local_normal_at(_: Group, _: Tuple) Tuple {
    @panic("We should never call local_normal_at on a Group");
}
