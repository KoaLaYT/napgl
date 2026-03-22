//! 3-component vector of f32.

x: f32,
y: f32,
z: f32,

const Self = @This();

pub fn init(x: f32, y: f32, z: f32) Self {
    return .{ .x = x, .y = y, .z = z };
}
