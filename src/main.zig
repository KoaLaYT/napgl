const std = @import("std");
const glfw3 = @import("c").glfw3;
const gl = @import("c").gl;

var g_previous_seconds: f64 = 0;
var g_frame_count: u64 = 0;

const vertex_shader = @embedFile("shaders/triangle.vert");
const fragment_shader = @embedFile("shaders/triangle.frag");

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
    gl.glEnable(gl.GL_CULL_FACE);
    gl.glCullFace(gl.GL_BACK);
    gl.glFrontFace(gl.GL_CW);

    const points = [_]f32{
        0.0,  0.5,  0.0,
        0.5,  -0.5, 0.0,
        -0.5, -0.5, 0.0,
    };

    const colors = [_]f32{
        1.0, 0.0, 0.0,
        0.0, 1.0, 0.0,
        0.0, 0.0, 1.0,
    };

    var points_vbo: gl.GLuint = 0;
    gl.glGenBuffers(1, &points_vbo);
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, points_vbo);
    gl.glBufferData(gl.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(points)), &points, gl.GL_STATIC_DRAW);

    var colors_vbo: gl.GLuint = 0;
    gl.glGenBuffers(1, &colors_vbo);
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, colors_vbo);
    gl.glBufferData(gl.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(colors)), &colors, gl.GL_STATIC_DRAW);

    var vao: gl.GLuint = 0;
    gl.glGenVertexArrays(1, &vao);
    gl.glBindVertexArray(vao);
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, points_vbo);
    gl.glVertexAttribPointer(0, 3, gl.GL_FLOAT, gl.GL_FALSE, 0, null);
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, colors_vbo);
    gl.glVertexAttribPointer(1, 3, gl.GL_FLOAT, gl.GL_FALSE, 0, null);
    gl.glEnableVertexAttribArray(0);
    gl.glEnableVertexAttribArray(1);

    const vs = try compile_shader(gl.GL_VERTEX_SHADER, vertex_shader);
    const fs = try compile_shader(gl.GL_FRAGMENT_SHADER, fragment_shader);
    const shader_program = try link_program(vs, fs);

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

fn compile_shader(typ: gl.GLenum, source: []const u8) !gl.GLuint {
    const shader_index = gl.glCreateShader(typ);
    gl.glShaderSource(shader_index, 1, @ptrCast(&source), null);
    gl.glCompileShader(shader_index);

    var params: c_int = -1;
    gl.glGetShaderiv(shader_index, gl.GL_COMPILE_STATUS, &params);
    if (gl.GL_TRUE != params) {
        std.log.err("ERROR: GL shader index {d} did not compile", .{shader_index});
        print_shader_info_log(shader_index);
        return error.CompileShaderFailed;
    }

    return shader_index;
}

fn link_program(vs: gl.GLuint, fs: gl.GLuint) !gl.GLuint {
    const shader_program = gl.glCreateProgram();
    gl.glAttachShader(shader_program, fs);
    gl.glAttachShader(shader_program, vs);
    gl.glLinkProgram(shader_program);

    var params: c_int = -1;
    gl.glGetProgramiv(shader_program, gl.GL_LINK_STATUS, &params);
    if (gl.GL_TRUE != params) {
        std.log.err("ERROR: could not link shader programme GL index {d}", .{shader_program});
        print_program_info_log(shader_program);
        return error.LinkProgramFailed;
    }

    return shader_program;
}

fn print_shader_info_log(shader_index: gl.GLuint) void {
    const max_length = 2048;
    var actual_length: gl.GLsizei = 0;
    var log: [2048]u8 = undefined;
    gl.glGetShaderInfoLog(shader_index, max_length, &actual_length, &log);
    std.log.err("shader info log for GL index {d}:\n{s}", .{ shader_index, log[0..@intCast(actual_length)] });
}

fn print_program_info_log(program: gl.GLuint) void {
    const max_length = 2048;
    var actual_length: gl.GLsizei = 0;
    var log: [2048]u8 = undefined;
    gl.glGetProgramInfoLog(program, max_length, &actual_length, &log);
    std.log.err("program info log for GL index {d}:\n{s}", .{ program, log[0..@intCast(actual_length)] });
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
