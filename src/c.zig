pub const gl = @cImport({
    @cInclude("glad/gl.h");
});

pub const glfw3 = @cImport({
    @cDefine("GLFW_INCLUDE_NONE", {});
    @cInclude("GLFW/glfw3.h");
});
