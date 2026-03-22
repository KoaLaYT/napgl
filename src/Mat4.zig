//! Column-major 4x4 matrix of f32.

arr: [16]f32,

const Self = @This();
const Vec3 = @import("Vec3.zig");
const Vec4 = @import("Vec4.zig");

/// Returns a 4x4 zero matrix.
pub fn zero() Self {
    return .{ .arr = [_]f32{0.0} ** 16 };
}

/// Returns a 4x4 identity matrix.
pub fn identity() Self {
    var m = zero();
    m.arr[0] = 1.0;
    m.arr[5] = 1.0;
    m.arr[10] = 1.0;
    m.arr[15] = 1.0;
    return m;
}

/// Column-major 4x4 matrix multiply: result = a * b
pub fn mul(a: Self, b: Self) Self {
    var result = zero();
    inline for (0..4) |col| {
        inline for (0..4) |row| {
            var sum: f32 = 0.0;
            inline for (0..4) |k| {
                sum += a.arr[k * 4 + row] * b.arr[col * 4 + k];
            }
            result.arr[col * 4 + row] = sum;
        }
    }
    return result;
}

/// Multiply this matrix by a Vec4.
pub fn mul_vec4(self: Self, v: Vec4) Vec4 {
    const a = self.arr;
    return Vec4.init(
        a[0] * v.x + a[4] * v.y + a[8] * v.z + a[12] * v.w,
        a[1] * v.x + a[5] * v.y + a[9] * v.z + a[13] * v.w,
        a[2] * v.x + a[6] * v.y + a[10] * v.z + a[14] * v.w,
        a[3] * v.x + a[7] * v.y + a[11] * v.z + a[15] * v.w,
    );
}

/// Rotation around X axis by `rad` radians.
pub fn rotate_x(rad: f32) Self {
    const c = @cos(rad);
    const s = @sin(rad);
    var m = identity();
    m.arr[5] = c;
    m.arr[6] = s;
    m.arr[9] = -s;
    m.arr[10] = c;
    return m;
}

/// Rotation around Y axis by `rad` radians.
pub fn rotate_y(rad: f32) Self {
    const c = @cos(rad);
    const s = @sin(rad);
    var m = identity();
    m.arr[0] = c;
    m.arr[2] = -s;
    m.arr[8] = s;
    m.arr[10] = c;
    return m;
}

/// Rotation around Z axis by `rad` radians.
pub fn rotate_z(rad: f32) Self {
    const c = @cos(rad);
    const s = @sin(rad);
    var m = identity();
    m.arr[0] = c;
    m.arr[1] = s;
    m.arr[4] = -s;
    m.arr[5] = c;
    return m;
}

/// Returns a 4x4 scaling matrix.
pub fn scale(x: f32, y: f32, z: f32) Self {
    var m = zero();
    m.arr[0] = x;
    m.arr[5] = y;
    m.arr[10] = z;
    m.arr[15] = 1.0;
    return m;
}

/// Returns a 4x4 translation matrix.
pub fn translate(v: Vec3) Self {
    var m = identity();
    m.arr[12] = v.x;
    m.arr[13] = v.y;
    m.arr[14] = v.z;
    return m;
}

/// Returns the inverse of the matrix, or `null` if it is singular.
pub fn inverse(self: Self) ?Self {
    const m = self.arr;

    // Compute 2x2 sub-determinants (pairs from columns 0-1 and columns 2-3)
    const s0 = m[0] * m[5] - m[4] * m[1];
    const s1 = m[0] * m[9] - m[8] * m[1];
    const s2 = m[0] * m[13] - m[12] * m[1];
    const s3 = m[4] * m[9] - m[8] * m[5];
    const s4 = m[4] * m[13] - m[12] * m[5];
    const s5 = m[8] * m[13] - m[12] * m[9];

    const c5 = m[10] * m[15] - m[14] * m[11];
    const c4 = m[6] * m[15] - m[14] * m[7];
    const c3 = m[6] * m[11] - m[10] * m[7];
    const c2 = m[2] * m[15] - m[14] * m[3];
    const c1 = m[2] * m[11] - m[10] * m[3];
    const c0 = m[2] * m[7] - m[6] * m[3];

    const det = s0 * c5 - s1 * c4 + s2 * c3 + s3 * c2 - s4 * c1 + s5 * c0;
    if (@abs(det) < 1e-10) return null;

    const inv_det = 1.0 / det;

    return .{ .arr = .{
        (m[5] * c5 - m[9] * c4 + m[13] * c3) * inv_det,
        (-m[1] * c5 + m[9] * c2 - m[13] * c1) * inv_det,
        (m[1] * c4 - m[5] * c2 + m[13] * c0) * inv_det,
        (-m[1] * c3 + m[5] * c1 - m[9] * c0) * inv_det,

        (-m[4] * c5 + m[8] * c4 - m[12] * c3) * inv_det,
        (m[0] * c5 - m[8] * c2 + m[12] * c1) * inv_det,
        (-m[0] * c4 + m[4] * c2 - m[12] * c0) * inv_det,
        (m[0] * c3 - m[4] * c1 + m[8] * c0) * inv_det,

        (m[7] * s5 - m[11] * s4 + m[15] * s3) * inv_det,
        (-m[3] * s5 + m[11] * s2 - m[15] * s1) * inv_det,
        (m[3] * s4 - m[7] * s2 + m[15] * s0) * inv_det,
        (-m[3] * s3 + m[7] * s1 - m[11] * s0) * inv_det,

        (-m[6] * s5 + m[10] * s4 - m[14] * s3) * inv_det,
        (m[2] * s5 - m[10] * s2 + m[14] * s1) * inv_det,
        (-m[2] * s4 + m[6] * s2 - m[14] * s0) * inv_det,
        (m[2] * s3 - m[6] * s1 + m[10] * s0) * inv_det,
    } };
}

/// Returns a perspective projection matrix
///   fov_y  – vertical field-of-view in radians
///   aspect – width / height
///   near, far – clipping planes (positive)
pub fn perspective(fov_y: f32, aspect: f32, near: f32, far: f32) Self {
    const f = 1.0 / @tan(fov_y / 2.0);
    var m = zero();
    m.arr[0] = f / aspect;
    m.arr[5] = f;
    m.arr[10] = (far + near) / (near - far);
    m.arr[11] = -1.0;
    m.arr[14] = (2.0 * far * near) / (near - far);
    return m;
}
