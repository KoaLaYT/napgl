//! 3-component vector of f32.

x: f32,
y: f32,
z: f32,

const Self = @This();

pub fn init(x: f32, y: f32, z: f32) Self {
    return .{ .x = x, .y = y, .z = z };
}

pub fn negate(self: Self) Self {
    return .{ .x = -self.x, .y = -self.y, .z = -self.z };
}

pub fn add(a: Self, b: Self) Self {
    return .{ .x = a.x + b.x, .y = a.y + b.y, .z = a.z + b.z };
}

pub fn scale(self: Self, s: f32) Self {
    return .{ .x = self.x * s, .y = self.y * s, .z = self.z * s };
}
