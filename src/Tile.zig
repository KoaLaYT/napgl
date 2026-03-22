const gl = @import("c").gl;

const Self = @This();

// zig fmt: off
/// A unit quad on the xz plane (y = 0), from (0,0,0) to (1,0,1), CW winding from +Y.
const pos = [_]f32{
    0, 0, 0,   1, 0, 0,   0, 0, 1,
    1, 0, 0,   1, 0, 1,   0, 0, 1,
};
// zig fmt: on

vao: gl.GLuint,

pub fn init() Self {
    var vbo: gl.GLuint = 0;
    gl.glGenBuffers(1, &vbo);
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, vbo);
    gl.glBufferData(gl.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(pos)), &pos, gl.GL_STATIC_DRAW);

    var vao: gl.GLuint = 0;
    gl.glGenVertexArrays(1, &vao);
    gl.glBindVertexArray(vao);
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, vbo);
    gl.glVertexAttribPointer(0, 3, gl.GL_FLOAT, gl.GL_FALSE, 0, null);
    gl.glEnableVertexAttribArray(0);

    return .{ .vao = vao };
}

pub fn draw(self: Self) void {
    gl.glBindVertexArray(self.vao);
    gl.glDrawArrays(gl.GL_TRIANGLES, 0, 6);
}
