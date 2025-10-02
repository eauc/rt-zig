const std = @import("std");
const floats = @import("floats.zig");
const Float = floats.Float;
const Object = @import("Object.zig");
const ObjFile = @This();
const Tuple = @import("Tuple.zig");

allocator: std.mem.Allocator,
default_group: Object,
normals: []Tuple,
vertices: []Tuple,

pub fn deinit(self: *ObjFile) void {
    self.default_group.as_group().deinit();
    self.allocator.free(self.normals);
    self.allocator.free(self.vertices);
}

pub fn parse_file(allocator: std.mem.Allocator, relative_path: []const u8) !ObjFile {
    const f = try std.fs.cwd().openFile(relative_path, .{});
    const stats = try f.stat();
    const buffer = allocator.alloc(u8, stats.size) catch unreachable;
    defer allocator.free(buffer);
    const n_bytes = try f.read(buffer);
    return try parse_string(allocator, buffer[0..n_bytes]);
}

pub fn parse_string(allocator: std.mem.Allocator, input: []const u8) error{ InvalidCharacter, Overflow }!ObjFile {
    var default_group = Object.group(allocator);
    errdefer default_group.as_group().deinit();
    var current_group = &default_group;
    var normals = std.ArrayList(Tuple){};
    errdefer normals.deinit(allocator);
    var vertices = std.ArrayList(Tuple){};
    errdefer vertices.deinit(allocator);

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |l| {
        if (l.len == 0) {
            continue;
        }
        const line = if (l[l.len - 1] == '\r') l[0 .. l.len - 1] else l;
        var words = std.mem.splitScalar(u8, line, ' ');
        if (words.next()) |cmd| {
            if (std.mem.eql(u8, cmd, "f")) {
                var vertex_indices = std.ArrayList(usize){};
                defer vertex_indices.deinit(allocator);
                var normal_indices = std.ArrayList(usize){};
                defer normal_indices.deinit(allocator);

                while (next_token(&words)) |indices| {
                    var index = std.mem.splitScalar(u8, indices, '/');
                    const vertex_index_str = index.next().?;
                    const vertex_index = try std.fmt.parseInt(usize, vertex_index_str, 10);
                    vertex_indices.append(allocator, vertex_index) catch unreachable;

                    if (index.next() == null) {
                        continue;
                    }
                    if (index.next()) |normal_index_str| {
                        const normal_index = try std.fmt.parseInt(usize, normal_index_str, 10);
                        normal_indices.append(allocator, normal_index) catch unreachable;
                    }
                }

                var triangles = fan_triangulation(allocator, vertices, vertex_indices, normals, normal_indices);
                defer triangles.deinit(allocator);

                for (triangles.items) |t| {
                    _ = current_group.as_group().add_child(t);
                }
            }
            if (std.mem.eql(u8, cmd, "g")) {
                current_group = default_group.as_group().add_child(Object.group(allocator));
            }
            if (std.mem.eql(u8, cmd, "v")) {
                const x = try std.fmt.parseFloat(Float, next_token(&words).?);
                const y = try std.fmt.parseFloat(Float, next_token(&words).?);
                const z = try std.fmt.parseFloat(Float, next_token(&words).?);

                vertices.append(allocator, Tuple.point(x, y, z)) catch unreachable;
            }
            if (std.mem.eql(u8, cmd, "vn")) {
                const x = try std.fmt.parseFloat(Float, next_token(&words).?);
                const y = try std.fmt.parseFloat(Float, next_token(&words).?);
                const z = try std.fmt.parseFloat(Float, next_token(&words).?);

                normals.append(allocator, Tuple.vector(x, y, z)) catch unreachable;
            }
        }
    }
    return ObjFile{
        .allocator = allocator,
        .default_group = default_group,
        .normals = normals.toOwnedSlice(allocator) catch unreachable,
        .vertices = vertices.toOwnedSlice(allocator) catch unreachable,
    };
}

fn next_token(iter: *std.mem.SplitIterator(u8, .scalar)) ?[]const u8 {
    if (iter.next()) |token| {
        if (token.len > 0) {
            return token;
        }
        return next_token(iter);
    }
    return null;
}

fn fan_triangulation(allocator: std.mem.Allocator, vertices: std.ArrayList(Tuple), vertex_indices: std.ArrayList(usize), normals: std.ArrayList(Tuple), normal_indices: std.ArrayList(usize)) std.ArrayList(Object) {
    var triangles = std.ArrayList(Object){};
    for (1..vertex_indices.items.len - 1) |i| {
        const p1 = vertices.items[vertex_indices.items[0] - 1];
        const p2 = vertices.items[vertex_indices.items[i] - 1];
        const p3 = vertices.items[vertex_indices.items[i + 1] - 1];
        if (normal_indices.items.len > 0) {
            const n1 = normals.items[normal_indices.items[0] - 1];
            const n2 = normals.items[normal_indices.items[i] - 1];
            const n3 = normals.items[normal_indices.items[i + 1] - 1];

            triangles.append(allocator, Object.smooth_triangle(p1, p2, p3, n1, n2, n3)) catch unreachable;
        } else {
            triangles.append(allocator, Object.triangle(p1, p2, p3)) catch unreachable;
        }
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

test "Vertex normal records" {
    const allocator = std.testing.allocator;

    const input =
        \\vn 0 0 1
        \\vn 0.707 0 -0.707
        \\vn 1 2 3
    ;
    var obj_file = try parse_string(allocator, input);
    defer obj_file.deinit();

    try std.testing.expectEqual(3, obj_file.normals.len);
    try Tuple.expectEqual(Tuple.vector(0, 0, 1), obj_file.normals[0]);
    try Tuple.expectEqual(Tuple.vector(0.707, 0, -0.707), obj_file.normals[1]);
    try Tuple.expectEqual(Tuple.vector(1, 2, 3), obj_file.normals[2]);
}

test "Faces with normals" {
    const allocator = std.testing.allocator;

    const input =
        \\v 0 1 0
        \\v -1 0 0
        \\v 1 0 0
        \\vn -1 0 0
        \\vn 1 0 0
        \\vn 0 1 0
        \\f 1//3 2//1 3//2
        \\f 1/0/3 2/102/1 3/14/2
    ;
    var obj_file = try parse_string(allocator, input);
    defer obj_file.deinit();

    try std.testing.expectEqual(2, obj_file.default_group.as_group().children.items.len);
    const t1 = obj_file.default_group.as_group().children.items[0].as_smooth_triangle();
    const t2 = obj_file.default_group.as_group().children.items[1].as_smooth_triangle();

    try Tuple.expectEqual(obj_file.vertices[0], t1.p1);
    try Tuple.expectEqual(obj_file.vertices[1], t1.p2);
    try Tuple.expectEqual(obj_file.vertices[2], t1.p3);
    try Tuple.expectEqual(obj_file.normals[2], t1.n1);
    try Tuple.expectEqual(obj_file.normals[0], t1.n2);
    try Tuple.expectEqual(obj_file.normals[1], t1.n3);

    try Tuple.expectEqual(obj_file.vertices[0], t2.p1);
    try Tuple.expectEqual(obj_file.vertices[1], t2.p2);
    try Tuple.expectEqual(obj_file.vertices[2], t2.p3);
    try Tuple.expectEqual(obj_file.normals[2], t2.n1);
    try Tuple.expectEqual(obj_file.normals[0], t2.n2);
    try Tuple.expectEqual(obj_file.normals[1], t2.n3);
}
