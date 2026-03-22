const glfw3 = @import("c").glfw3;

pub const Key = enum {
    move_left,
    move_right,
    move_forward,
    move_back,
    rotate_left,
    rotate_right,
    rotate_up,
    rotate_down,
};

const Binding = struct {
    glfw_key: c_int,
    key: Key,
};

pub const key_map = [_]Binding{
    .{ .glfw_key = glfw3.GLFW_KEY_A, .key = .move_left },
    .{ .glfw_key = glfw3.GLFW_KEY_D, .key = .move_right },
    .{ .glfw_key = glfw3.GLFW_KEY_W, .key = .move_forward },
    .{ .glfw_key = glfw3.GLFW_KEY_S, .key = .move_back },
    .{ .glfw_key = glfw3.GLFW_KEY_LEFT, .key = .rotate_left },
    .{ .glfw_key = glfw3.GLFW_KEY_RIGHT, .key = .rotate_right },
    .{ .glfw_key = glfw3.GLFW_KEY_UP, .key = .rotate_up },
    .{ .glfw_key = glfw3.GLFW_KEY_DOWN, .key = .rotate_down },
};
