//! Column-major 4x4 matrix of f32.

arr: [16]f32,

const Self = @This();
const Vec3 = @import("Vec3.zig");

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
