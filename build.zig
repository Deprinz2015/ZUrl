const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const httpz = b.dependency("httpz", .{ .target = target, .optimize = .ReleaseSafe });
    const zli = b.dependency("zli", .{ .target = target, .optimize = .ReleaseSafe });

    const exe = b.addExecutable(.{
        .name = "zurl",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("httpz", httpz.module("httpz"));
    exe.root_module.addImport("Zli", zli.module("Zli"));
    exe.linkLibC();
    exe.addCSourceFile(.{ .file = b.path("lib/sqlite3.c") });
    exe.addIncludePath(b.path("lib"));

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Check step for better lsp diagnostics
    const exe_check = b.addExecutable(.{
        .name = "zurl",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = .Debug,
    });
    exe_check.root_module.addImport("httpz", httpz.module("httpz"));
    exe_check.root_module.addImport("Zli", zli.module("Zli"));
    exe_check.linkLibC();
    exe_check.addCSourceFile(.{ .file = b.path("lib/sqlite3.c") });
    exe_check.addIncludePath(b.path("lib"));

    const check = b.step("check", "Check if compiles");
    check.dependOn(&exe_check.step);
}
