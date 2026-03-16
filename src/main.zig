const std = @import("std");
const glfw3 = @import("c").glfw3;
const gl = @import("c").gl;

var g_previous_seconds: f64 = 0;
var g_frame_count: u64 = 0;

const vertex_shader =
    \\#version 410
    \\
    \\in vec3 vp;
    \\void main () {
    \\  gl_Position = vec4 (vp, 1.0);
    \\}
;

const fragment_shader =
    \\#version 410
    \\
    \\out vec4 frag_colour;
    \\void main () {
    \\  frag_colour = vec4 (0.5, 0.0, 0.5, 1.0);
    \\}
;

pub fn main() !void {
    _ = glfw3.glfwSetErrorCallback(glfw_error_callback);

    if (glfw3.glfwInit() == 0) {
        std.log.err("glfwInit failed", .{});
    }
    defer glfw3.glfwTerminate();

    glfw3.glfwWindowHint(glfw3.GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfw3.glfwWindowHint(glfw3.GLFW_CONTEXT_VERSION_MINOR, 1);
    glfw3.glfwWindowHint(glfw3.GLFW_OPENGL_FORWARD_COMPAT, gl.GL_TRUE);
    glfw3.glfwWindowHint(glfw3.GLFW_OPENGL_PROFILE, glfw3.GLFW_OPENGL_CORE_PROFILE);

    const window = glfw3.glfwCreateWindow(640, 480, "napgl", null, null);
    if (window == null) {
        std.log.err("glfwCreateWindow failed", .{});
        return;
    }
    glfw3.glfwMakeContextCurrent(window);

    const version = gl.gladLoadGL(glfw3.glfwGetProcAddress);
    if (version == 0) {
        std.log.err("Failed to initialize OpenGL context", .{});
        return;
    }
    std.log.info("Loaded OpenGL {d}.{d}", .{ gl.GLAD_VERSION_MAJOR(version), gl.GLAD_VERSION_MINOR(version) });
    log_gl_params();

    // tell GL to only draw onto a pixel if the shape is closer to the viewer
    gl.glEnable(gl.GL_DEPTH_TEST); // enable depth-testing
    gl.glDepthFunc(gl.GL_LESS); // depth-testing interprets a smaller value as "closer"

    const points = [_]f32{
        0.0,  0.5,  0.0,
        0.5,  -0.5, 0.0,
        -0.5, -0.5, 0.0,
    };

    var vbo: gl.GLuint = 0;
    gl.glGenBuffers(1, &vbo);
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, vbo);
    gl.glBufferData(gl.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(points)), &points, gl.GL_STATIC_DRAW);

    var vao: gl.GLuint = 0;
    gl.glGenVertexArrays(1, &vao);
    gl.glBindVertexArray(vao);
    gl.glEnableVertexAttribArray(0);
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, vbo);
    gl.glVertexAttribPointer(0, 3, gl.GL_FLOAT, gl.GL_FALSE, 0, null);

    const vs = gl.glCreateShader(gl.GL_VERTEX_SHADER);
    gl.glShaderSource(vs, 1, @ptrCast(&vertex_shader), null);
    gl.glCompileShader(vs);

    const fs = gl.glCreateShader(gl.GL_FRAGMENT_SHADER);
    gl.glShaderSource(fs, 1, @ptrCast(&fragment_shader), null);
    gl.glCompileShader(fs);

    const shader_program = gl.glCreateProgram();
    gl.glAttachShader(shader_program, fs);
    gl.glAttachShader(shader_program, vs);
    gl.glLinkProgram(shader_program);

    while (glfw3.glfwWindowShouldClose(window) == 0) {
        update_fps_counter(window);

        gl.glClear(gl.GL_COLOR_BUFFER_BIT | gl.GL_DEPTH_BUFFER_BIT);

        gl.glUseProgram(shader_program);
        gl.glBindVertexArray(vao);
        gl.glDrawArrays(gl.GL_TRIANGLES, 0, 3);

        glfw3.glfwSwapBuffers(window);
        glfw3.glfwPollEvents();
        if (glfw3.GLFW_PRESS == glfw3.glfwGetKey(window, glfw3.GLFW_KEY_Q)) {
            glfw3.glfwSetWindowShouldClose(window, 1);
        }
    }
}

fn glfw_error_callback(err: c_int, description: [*c]const u8) callconv(.c) void {
    std.log.err("GLFW ERROR: code {d}, msg: {s}", .{ err, description });
}

fn log_gl_params() void {
    const params = [_]gl.GLenum{
        gl.GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS,
        gl.GL_MAX_CUBE_MAP_TEXTURE_SIZE,
        gl.GL_MAX_DRAW_BUFFERS,
        gl.GL_MAX_FRAGMENT_UNIFORM_COMPONENTS,
        gl.GL_MAX_TEXTURE_IMAGE_UNITS,
        gl.GL_MAX_TEXTURE_SIZE,
        // gl.GL_MAX_VARYING_FLOATS,
        gl.GL_MAX_VERTEX_ATTRIBS,
        gl.GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS,
        gl.GL_MAX_VERTEX_UNIFORM_COMPONENTS,
        gl.GL_MAX_VIEWPORT_DIMS,
        gl.GL_STEREO,
    };
    const names = [_][]const u8{
        "GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS",
        "GL_MAX_CUBE_MAP_TEXTURE_SIZE",
        "GL_MAX_DRAW_BUFFERS",
        "GL_MAX_FRAGMENT_UNIFORM_COMPONENTS",
        "GL_MAX_TEXTURE_IMAGE_UNITS",
        "GL_MAX_TEXTURE_SIZE",
        // "GL_MAX_VARYING_FLOATS",
        "GL_MAX_VERTEX_ATTRIBS",
        "GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS",
        "GL_MAX_VERTEX_UNIFORM_COMPONENTS",
        "GL_MAX_VIEWPORT_DIMS",
        "GL_STEREO",
    };
    std.log.info("GL Context Params:", .{});
    // integers - only works if the order is 0-10 integer return types
    for (0..9) |i| {
        var v: c_int = 0;
        gl.glGetIntegerv(params[i], &v);
        std.log.info("{s} {d}", .{ names[i], v });
    }
    // others
    var v = [2]c_int{ 0, 0 };
    gl.glGetIntegerv(params[9], &v);
    std.log.info("{s} {d} {d}", .{ names[9], v[0], v[1] });

    var s: u8 = 0;
    gl.glGetBooleanv(params[10], &s);
    std.log.info("{s} {d}", .{ names[10], s });
    std.log.info("-----------------------------", .{});
}

fn update_fps_counter(window: ?*glfw3.GLFWwindow) void {
    const current_seconds = glfw3.glfwGetTime();
    const elapsed_seconds = current_seconds - g_previous_seconds;

    // limit text updates to 4 per second
    if (elapsed_seconds > 0.25) {
        g_previous_seconds = current_seconds;
        var buf: [128]u8 = undefined;
        const fps = @as(f64, @floatFromInt(g_frame_count)) / elapsed_seconds;
        const title = std.fmt.bufPrintZ(&buf, "napgl @ fps: {d:.2}", .{fps}) catch unreachable;
        glfw3.glfwSetWindowTitle(window, title.ptr);
        g_frame_count = 0;
    }

    g_frame_count += 1;
}
