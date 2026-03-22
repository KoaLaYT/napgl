const gl = @import("c").gl;

const Self = @This();

// zig fmt: off
const pos = [_]f32{
    // front (+Z)
    -0.5, -0.5,  0.5,  -0.5,  0.5,  0.5,   0.5, -0.5,  0.5,
    -0.5,  0.5,  0.5,   0.5,  0.5,  0.5,   0.5, -0.5,  0.5,
    // back (-Z)
     0.5, -0.5, -0.5,   0.5,  0.5, -0.5,  -0.5, -0.5, -0.5,
     0.5,  0.5, -0.5,  -0.5,  0.5, -0.5,  -0.5, -0.5, -0.5,
    // right (+X)
     0.5, -0.5,  0.5,   0.5,  0.5,  0.5,   0.5, -0.5, -0.5,
     0.5,  0.5,  0.5,   0.5,  0.5, -0.5,   0.5, -0.5, -0.5,
    // left (-X)
    -0.5, -0.5, -0.5,  -0.5,  0.5, -0.5,  -0.5, -0.5,  0.5,
    -0.5,  0.5, -0.5,  -0.5,  0.5,  0.5,  -0.5, -0.5,  0.5,
    // top (+Y)
    -0.5,  0.5,  0.5,  -0.5,  0.5, -0.5,   0.5,  0.5,  0.5,
    -0.5,  0.5, -0.5,   0.5,  0.5, -0.5,   0.5,  0.5,  0.5,
    // bottom (-Y)
    -0.5, -0.5, -0.5,  -0.5, -0.5,  0.5,   0.5, -0.5, -0.5,
    -0.5, -0.5,  0.5,   0.5, -0.5,  0.5,   0.5, -0.5, -0.5,
};

const color = [_]f32{
    // front: red
    1.0, 0.0, 0.0,  1.0, 0.0, 0.0,  1.0, 0.0, 0.0,
    1.0, 0.0, 0.0,  1.0, 0.0, 0.0,  1.0, 0.0, 0.0,
    // back: cyan
    0.0, 1.0, 1.0,  0.0, 1.0, 1.0,  0.0, 1.0, 1.0,
    0.0, 1.0, 1.0,  0.0, 1.0, 1.0,  0.0, 1.0, 1.0,
    // right: green
    0.0, 1.0, 0.0,  0.0, 1.0, 0.0,  0.0, 1.0, 0.0,
    0.0, 1.0, 0.0,  0.0, 1.0, 0.0,  0.0, 1.0, 0.0,
    // left: magenta
    1.0, 0.0, 1.0,  1.0, 0.0, 1.0,  1.0, 0.0, 1.0,
    1.0, 0.0, 1.0,  1.0, 0.0, 1.0,  1.0, 0.0, 1.0,
    // top: blue
    0.0, 0.0, 1.0,  0.0, 0.0, 1.0,  0.0, 0.0, 1.0,
    0.0, 0.0, 1.0,  0.0, 0.0, 1.0,  0.0, 0.0, 1.0,
    // bottom: yellow
    1.0, 1.0, 0.0,  1.0, 1.0, 0.0,  1.0, 1.0, 0.0,
    1.0, 1.0, 0.0,  1.0, 1.0, 0.0,  1.0, 1.0, 0.0,
};
// zig fmt: on

vao: gl.GLuint,

pub fn init() Self {
    var pos_vbo: gl.GLuint = 0;
    gl.glGenBuffers(1, &pos_vbo);
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, pos_vbo);
    gl.glBufferData(gl.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(pos)), &pos, gl.GL_STATIC_DRAW);

    var col_vbo: gl.GLuint = 0;
    gl.glGenBuffers(1, &col_vbo);
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, col_vbo);
    gl.glBufferData(gl.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(color)), &color, gl.GL_STATIC_DRAW);

    var vao: gl.GLuint = 0;
    gl.glGenVertexArrays(1, &vao);
    gl.glBindVertexArray(vao);
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, pos_vbo);
    gl.glVertexAttribPointer(0, 3, gl.GL_FLOAT, gl.GL_FALSE, 0, null);
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, col_vbo);
    gl.glVertexAttribPointer(1, 3, gl.GL_FLOAT, gl.GL_FALSE, 0, null);
    gl.glEnableVertexAttribArray(0);
    gl.glEnableVertexAttribArray(1);

    return .{ .vao = vao };
}

pub fn draw(self: Self) void {
    gl.glBindVertexArray(self.vao);
    gl.glDrawArrays(gl.GL_TRIANGLES, 0, 36);
}
