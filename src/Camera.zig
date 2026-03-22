//! FPS-style camera using quaternion orientation.
//! Yaw rotates around the world Y axis, pitch around the camera's local X axis.

const std = @import("std");
const Vec3 = @import("Vec3.zig");
const Mat4 = @import("Mat4.zig");
const Quat = @import("Quat.zig");
const control = @import("control.zig");

const move_speed: f32 = 5.0;
const rotate_speed: f32 = 60.0 * std.math.pi / 180.0;

pos: Vec3,
yaw: f32,   // radians
pitch: f32, // radians

const Self = @This();

const pitch_limit: f32 = 89.0 * std.math.pi / 180.0;

pub fn init(position: Vec3) Self {
    return .{
        .pos = position,
        .yaw = 0,
        .pitch = 0,
    };
}

/// Apply yaw and pitch deltas (in radians). Pitch is clamped to ±89°.
pub fn rotate(self: *Self, yaw_delta: f32, pitch_delta: f32) void {
    self.yaw += yaw_delta;
    self.pitch = std.math.clamp(self.pitch + pitch_delta, -pitch_limit, pitch_limit);
}

/// Compute the orientation quaternion from current yaw and pitch.
pub fn orientation(self: Self) Quat {
    const q_yaw = Quat.from_axis_angle(Vec3.init(0, 1, 0), self.yaw);
    const q_pitch = Quat.from_axis_angle(Vec3.init(1, 0, 0), -self.pitch);
    return Quat.mul(q_yaw, q_pitch);
}

/// Forward direction on the XZ plane (yaw only, ignoring pitch).
pub fn forward(self: Self) Vec3 {
    return Vec3.init(-@sin(self.yaw), 0, -@cos(self.yaw));
}

/// Right direction on the XZ plane (yaw only, ignoring pitch).
pub fn right(self: Self) Vec3 {
    return Vec3.init(@cos(self.yaw), 0, -@sin(self.yaw));
}

pub fn on_key(self: *Self, key: control.Key, elapsed: f32) void {
    switch (key) {
        .move_left => self.pos = self.pos.add(self.right().scale(-move_speed * elapsed)),
        .move_right => self.pos = self.pos.add(self.right().scale(move_speed * elapsed)),
        .move_forward => self.pos = self.pos.add(self.forward().scale(move_speed * elapsed)),
        .move_back => self.pos = self.pos.add(self.forward().scale(-move_speed * elapsed)),
        .rotate_left => self.rotate(rotate_speed * elapsed, 0),
        .rotate_right => self.rotate(-rotate_speed * elapsed, 0),
        .rotate_up => self.rotate(0, -rotate_speed * elapsed),
        .rotate_down => self.rotate(0, rotate_speed * elapsed),
    }
}

/// Compute the view matrix: inverse(orientation) * translate(-pos).
pub fn view_matrix(self: Self) Mat4 {
    const q = self.orientation();
    const inv_rot = Quat.conjugate(q).to_mat4();
    const inv_trans = Mat4.translate(self.pos.negate());
    return Mat4.mul(inv_rot, inv_trans);
}
