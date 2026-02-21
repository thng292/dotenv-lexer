const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const dynamic = b.option(bool, "dynamic", "Build this library as a dynamic lib.") orelse false;

    const mod = b.addModule("dotenv_parser", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addLibrary(.{
        .name = "dotenv-parser",
        .root_module = mod,
        .use_llvm = true,
        .linkage = if (dynamic) .dynamic else .static,
    });
    lib.installHeadersDirectory(b.path("src/include/"), "", .{});
    const lib_install_artifact = b.addInstallArtifact(lib, .{});
    b.getInstallStep().dependOn(&lib_install_artifact.step);

    const mod_tests = b.addTest(.{
        .root_module = mod,
        .use_llvm = true,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&b.addInstallArtifact(mod_tests, .{}).step);

    const fmt_step = b.step("fmt", "Check formatting");

    const fmt = b.addFmt(.{
        .paths = &.{
            "src/",
            "build.zig",
            "build.zig.zon",
        },
    });

    fmt_step.dependOn(&fmt.step);

    // c Example
    const c_examples = b.step("c-examples", "Build the C examples");
    const c_examples_path = [_][]const u8{
        "c-test-program",
    };
    for (c_examples_path) |path| {
        const main_mod = b.addModule(path, .{
            .link_libc = true,
            .optimize = optimize,
            .target = target,
        });
        main_mod.addCSourceFile(.{
            .file = b.path(b.pathJoin(&.{ "examples/", path, "main.c" })),
            .language = .c,
        });
        main_mod.linkLibrary(lib);
        const example_exe = b.addExecutable(.{
            .name = path,
            .root_module = main_mod,
        });
        example_exe.step.dependOn(&lib_install_artifact.step);
        const install_step = b.addInstallArtifact(example_exe, .{});
        c_examples.dependOn(&install_step.step);
    }
}
