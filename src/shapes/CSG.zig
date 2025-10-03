const std = @import("std");
const CSG = @This();
const Intersection = @import("../Intersection.zig");
const Object = @import("../Object.zig");
const Ray = @import("../Ray.zig");
const transformations = @import("../transformations.zig");
const Tuple = @import("../Tuple.zig");

pub const Operation = enum {
    _union,
    _intersection,
    _difference,
};

allocator: std.mem.Allocator,
operation: Operation,
left: *Object,
right: *Object,

pub fn init(allocator: std.mem.Allocator, op: Operation, l: Object, r: Object) CSG {
    const left = allocator.create(Object) catch unreachable;
    const right = allocator.create(Object) catch unreachable;

    left.* = l;
    right.* = r;

    return CSG{
        .allocator = allocator,
        .operation = op,
        .left = left,
        .right = right,
    };
}

pub fn deinit(self: *CSG) void {
    self.left.deinit();
    self.allocator.destroy(self.left);
    self.right.deinit();
    self.allocator.destroy(self.right);
}

pub fn includes(self: *const CSG, other: *const Object) bool {
    return self.left.includes(other) or self.right.includes(other);
}

test "csg is created with an operation and two shapes" {
    const allocator = std.testing.allocator;

    const s1 = Object.sphere();
    const s2 = Object.cube();
    var c = init(allocator, ._union, s1, s2);
    defer c.deinit();

    try std.testing.expectEqual(._union, c.operation);
    try std.testing.expectEqual(s1, c.left.*);
    try std.testing.expectEqual(s2, c.right.*);
}

fn intersection_allowed(op: Operation, lhit: bool, inl: bool, inr: bool) bool {
    return switch (op) {
        ._union => (lhit and !inr) or (!lhit and !inl),
        ._intersection => (lhit and inr) or (!lhit and inl),
        ._difference => (lhit and !inr) or (!lhit and inl),
    };
}

test "Evaluating the rule for a CSG operation" {
    for ([_]struct {
        op: Operation,
        lhit: bool,
        inl: bool,
        inr: bool,
        result: bool,
    }{
        .{ .op = ._union, .lhit = true, .inl = true, .inr = true, .result = false },
        .{ .op = ._union, .lhit = true, .inl = true, .inr = false, .result = true },
        .{ .op = ._union, .lhit = true, .inl = false, .inr = true, .result = false },
        .{ .op = ._union, .lhit = true, .inl = false, .inr = false, .result = true },
        .{ .op = ._union, .lhit = false, .inl = true, .inr = true, .result = false },
        .{ .op = ._union, .lhit = false, .inl = true, .inr = false, .result = false },
        .{ .op = ._union, .lhit = false, .inl = false, .inr = true, .result = true },
        .{ .op = ._union, .lhit = false, .inl = false, .inr = false, .result = true },
        .{ .op = ._intersection, .lhit = true, .inl = true, .inr = true, .result = true },
        .{ .op = ._intersection, .lhit = true, .inl = true, .inr = false, .result = false },
        .{ .op = ._intersection, .lhit = true, .inl = false, .inr = true, .result = true },
        .{ .op = ._intersection, .lhit = true, .inl = false, .inr = false, .result = false },
        .{ .op = ._intersection, .lhit = false, .inl = true, .inr = true, .result = true },
        .{ .op = ._intersection, .lhit = false, .inl = true, .inr = false, .result = true },
        .{ .op = ._intersection, .lhit = false, .inl = false, .inr = true, .result = false },
        .{ .op = ._intersection, .lhit = false, .inl = false, .inr = false, .result = false },
        .{ .op = ._difference, .lhit = true, .inl = true, .inr = true, .result = false },
        .{ .op = ._difference, .lhit = true, .inl = true, .inr = false, .result = true },
        .{ .op = ._difference, .lhit = true, .inl = false, .inr = true, .result = false },
        .{ .op = ._difference, .lhit = true, .inl = false, .inr = false, .result = true },
        .{ .op = ._difference, .lhit = false, .inl = true, .inr = true, .result = true },
        .{ .op = ._difference, .lhit = false, .inl = true, .inr = false, .result = true },
        .{ .op = ._difference, .lhit = false, .inl = false, .inr = true, .result = false },
        .{ .op = ._difference, .lhit = false, .inl = false, .inr = false, .result = false },
    }) |example| {
        try std.testing.expectEqual(
            example.result,
            intersection_allowed(example.op, example.lhit, example.inl, example.inr),
        );
    }
}

fn filter_intersections(c: CSG, xs: []Intersection) []Intersection {
    var inl = false;
    var inr = false;
    var result_count: usize = 0;
    for (xs) |x| {
        const lhit = c.left.includes(x.object);
        if (intersection_allowed(c.operation, lhit, inl, inr)) {
            xs[result_count] = x;
            result_count += 1;
        }
        if (lhit) {
            inl = !inl;
        } else {
            inr = !inr;
        }
    }
    return xs[0..result_count];
}

test "Filtering a list of intersections" {
    const allocator = std.testing.allocator;

    const s1 = Object.sphere();
    const s2 = Object.cube();

    for ([_]struct { op: Operation, x0: usize, x1: usize }{
        .{ .op = ._union, .x0 = 0, .x1 = 3 },
        .{ .op = ._intersection, .x0 = 1, .x1 = 2 },
        .{ .op = ._difference, .x0 = 0, .x1 = 1 },
    }) |example| {
        var c = init(allocator, example.op, s1, s2);
        defer c.deinit();

        const xs = [_]Intersection{
            Intersection.init(1, c.left),
            Intersection.init(2, c.right),
            Intersection.init(3, c.left),
            Intersection.init(4, c.right),
        };
        var buf = xs;
        const result = c.filter_intersections(&buf);

        try std.testing.expectEqual(2, result.len);
        try std.testing.expectEqual(xs[example.x0], result[0]);
        try std.testing.expectEqual(xs[example.x1], result[1]);
    }
}

pub fn local_intersect(self: CSG, ray: Ray, _: *const Object, buf: []Intersection) []Intersection {
    const left_xs = self.left.intersect(ray, buf);
    const right_xs = self.right.intersect(ray, buf[left_xs.len..]);
    const xs = buf[0 .. left_xs.len + right_xs.len];
    Intersection.sort(xs);
    return self.filter_intersections(xs);
}

test "A ray misses a CSG object" {
    const allocator = std.testing.allocator;

    var c = Object.csg(allocator, ._union, Object.sphere(), Object.cube());
    defer c.deinit();

    const r = Ray.init(Tuple.point(0, 2, -5), Tuple.vector(0, 0, 1));
    var buf = [_]Intersection{undefined} ** 10;
    const xs = c.intersect(r, &buf);

    try std.testing.expectEqual(0, xs.len);
}

test "A ray hits a CSG object" {
    const allocator = std.testing.allocator;

    const s1 = Object.sphere();
    const s2 = Object.sphere().with_transform(transformations.translation(0, 0, 0.5));

    var c = Object.csg(allocator, ._union, s1, s2);
    defer c.deinit();

    const r = Ray.init(Tuple.point(0, 0, -5), Tuple.vector(0, 0, 1));

    var buf = [_]Intersection{undefined} ** 10;
    const xs = c.intersect(r, &buf);

    try std.testing.expectEqual(2, xs.len);
    try std.testing.expectEqual(4, xs[0].t);
    try std.testing.expectEqual(c.as_csg().left, xs[0].object);
    try std.testing.expectEqual(6.5, xs[1].t);
    try std.testing.expectEqual(c.as_csg().right, xs[1].object);
}

pub fn local_normal_at(_: CSG, _: Tuple) Tuple {
    @panic("We should never call local_normal_at on a CSG");
}
