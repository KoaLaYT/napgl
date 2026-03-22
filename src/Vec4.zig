//! 4-component vector of f32.

x: f32,
y: f32,
z: f32,
w: f32,

const Self = @This();

pub fn init(x: f32, y: f32, z: f32, w: f32) Self {
    return .{ .x = x, .y = y, .z = z, .w = w };
}

pub fn negate(self: Self) Self {
    return .{ .x = -self.x, .y = -self.y, .z = -self.z, .w = -self.w };
}

pub fn add(a: Self, b: Self) Self {
    return .{ .x = a.x + b.x, .y = a.y + b.y, .z = a.z + b.z, .w = a.w + b.w };
}

pub fn sub(a: Self, b: Self) Self {
    return .{ .x = a.x - b.x, .y = a.y - b.y, .z = a.z - b.z, .w = a.w - b.w };
}

pub fn scale(self: Self, s: f32) Self {
    return .{ .x = self.x * s, .y = self.y * s, .z = self.z * s, .w = self.w * s };
}

pub fn normalize(self: Self) Self {
    const len = @sqrt(self.x * self.x + self.y * self.y + self.z * self.z + self.w * self.w);
    if (len == 0.0) return self;
    return self.scale(1.0 / len);
}
