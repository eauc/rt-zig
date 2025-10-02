const std = @import("std");
const floats = @import("floats.zig");
const Float = floats.Float;
const Object = @import("Object.zig");
const ObjFile = @This();
const Tuple = @import("Tuple.zig");

allocator: std.mem.Allocator,
vertices: []Tuple,
default_group: Object,

pub fn deinit(self: *ObjFile) void {
    self.allocator.free(self.vertices);
    self.default_group.as_group().deinit();
}

pub fn parse_string(allocator: std.mem.Allocator, input: []const u8) error{ InvalidCharacter, Overflow }!ObjFile {
    var vertices = std.ArrayList(Tuple){};
    errdefer vertices.deinit(allocator);
    var default_group = Object.group(allocator);
    errdefer default_group.as_group().deinit();
    var current_group = &default_group;

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var words = std.mem.splitScalar(u8, line, ' ');
        if (words.next()) |cmd| {
            if (std.mem.eql(u8, cmd, "f")) {
                var indices = std.ArrayList(usize){};
                defer indices.deinit(allocator);

                while (words.next()) |index_str| {
                    const index = try std.fmt.parseInt(usize, index_str, 10);
                    indices.append(allocator, index) catch unreachable;
                }

                var triangles = fan_triangulation(allocator, vertices, indices);
                defer triangles.deinit(allocator);

                for (triangles.items) |t| {
                    _ = current_group.as_group().add_child(t);
                }
            }
            if (std.mem.eql(u8, cmd, "g")) {
                current_group = default_group.as_group().add_child(Object.group(allocator));
            }
            if (std.mem.eql(u8, cmd, "v")) {
                const x = try std.fmt.parseFloat(Float, words.next().?);
                const y = try std.fmt.parseFloat(Float, words.next().?);
                const z = try std.fmt.parseFloat(Float, words.next().?);

                vertices.append(allocator, Tuple.point(x, y, z)) catch unreachable;
            }
        }
    }
    return ObjFile{
        .allocator = allocator,
        .vertices = vertices.toOwnedSlice(allocator) catch unreachable,
        .default_group = default_group,
    };
}

fn fan_triangulation(allocator: std.mem.Allocator, vertices: std.ArrayList(Tuple), indices: std.ArrayList(usize)) std.ArrayList(Object) {
    var triangles = std.ArrayList(Object){};
    const p1 = vertices.items[indices.items[0] - 1];
    for (1..indices.items.len - 1) |i| {
        const p2 = vertices.items[indices.items[i] - 1];
        const p3 = vertices.items[indices.items[i + 1] - 1];
        triangles.append(allocator, Object.triangle(p1, p2, p3)) catch unreachable;
    }
    return triangles;
}

test "Ignoring unrecognized lines" {
    const allocator = std.testing.allocator;

    const input =
        \\There was a young lady named Bright
        \\who traveled much faster than light.
        \\She set out one day
        \\in a relative way,
        \\and came back the previous night.
    ;
    var obj_file = try parse_string(allocator, input);
    defer obj_file.deinit();

    try std.testing.expectEqual(0, obj_file.vertices.len);
}

test "Vertex records" {
    const allocator = std.testing.allocator;

    const input =
        \\v -1 1 0
        \\v -1.0000 0.5000 0.0000
        \\v 1 0 0
        \\v 1 1 0
    ;
    var obj_file = try parse_string(allocator, input);
    defer obj_file.deinit();

    try std.testing.expectEqual(4, obj_file.vertices.len);
    try Tuple.expectEqual(obj_file.vertices[0], Tuple.point(-1, 1, 0));
    try Tuple.expectEqual(obj_file.vertices[1], Tuple.point(-1, 0.5, 0));
    try Tuple.expectEqual(obj_file.vertices[2], Tuple.point(1, 0, 0));
    try Tuple.expectEqual(obj_file.vertices[3], Tuple.point(1, 1, 0));
}

test "Parsing triangle faces" {
    const allocator = std.testing.allocator;

    const input =
        \\v -1 1 0
        \\v -1 0 0
        \\v 1 0 0
        \\v 1 1 0
        \\f 1 2 3
        \\f 1 3 4
    ;
    var obj_file = try parse_string(allocator, input);
    defer obj_file.deinit();

    try std.testing.expectEqual(2, obj_file.default_group.as_group().children.items.len);
    const t1 = obj_file.default_group.as_group().children.items[0].as_triangle();
    const t2 = obj_file.default_group.as_group().children.items[1].as_triangle();

    try Tuple.expectEqual(obj_file.vertices[0], t1.p1);
    try Tuple.expectEqual(obj_file.vertices[1], t1.p2);
    try Tuple.expectEqual(obj_file.vertices[2], t1.p3);
    try Tuple.expectEqual(obj_file.vertices[0], t2.p1);
    try Tuple.expectEqual(obj_file.vertices[2], t2.p2);
    try Tuple.expectEqual(obj_file.vertices[3], t2.p3);
}

test "Triangulating polygons" {
    const allocator = std.testing.allocator;

    const input =
        \\v -1 1 0
        \\v -1 0 0
        \\v 1 0 0
        \\v 1 1 0
        \\v 0 2 0
        \\f 1 2 3 4 5
    ;
    var obj_file = try parse_string(allocator, input);
    defer obj_file.deinit();

    try std.testing.expectEqual(3, obj_file.default_group.as_group().children.items.len);
    const t1 = obj_file.default_group.as_group().children.items[0].as_triangle();
    const t2 = obj_file.default_group.as_group().children.items[1].as_triangle();
    const t3 = obj_file.default_group.as_group().children.items[2].as_triangle();

    try Tuple.expectEqual(obj_file.vertices[0], t1.p1);
    try Tuple.expectEqual(obj_file.vertices[1], t1.p2);
    try Tuple.expectEqual(obj_file.vertices[2], t1.p3);
    try Tuple.expectEqual(obj_file.vertices[0], t2.p1);
    try Tuple.expectEqual(obj_file.vertices[2], t2.p2);
    try Tuple.expectEqual(obj_file.vertices[3], t2.p3);
    try Tuple.expectEqual(obj_file.vertices[0], t3.p1);
    try Tuple.expectEqual(obj_file.vertices[3], t3.p2);
    try Tuple.expectEqual(obj_file.vertices[4], t3.p3);
}

test "Triangles in groups" {
    const allocator = std.testing.allocator;

    const input =
        \\v -1 1 0
        \\v -1 0 0
        \\v 1 0 0
        \\v 1 1 0
        \\g FirstGroup
        \\f 1 2 3
        \\g SecondGroup
        \\f 1 3 4
    ;
    var obj_file = try parse_string(allocator, input);
    defer obj_file.deinit();

    try std.testing.expectEqual(2, obj_file.default_group.as_group().children.items.len);
    const g1 = obj_file.default_group.as_group().children.items[0].as_group();
    const g2 = obj_file.default_group.as_group().children.items[1].as_group();

    try std.testing.expectEqual(1, g1.children.items.len);
    const t1 = g1.children.items[0].as_triangle();

    try std.testing.expectEqual(1, g2.children.items.len);
    const t2 = g2.children.items[0].as_triangle();

    try Tuple.expectEqual(obj_file.vertices[0], t1.p1);
    try Tuple.expectEqual(obj_file.vertices[1], t1.p2);
    try Tuple.expectEqual(obj_file.vertices[2], t1.p3);
    try Tuple.expectEqual(obj_file.vertices[0], t2.p1);
    try Tuple.expectEqual(obj_file.vertices[2], t2.p2);
    try Tuple.expectEqual(obj_file.vertices[3], t2.p3);
}
