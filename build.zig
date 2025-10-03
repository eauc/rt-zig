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
        .{
            .name = "light_shading",
            .desc = "Example: light and shading",
            .path = "examples/light_shading.zig",
        },
        .{
            .name = "spheres_scene",
            .desc = "Example: scene done with only spheres",
            .path = "examples/spheres_scene.zig",
        },
        .{
            .name = "spheres_planes",
            .desc = "Example: scene done with spheres and planes",
            .path = "examples/spheres_planes.zig",
        },
        .{
            .name = "patterns",
            .desc = "Example: patterns",
            .path = "examples/patterns.zig",
        },
        .{
            .name = "reflection",
            .desc = "Example: reflection",
            .path = "examples/reflection.zig",
        },
        .{
            .name = "refraction",
            .desc = "Example: refraction",
            .path = "examples/refraction.zig",
        },
        .{
            .name = "cubes",
            .desc = "Example: cubes",
            .path = "examples/cubes.zig",
        },
        .{
            .name = "cylinders",
            .desc = "Example: cylinders",
            .path = "examples/cylinders.zig",
        },
        .{
            .name = "cones",
            .desc = "Example: cones",
            .path = "examples/cones.zig",
        },
        .{
            .name = "hexagon",
            .desc = "Example: hexagon",
            .path = "examples/hexagon.zig",
        },
        .{
            .name = "teapot_obj",
            .desc = "Example: teapot OBJ file",
            .path = "examples/teapot_obj.zig",
        },
        .{
            .name = "csg",
            .desc = "Example: csg",
            .path = "examples/csg.zig",
        },
        .{
            .name = "lights",
            .desc = "Example: lights",
            .path = "examples/lights.zig",
        },
        .{
            .name = "cube_light",
            .desc = "Example: cube light",
            .path = "examples/cube_light.zig",
        },
        .{
            .name = "sphere_light",
            .desc = "Example: sphere light",
            .path = "examples/sphere_light.zig",
        },
        .{
            .name = "spot_light",
            .desc = "Example: spot light",
            .path = "examples/spot_light.zig",
        },
        .{
            .name = "blur",
            .desc = "Example: blur effect",
            .path = "examples/blur.zig",
        },
        .{
            .name = "cover",
            .desc = "Example: cover",
            .path = "examples/cover.zig",
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
        const run_cmd = b.addRunArtifact(exe);

        const run_step = b.step(example.name, example.desc);
        run_step.dependOn(&run_cmd.step);

        examples_step.dependOn(&run_cmd.step);
    }
}
