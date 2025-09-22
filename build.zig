const std = @import("std");

const Example = struct {
    name: []const u8,
    desc: []const u8,
    path: []const u8,
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("rt_zig", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });
    const run_mod_tests = b.addRunArtifact(mod_tests);

    const install_docs = b.addInstallDirectory(.{
        .source_dir = mod_tests.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&install_docs.step);

    const examples_step = b.step("examples", "Run all examples");

    const examples = [_]Example{
        .{
            .name = "ray_sphere",
            .desc = "Example: ray sphere intersection",
            .path = "examples/ray_sphere.zig",
        },
    };

    for (examples) |example| {
        const root_mod = b.createModule(.{
            .root_source_file = b.path(example.path),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "rt_zig", .module = mod },
            },
        });
        const exe = b.addExecutable(.{
            .name = example.name,
            .root_module = root_mod,
        });
        b.installArtifact(exe);

        const run_step = b.step(example.name, example.desc);

        const run_cmd = b.addRunArtifact(exe);
        run_step.dependOn(&run_cmd.step);
        examples_step.dependOn(&run_cmd.step);

        run_cmd.step.dependOn(b.getInstallStep());
    }
}
