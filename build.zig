const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "tetris",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    exe.linkLibC();

    if (target.result.os.tag == .windows) {
        exe.addIncludePath(.{ .cwd_relative = "C:/raylib/include" });
        exe.addLibraryPath(.{ .cwd_relative = "C:/raylib/lib" });
        exe.linkSystemLibrary("raylib");
        exe.linkSystemLibrary("winmm");
        exe.linkSystemLibrary("gdi32");
        exe.linkSystemLibrary("opengl32");
    } else if (target.result.os.tag == .linux) {
        exe.linkSystemLibrary("raylib");
        exe.linkSystemLibrary("m");
        exe.linkSystemLibrary("dl");
        exe.linkSystemLibrary("pthread");
        exe.linkSystemLibrary("rt");
        exe.linkSystemLibrary("X11");
    } else {
        exe.addIncludePath(.{ .cwd_relative = "/opt/homebrew/opt/raylib/include" });
        exe.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/opt/raylib/lib" });
        exe.linkSystemLibrary("raylib");
        exe.linkFramework("Cocoa");
        exe.linkFramework("CoreFoundation");
        exe.linkFramework("CoreGraphics");
        exe.linkFramework("CoreVideo");
        exe.linkFramework("IOKit");
        exe.linkFramework("OpenGL");
        exe.linkFramework("Carbon");
    }

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the game");
    run_step.dependOn(&run_cmd.step);
}
