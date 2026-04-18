const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const llvm_dep = b.dependency("llvm", .{ .target = target, .optimize = optimize });
    const llvm_c_mod = llvm_dep.module("llvm");
    const clang_c_mod = llvm_dep.module("clang");

    const llvm_bds_mod = b.addModule("impl", .{
        .root_source_file = b.path("src/llvm/llvm.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "cllvm", .module = llvm_c_mod },
            .{ .name = "clang", .module = clang_c_mod },
        },
    });

    const impl_mod = b.addModule("impl", .{
        .root_source_file = b.path("src/impl/root.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "llvm", .module = llvm_bds_mod },
        },
    });

    const mod = b.addModule("code101", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "impl", .module = impl_mod },
            .{ .name = "llvm", .module = llvm_bds_mod },
        },
    });

    const exe = b.addExecutable(.{
        .name = "code101",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "code101", .module = mod },
                .{ .name = "llvm", .module = llvm_bds_mod },
                .{ .name = "impl", .module = impl_mod },
            },
        }),
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);

    // LLVM MODULE
    const llvm_module = b.addModule("llvm", .{
        .root_source_file = b.path("src/llvm-bindings.zig"),
        .target = target,
        .optimize = optimize,
    });

    llvm_module.addCMacro("_FILE_OFFSET_BITS", "64");
    llvm_module.addCMacro("__STDC_CONSTANT_MACROS", "");
    llvm_module.addCMacro("__STDC_FORMAT_MACROS", "");
    llvm_module.addCMacro("__STDC_LIMIT_MACROS", "");
    llvm_module.linkSystemLibrary("z", .{});

    if (target.result.abi != .msvc)
        llvm_module.link_libc = true
    else
        llvm_module.link_libcpp = true;

    switch (target.result.os.tag) {
        .linux => llvm_module.linkSystemLibrary("LLVM-19", .{}), // Ubuntu
        .macos => {
            llvm_module.addLibraryPath(.{
                .cwd_relative = "/opt/homebrew/opt/llvm/lib",
            });
            llvm_module.linkSystemLibrary("LLVM", .{
                .use_pkg_config = .no,
            });
        },
        else => llvm_module.linkSystemLibrary("LLVM", .{
            .use_pkg_config = .no,
        }),
    }

    // CLANG MODULE
    const clang_module = b.addModule("clang", .{
        .root_source_file = b.path("src/clang.zig"),
        .target = target,
        .optimize = optimize,
    });
    switch (target.result.os.tag) {
        .linux => clang_module.linkSystemLibrary("clang-19", .{}), // Ubuntu
        .macos => {
            clang_module.addLibraryPath(.{
                .cwd_relative = "/opt/homebrew/opt/llvm/lib",
            });
            clang_module.linkSystemLibrary("clang", .{
                .use_pkg_config = .no,
            });
        },
        else => clang_module.linkSystemLibrary("clang", .{
            .use_pkg_config = .no,
        }),
    }
    if (target.result.abi != .msvc)
        clang_module.link_libc = true
    else
        clang_module.link_libcpp = true;
}
