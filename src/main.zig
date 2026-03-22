const std = @import("std");
const glfw3 = @import("c").glfw3;
const gl = @import("c").gl;
const Vec3 = @import("Vec3.zig");
const Vec4 = @import("Vec4.zig");
const Mat4 = @import("Mat4.zig");
const Camera = @import("Camera.zig");
const control = @import("control.zig");
const Cube = @import("Cube.zig");
const Tile = @import("Tile.zig");

const degree_in_rad: f32 = std.math.pi / 180.0;
const world_up = Vec3.init(0, 1, 0);

var g_previous_seconds: f64 = 0;
var g_fps_seconds: f64 = 0;
var g_frame_count: u64 = 0;

var g_mouse_x: f64 = 0;
var g_mouse_y: f64 = 0;

const vertex_shader = @embedFile("shaders/default.vert");
const fragment_shader = @embedFile("shaders/default.frag");

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

    const width = 640;
    const height = 480;
    const aspect = @as(f32, @floatFromInt(width)) / @as(f32, @floatFromInt(height));
    const window = glfw3.glfwCreateWindow(width, height, "napgl", null, null);
    if (window == null) {
        std.log.err("glfwCreateWindow failed", .{});
        return;
    }
    glfw3.glfwMakeContextCurrent(window);
    _ = glfw3.glfwSetCursorPosCallback(window, cursor_pos_callback);

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

    const vs = try compile_shader(gl.GL_VERTEX_SHADER, vertex_shader);
    const fs = try compile_shader(gl.GL_FRAGMENT_SHADER, fragment_shader);
    const shader_program = try link_program(vs, fs);
    const world_location = gl.glGetUniformLocation(shader_program, "world");
    const view_location = gl.glGetUniformLocation(shader_program, "view");
    const proj_location = gl.glGetUniformLocation(shader_program, "proj");
    const color_location = gl.glGetAttribLocation(shader_program, "vertex_color");

    const cube = Cube.init();
    const cube_world = Mat4.translate(Vec3.init(0, 0.5, 1));

    const plane = Plane.init(world_location, color_location);

    var cam = Camera.init(Vec3.init(0, 2, 5));
    var view = cam.view_matrix();
    const proj = Mat4.perspective(67.0 * degree_in_rad, aspect, 0.1, 100.0);

    while (glfw3.glfwWindowShouldClose(window) == 0) {
        const elapsed_seconds = get_elapsed_seconds();
        update_fps_counter(window);

        gl.glClear(gl.GL_COLOR_BUFFER_BIT | gl.GL_DEPTH_BUFFER_BIT);

        gl.glUseProgram(shader_program);
        gl.glUniformMatrix4fv(view_location, 1, gl.GL_FALSE, &view.arr);
        gl.glUniformMatrix4fv(proj_location, 1, gl.GL_FALSE, &proj.arr);

        // ray-plane intersection (y = 0)
        const hover_pos: ?Vec3 = blk: {
            const ray = screen_to_world_ray(
                g_mouse_x,
                g_mouse_y,
                width,
                height,
                proj,
                view,
            ) orelse break :blk null;

            const b = Vec3.dot(ray, world_up);
            if (@abs(b) < 1e-10) break :blk null;

            const a = Vec3.dot(cam.pos, world_up);
            const t = -a / b;
            if (t < 0) break :blk null;

            break :blk cam.pos.add(ray.scale(t));
        };

        // cube
        gl.glUniformMatrix4fv(world_location, 1, gl.GL_FALSE, &cube_world.arr);
        cube.draw();
        // plane
        plane.draw(hover_pos);

        glfw3.glfwSwapBuffers(window);
        glfw3.glfwPollEvents();

        if (glfw3.GLFW_PRESS == glfw3.glfwGetKey(window, glfw3.GLFW_KEY_Q)) {
            glfw3.glfwSetWindowShouldClose(window, 1);
            continue;
        }

        var cam_moved = false;
        inline for (control.key_map) |binding| {
            if (glfw3.GLFW_PRESS == glfw3.glfwGetKey(window, binding.glfw_key)) {
                cam.on_key(binding.key, elapsed_seconds);
                cam_moved = true;
            }
        }

        if (cam_moved) {
            view = cam.view_matrix();
        }
    }
}

/// Convert screen-space mouse coordinates to a normalized world-space ray direction.
/// Returns null if the projection or view matrix is singular.
fn screen_to_world_ray(mouse_x: f64, mouse_y: f64, vp_width: u32, vp_height: u32, proj: Mat4, view: Mat4) ?Vec3 {
    const w: f64 = @floatFromInt(vp_width);
    const h: f64 = @floatFromInt(vp_height);

    if (mouse_x < 0 or mouse_x >= w or mouse_y < 0 or mouse_y >= h) {
        return null;
    }

    // 1. Pixel → NDC  (y flipped: screen top = +1)
    const ndc_x: f32 = @floatCast((2.0 * mouse_x) / w - 1.0);
    const ndc_y: f32 = @floatCast(1.0 - (2.0 * mouse_y) / h);

    // 2. NDC → clip space (point on the near plane, w = 1)
    const clip = Vec4.init(ndc_x, ndc_y, -1.0, 1.0);

    // 3. Clip → eye space
    const inv_proj = proj.inverse() orelse return null;
    const eye = inv_proj.mul_vec4(clip);
    // We only care about the direction, so set z = -1 (into the screen) and w = 0
    const eye_ray = Vec4.init(eye.x, eye.y, -1.0, 0.0);

    // 4. Eye → world space
    const inv_view = view.inverse() orelse return null;
    const world = inv_view.mul_vec4(eye_ray);

    return Vec3.init(world.x, world.y, world.z).normalize();
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

fn cursor_pos_callback(_: ?*glfw3.GLFWwindow, xpos: f64, ypos: f64) callconv(.c) void {
    g_mouse_x = xpos;
    g_mouse_y = ypos;
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

fn get_elapsed_seconds() f32 {
    const current_seconds = glfw3.glfwGetTime();
    const elapsed_seconds = current_seconds - g_previous_seconds;
    g_previous_seconds = current_seconds;
    g_fps_seconds += elapsed_seconds;
    return @floatCast(elapsed_seconds);
}

fn update_fps_counter(window: ?*glfw3.GLFWwindow) void {
    // limit text updates to 4 per second
    if (g_fps_seconds > 0.25) {
        var buf: [128]u8 = undefined;
        const fps = @as(f64, @floatFromInt(g_frame_count)) / g_fps_seconds;
        const title = std.fmt.bufPrintZ(&buf, "napgl @ fps: {d:.2}", .{fps}) catch unreachable;
        glfw3.glfwSetWindowTitle(window, title.ptr);
        g_frame_count = 0;
        g_fps_seconds = 0;
    }

    g_frame_count += 1;
}

const Plane = struct {
    const half_size = 10;
    const gray = [3]f32{ 0.5, 0.5, 0.5 };
    const light_yellow = [3]f32{ 1.0, 1.0, 0.8 };
    const red = [3]f32{ 1.0, 0.3, 0.3 };

    tile: Tile,
    world_location: gl.GLint,
    color_location: gl.GLint,

    fn init(world_location: gl.GLint, color_location: gl.GLint) Plane {
        return .{
            .tile = Tile.init(),
            .world_location = world_location,
            .color_location = color_location,
        };
    }

    fn draw(self: Plane, hover_pos: ?Vec3) void {
        var iz: i32 = -half_size;
        while (iz < half_size) : (iz += 1) {
            var ix: i32 = -half_size;
            while (ix < half_size) : (ix += 1) {
                const tile_world = Mat4.translate(Vec3.init(
                    @floatFromInt(ix),
                    0,
                    @floatFromInt(iz),
                ));
                gl.glUniformMatrix4fv(self.world_location, 1, gl.GL_FALSE, &tile_world.arr);
                const color = if (is_hover(ix, iz, hover_pos)) red else checker_color(ix, iz);
                gl.glVertexAttrib3f(@intCast(self.color_location), color[0], color[1], color[2]);
                self.tile.draw();
            }
        }
    }

    fn is_hover(ix: isize, iz: isize, hover_pos: ?Vec3) bool {
        if (hover_pos) |pos| {
            return ix == @as(i32, @intFromFloat(@floor(pos.x))) and
                iz == @as(i32, @intFromFloat(@floor(pos.z)));
        }

        return false;
    }

    fn checker_color(ix: i32, iz: i32) [3]f32 {
        return if (@mod(ix + iz, 2) == 0) gray else light_yellow;
    }
};
