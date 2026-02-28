const std = @import("std");
const SyntaxTreeNode = @import("SyntaxTreeNode.zig");
const fns = @import("fns.zig");
const nodes = @import("nodes.zig");
const Context = @import("Context.zig");
const Tokenizer = @import("Tokenizer.zig");
const ex = @import("ex.zig");

pub fn processFileContents(gpa: std.mem.Allocator, file: []const u8) !void {
    const progressNode = std.Progress.start(.{ .root_name = "Compilation" });

    var ctx = Context.init(gpa, progressNode);
    var tokens = std.ArrayList([]const u8).initCapacity(gpa, 128) catch @panic("OOM");
    defer tokens.deinit(gpa);
    defer ctx.deinit();

    const tkNode = progressNode.start("Tokenize", file.len);

    try Tokenizer.tokenize(tkNode, file, &tokens, gpa);

    tkNode.end();

    const emitNode = progressNode.start("LLVM Emit IR", tokens.items.len);

    try ctx.traverseNodes(nodes.masterNode, tokens.items, gpa);

    emitNode.end();

    ctx.module.printToFile("output.ll");
    //ctx.toAsm();

    var child = std.process.Child.init(&.{ "clang", "output.ll", "-o", "output" }, gpa);
    _ = child.spawnAndWait() catch @panic("");

    var child2 = std.process.Child.init(&.{"./output"}, gpa);
    _ = child2.spawnAndWait() catch @panic("");
}

pub fn compile(path: [:0]const u8) !void {
    var general_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = general_allocator.deinit();
    const gpa = general_allocator.allocator();

    const max_file_size = 1024 * 1024; // 1 MB

    const file_err = std.fs.cwd().readFileAlloc(gpa, path, max_file_size);

    if (file_err) |file| {
        defer gpa.free(file); // Remember to free the allocated memory
        try processFileContents(gpa, file);
    } else |err| switch (err) {
        error.FileNotFound => {
            std.log.err("File not found", .{});
            return err;
        },
        error.FileTooBig => {
            std.log.err("File too big. 1mb max per file", .{});
            return err;
        },
        else => {
            std.log.err("Unhandled error", .{});
            return err;
        },
    }
}

pub fn main() !void {
    //ex.e();
    var general_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = general_allocator.deinit();
    const gpa = general_allocator.allocator();

    const args = std.process.argsAlloc(gpa) catch return;
    defer std.process.argsFree(gpa, args);

    std.log.info("code101", .{});

    if (args.len == 1) {
        std.log.err("no input specfied.", .{});
        return;
    } else if (args.len == 2) {
        std.log.info("no output specfied. using default output", .{});
        try compile(args[1]);
    }
}
