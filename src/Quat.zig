//! Unit quaternion (w + xi + yj + zk) for representing 3D rotations.

w: f32,
x: f32,
y: f32,
z: f32,

const Self = @This();
const Vec3 = @import("Vec3.zig");
const Mat4 = @import("Mat4.zig");

pub fn identity() Self {
    return .{ .w = 1, .x = 0, .y = 0, .z = 0 };
}

/// Create a quaternion from an axis-angle rotation.
/// `axis` must be a unit vector. `angle` is in radians.
pub fn from_axis_angle(axis: Vec3, angle: f32) Self {
    const half = angle * 0.5;
    const s = @sin(half);
    return .{
        .w = @cos(half),
        .x = axis.x * s,
        .y = axis.y * s,
        .z = axis.z * s,
    };
}

/// Hamilton product: a * b (applies rotation b first, then a).
pub fn mul(a: Self, b: Self) Self {
    return .{
        .w = a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z,
        .x = a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
        .y = a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
        .z = a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w,
    };
}

/// Conjugate (inverse for unit quaternions).
pub fn conjugate(q: Self) Self {
    return .{ .w = q.w, .x = -q.x, .y = -q.y, .z = -q.z };
}

/// Normalize to unit length.
pub fn normalize(q: Self) Self {
    const len = @sqrt(q.w * q.w + q.x * q.x + q.y * q.y + q.z * q.z);
    if (len == 0) return identity();
    const inv = 1.0 / len;
    return .{ .w = q.w * inv, .x = q.x * inv, .y = q.y * inv, .z = q.z * inv };
}

/// Convert unit quaternion to a 4x4 rotation matrix (column-major).
pub fn to_mat4(q: Self) Mat4 {
    const xx = q.x * q.x;
    const yy = q.y * q.y;
    const zz = q.z * q.z;
    const xy = q.x * q.y;
    const xz = q.x * q.z;
    const yz = q.y * q.z;
    const wx = q.w * q.x;
    const wy = q.w * q.y;
    const wz = q.w * q.z;

    var m = Mat4.zero();
    m.arr[0] = 1.0 - 2.0 * (yy + zz);
    m.arr[1] = 2.0 * (xy + wz);
    m.arr[2] = 2.0 * (xz - wy);

    m.arr[4] = 2.0 * (xy - wz);
    m.arr[5] = 1.0 - 2.0 * (xx + zz);
    m.arr[6] = 2.0 * (yz + wx);

    m.arr[8] = 2.0 * (xz + wy);
    m.arr[9] = 2.0 * (yz - wx);
    m.arr[10] = 1.0 - 2.0 * (xx + yy);

    m.arr[15] = 1.0;
    return m;
}
