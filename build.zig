const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const c_mod = b.addModule("c", .{
        .root_source_file = b.path("src/c.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    c_mod.addIncludePath(b.path("thirdparty/glfw-3.4.bin.MACOS/include"));
    c_mod.addIncludePath(b.path("thirdparty/glad/include"));
    c_mod.addCSourceFile(.{
        .file = b.path("thirdparty/glad/src/gl.c"),
    });
    c_mod.addObjectFile(b.path("thirdparty/glfw-3.4.bin.MACOS/lib-arm64/libglfw.3.dylib"));
    c_mod.addRPath(b.path("thirdparty/glfw-3.4.bin.MACOS/lib-arm64"));
    // c_mod.linkFramework("Cocoa", .{});
    // c_mod.linkFramework("IOKit", .{});

    const exe = b.addExecutable(.{
        .name = "napgl",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "c", .module = c_mod },
            },
        }),
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_exe_tests.step);
}
