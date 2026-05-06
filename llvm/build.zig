const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

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
        .linux => llvm_module.linkSystemLibrary("LLVM-20", .{}), // Ubuntu
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
        .linux => clang_module.linkSystemLibrary("clang-20", .{}), // Ubuntu
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
