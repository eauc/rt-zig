const std = @import("std");
const floats = @import("floats.zig");
const Float = floats.Float;
const Matrix = @This();
const Tuple = @import("Tuple.zig");

fn MatrixS(comptime S: usize) type {
    return [S][S]Float;
}

data: MatrixS(4),

fn initS(comptime S: usize, input: [S][S]Float) MatrixS(S) {
    return input;
}

pub fn init(input: [4][4]Float) Matrix {
    return .{ .data = initS(4, input) };
}

fn zero(comptime S: usize) MatrixS(S) {
    return initS(S, [_][S]Float{[_]Float{0} ** S} ** S);
}

pub fn identity() Matrix {
    var result = zero(4);
    for (0..4) |i| {
        result[i][i] = 1;
    }
    return .{ .data = result };
}

fn elem(comptime S: usize, m: MatrixS(S), row: usize, col: usize) Float {
    return m[row][col];
}

fn equal(comptime S: usize, a: MatrixS(S), b: MatrixS(S)) bool {
    for (0..S) |i| {
        for (0..S) |j| {
            if (!floats.equal(a[i][j], b[i][j])) {
                return false;
            }
        }
    }
    return true;
}

fn expectEqualS(comptime S: usize, a: MatrixS(S), b: MatrixS(S)) !void {
    for (0..S) |i| {
        for (0..S) |j| {
            try floats.expectEqual(a[i][j], b[i][j]);
        }
    }
}

pub fn expectEqual(self: Matrix, b: Matrix) !void {
    try expectEqualS(4, self.data, b.data);
}

test init {
    const m = init([_][4]Float{
        [_]Float{ 1, 2, 3, 4 },
        [_]Float{ 5.5, 6.5, 7.5, 8.5 },
        [_]Float{ 9, 10, 11, 12 },
        [_]Float{ 13.5, 14.5, 15.5, 16.5 },
    });
    try std.testing.expectEqual(1, elem(4, m.data, 0, 0));
    try std.testing.expectEqual(4, elem(4, m.data, 0, 3));
    try std.testing.expectEqual(5.5, elem(4, m.data, 1, 0));
    try std.testing.expectEqual(7.5, elem(4, m.data, 1, 2));
    try std.testing.expectEqual(11, elem(4, m.data, 2, 2));
    try std.testing.expectEqual(13.5, elem(4, m.data, 3, 0));
    try std.testing.expectEqual(15.5, elem(4, m.data, 3, 2));
}

test "Matrix(2)" {
    const m = initS(2, [2][2]Float{
        [_]Float{ -3, 5 },
        [_]Float{ 1, -2 },
    });
    try std.testing.expectEqual(-3, elem(2, m, 0, 0));
    try std.testing.expectEqual(5, elem(2, m, 0, 1));
    try std.testing.expectEqual(1, elem(2, m, 1, 0));
    try std.testing.expectEqual(-2, elem(2, m, 1, 1));
}

test "Matrix(3)" {
    const m = initS(3, [3][3]Float{
        [_]Float{ -3, 5, 0 },
        [_]Float{ 1, -2, -7 },
        [_]Float{ 0, 1, 1 },
    });
    try std.testing.expectEqual(-3, elem(3, m, 0, 0));
    try std.testing.expectEqual(5, elem(3, m, 0, 1));
    try std.testing.expectEqual(0, elem(3, m, 0, 2));
    try std.testing.expectEqual(1, elem(3, m, 1, 0));
    try std.testing.expectEqual(-2, elem(3, m, 1, 1));
    try std.testing.expectEqual(-7, elem(3, m, 1, 2));
    try std.testing.expectEqual(0, elem(3, m, 2, 0));
    try std.testing.expectEqual(1, elem(3, m, 2, 1));
    try std.testing.expectEqual(1, elem(3, m, 2, 2));
}

/// Multiplies two matrices
pub fn mul(self: Matrix, b: Matrix) Matrix {
    var result = zero(4);
    for (0..4) |i| {
        for (0..4) |j| {
            var sum: Float = 0;
            for (0..4) |k| {
                sum += self.data[i][k] * b.data[k][j];
            }
            result[i][j] = sum;
        }
    }
    return init(result);
}

test mul {
    const a = init([4][4]Float{
        [_]Float{ 1, 2, 3, 4 },
        [_]Float{ 5, 6, 7, 8 },
        [_]Float{ 9, 8, 7, 6 },
        [_]Float{ 5, 4, 3, 2 },
    });
    const b = init([4][4]Float{
        [_]Float{ -2, 1, 2, 3 },
        [_]Float{ 3, 2, 1, -1 },
        [_]Float{ 4, 3, 6, 5 },
        [_]Float{ 1, 2, 7, 8 },
    });
    const c = a.mul(b);

    try expectEqual(init([4][4]Float{
        [_]Float{ 20, 22, 50, 48 },
        [_]Float{ 44, 54, 114, 108 },
        [_]Float{ 40, 58, 110, 102 },
        [_]Float{ 16, 26, 46, 42 },
    }), c);
}

test "Multiplying a matrix by the identity matrix" {
    const a = init([4][4]Float{
        [_]Float{ 0, 1, 2, 4 },
        [_]Float{ 1, 2, 4, 8 },
        [_]Float{ 2, 4, 8, 16 },
        [_]Float{ 4, 8, 16, 32 },
    });
    try expectEqual(a, a.mul(identity()));
}

/// Multiplies a matrix by a tuple
pub fn mult(self: Matrix, t: Tuple) Tuple {
    return Tuple.init(
        self.data[0][0] * t.x + self.data[0][1] * t.y + self.data[0][2] * t.z + self.data[0][3] * t.w,
        self.data[1][0] * t.x + self.data[1][1] * t.y + self.data[1][2] * t.z + self.data[1][3] * t.w,
        self.data[2][0] * t.x + self.data[2][1] * t.y + self.data[2][2] * t.z + self.data[2][3] * t.w,
        self.data[3][0] * t.x + self.data[3][1] * t.y + self.data[3][2] * t.z + self.data[3][3] * t.w,
    );
}

test mult {
    const a = init([4][4]Float{
        [_]Float{ 1, 2, 3, 4 },
        [_]Float{ 2, 4, 4, 2 },
        [_]Float{ 8, 6, 4, 1 },
        [_]Float{ 0, 0, 0, 1 },
    });
    const b = Tuple.init(1, 2, 3, 1);
    try Tuple.expectEqual(Tuple.init(18, 24, 33, 1), a.mult(b));
}

test "Multiplying the identity matrix by a tuple" {
    const a = Tuple.init(1, 2, 3, 4);
    try Tuple.expectEqual(a, mult(identity(), a));
}

/// Transposes a matrix
pub fn transpose(self: Matrix) Matrix {
    var result = zero(4);
    for (0..4) |i| {
        for (0..4) |j| {
            result[i][j] = self.data[j][i];
        }
    }
    return init(result);
}

test transpose {
    const a = init([4][4]Float{
        [_]Float{ 0, 9, 3, 0 },
        [_]Float{ 9, 8, 0, 8 },
        [_]Float{ 1, 8, 5, 3 },
        [_]Float{ 0, 0, 5, 8 },
    });

    try expectEqual(init([4][4]Float{
        [_]Float{ 0, 9, 1, 0 },
        [_]Float{ 9, 8, 8, 0 },
        [_]Float{ 3, 0, 5, 5 },
        [_]Float{ 0, 8, 3, 8 },
    }), transpose(a));
}

fn det2(a: MatrixS(2)) Float {
    return a[0][0] * a[1][1] - a[0][1] * a[1][0];
}

test det2 {
    const a = initS(2, [2][2]Float{
        [_]Float{ 1, 5 },
        [_]Float{ -3, 2 },
    });
    try floats.expectEqual(17, det2(a));
}

fn submatrix(comptime S: usize, a: MatrixS(S), row: usize, col: usize) MatrixS(S - 1) {
    var result = zero(S - 1);
    var destRow: usize = 0;
    for (0..S) |i| {
        if (i == row) {
            continue;
        }
        var destCol: usize = 0;
        for (0..S) |j| {
            if (j == col) {
                continue;
            }
            result[destRow][destCol] = a[i][j];
            destCol += 1;
        }
        destRow += 1;
    }
    return result;
}

test submatrix {
    const a = initS(3, [3][3]Float{
        [_]Float{ 1, 5, 0 },
        [_]Float{ -3, 2, 7 },
        [_]Float{ 0, 6, -3 },
    });
    try expectEqualS(2, initS(2, [2][2]Float{
        [_]Float{ -3, 2 },
        [_]Float{ 0, 6 },
    }), submatrix(3, a, 0, 2));
}

test "Submatrix of a 4x4 matrix is a 3x3 matrix" {
    const a = init([4][4]Float{
        [_]Float{ -6, 1, 1, 6 },
        [_]Float{ -8, 5, 8, 6 },
        [_]Float{ -1, 0, 8, 2 },
        [_]Float{ -7, 1, -1, 1 },
    });
    try expectEqualS(3, initS(3, [3][3]Float{
        [_]Float{ -6, 1, 6 },
        [_]Float{ -8, 8, 6 },
        [_]Float{ -7, -1, 1 },
    }), submatrix(4, a.data, 2, 1));
}

fn minor(comptime S: usize, a: MatrixS(S), row: usize, col: usize) Float {
    const sub = submatrix(S, a, row, col);
    if (S == 3) {
        return det2(sub);
    }
    return det(S - 1, sub);
}

test minor {
    const a = initS(3, [3][3]Float{
        [_]Float{ 3, 5, 0 },
        [_]Float{ 2, -1, -7 },
        [_]Float{ 6, -1, 5 },
    });
    try floats.expectEqual(25, minor(3, a, 1, 0));
}

fn cofactor(comptime S: usize, a: MatrixS(S), row: usize, col: usize) Float {
    const min = minor(S, a, row, col);
    return if ((row + col) % 2 == 0) min else -min;
}

test cofactor {
    const a = initS(3, [3][3]Float{
        [_]Float{ 3, 5, 0 },
        [_]Float{ 2, -1, -7 },
        [_]Float{ 6, -1, 5 },
    });
    try floats.expectEqual(-12, minor(3, a, 0, 0));
    try floats.expectEqual(-12, cofactor(3, a, 0, 0));
    try floats.expectEqual(25, minor(3, a, 1, 0));
    try floats.expectEqual(-25, cofactor(3, a, 1, 0));
}

fn det(comptime S: usize, a: MatrixS(S)) Float {
    var result: Float = 0;
    for (0..S) |i| {
        result += a[0][i] * cofactor(S, a, 0, i);
    }
    return result;
}

test det {
    const a = initS(3, [3][3]Float{
        [_]Float{ 1, 2, 6 },
        [_]Float{ -5, 8, -4 },
        [_]Float{ 2, 6, 4 },
    });
    try floats.expectEqual(56, cofactor(3, a, 0, 0));
    try floats.expectEqual(12, cofactor(3, a, 0, 1));
    try floats.expectEqual(-46, cofactor(3, a, 0, 2));
    try floats.expectEqual(-196, det(3, a));
}

test "Determinant of a 4x4 matrix" {
    const a = init([4][4]Float{
        [_]Float{ -2, -8, 3, 5 },
        [_]Float{ -3, 1, 7, 3 },
        [_]Float{ 1, 2, -9, 6 },
        [_]Float{ -6, 7, 7, -9 },
    });
    try floats.expectEqual(690, cofactor(4, a.data, 0, 0));
    try floats.expectEqual(447, cofactor(4, a.data, 0, 1));
    try floats.expectEqual(210, cofactor(4, a.data, 0, 2));
    try floats.expectEqual(51, cofactor(4, a.data, 0, 3));
    try floats.expectEqual(-4071, det(4, a.data));
}

fn invertible(a: Matrix) bool {
    return !floats.equals(0, det(4, a.data));
}

test invertible {
    try std.testing.expect(init([4][4]Float{
        [_]Float{ 6, 4, 4, 4 },
        [_]Float{ 5, 5, 7, 6 },
        [_]Float{ 4, -9, 3, -7 },
        [_]Float{ 9, 1, 7, -6 },
    }).invertible());

    try std.testing.expect(!init([4][4]Float{
        [_]Float{ -4, 2, -2, -3 },
        [_]Float{ 9, 6, 2, 6 },
        [_]Float{ 0, -5, 1, -5 },
        [_]Float{ 0, 0, 0, 0 },
    }).invertible());
}

/// Inverse of a 4x4 matrix
pub fn inverse(a: Matrix) Matrix {
    var result = zero(4);
    const d = det(4, a.data);
    for (0..4) |i| {
        for (0..4) |j| {
            result[i][j] = cofactor(4, a.data, j, i) / d;
        }
    }
    return init(result);
}

test inverse {
    const a = init([4][4]Float{
        [_]Float{ -5, 2, 6, -8 },
        [_]Float{ 1, -5, 1, 8 },
        [_]Float{ 7, 7, -6, -7 },
        [_]Float{ 1, -3, 7, 4 },
    });
    const b = a.inverse();
    try expectEqual(init([4][4]Float{
        [_]Float{ 0.21805, 0.45113, 0.24060, -0.04511 },
        [_]Float{ -0.80827, -1.45677, -0.44361, 0.52068 },
        [_]Float{ -0.07895, -0.22368, -0.05263, 0.19737 },
        [_]Float{ -0.52256, -0.81391, -0.30075, 0.30639 },
    }), b);
}

test "Calculating the inverse of another matrix" {
    const a = init([4][4]Float{
        [_]Float{ 8, -5, 9, 2 },
        [_]Float{ 7, 5, 6, 1 },
        [_]Float{ -6, 0, 9, 6 },
        [_]Float{ -3, 0, -9, -4 },
    });
    const b = a.inverse();
    try expectEqual(init([4][4]Float{
        [_]Float{ -0.15385, -0.15385, -0.28205, -0.53846 },
        [_]Float{ -0.07692, 0.12308, 0.02564, 0.03077 },
        [_]Float{ 0.35897, 0.35897, 0.43590, 0.92308 },
        [_]Float{ -0.69231, -0.69231, -0.76923, -1.92308 },
    }), b);
}

test "Calculating the inverse of a third matrix" {
    const a = init([4][4]Float{
        [_]Float{ 9, 3, 0, 9 },
        [_]Float{ -5, -2, -6, -3 },
        [_]Float{ -4, 9, 6, 4 },
        [_]Float{ -7, 6, 6, 2 },
    });
    const b = a.inverse();
    try expectEqual(init([4][4]Float{
        [_]Float{ -0.04074, -0.07778, 0.14444, -0.22222 },
        [_]Float{ -0.07778, 0.03333, 0.36667, -0.33333 },
        [_]Float{ -0.02901, -0.14630, -0.10926, 0.12963 },
        [_]Float{ 0.17778, 0.06667, -0.26667, 0.33333 },
    }), b);
}

test "Multiplying a product by its inverse" {
    const a = init([4][4]Float{
        [_]Float{ 3, -9, 7, 3 },
        [_]Float{ 3, -8, 2, -9 },
        [_]Float{ -4, 4, 4, 1 },
        [_]Float{ -6, 5, -1, 1 },
    });
    const b = init([4][4]Float{
        [_]Float{ 8, 2, 2, 2 },
        [_]Float{ 3, -1, 7, 0 },
        [_]Float{ 7, 0, 5, 4 },
        [_]Float{ 6, -2, 0, 5 },
    });
    const c = mul(a, b);
    try expectEqual(a, mul(c, b.inverse()));
}
