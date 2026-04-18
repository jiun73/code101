const std = @import("std");
const llvm = @import("llvm");
const impl = @import("impl");

pub fn compile(gpa: std.mem.Allocator, progressNode: std.Progress.Node, source: []const u8) !llvm.Module {
    var tokens = try impl.Tokenizer.tokenize(gpa, progressNode, source);
    defer tokens.deinit(gpa);
    const emitNode = progressNode.start("LLVM Emit IR", tokens.items.len);
    const module = llvm.Module.create("programme");
    var ctx = impl.Context.init(gpa, progressNode, source, module);
    try ctx.build(gpa, tokens.items);
    ctx.deinit();
    emitNode.end();
    return module;
}

pub fn readFile(buffer: []u8, path: []const u8) ![]const u8 {
    return std.fs.cwd().readFile(path, buffer) catch |err| {
        switch (err) {
            error.FileNotFound => std.log.err("File not found", .{}),
            error.FileTooBig => std.log.err("File too big", .{}),
            else => std.log.err("Unhandled error", .{}),
        }
        return err;
    };
}

const buffer_size = 1024 * 1024;
var const_buffer: [buffer_size]u8 = [_]u8{undefined} ** buffer_size;

pub fn main() !void {
    var general_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = general_allocator.deinit();
    const gpa = general_allocator.allocator();

    const full_args = std.process.argsAlloc(gpa) catch @panic("OOM");
    defer std.process.argsFree(gpa, full_args);
    if (full_args.len == 0) return;
    var args = full_args[1..];

    std.log.info("code101", .{});

    var input_path_opt: ?[]const u8 = null;
    var output_path_opt: ?[]const u8 = null;
    var run: bool = false;
    var accept_input: bool = true;
    var consumed: usize = 0;

    while (args.len > 0) {
        if (std.mem.eql(u8, args[0], "run") and !run and consumed == 0) {
            llvm.linkInMCJIT();
            llvm.initializeNativeAsmPrinter();

            run = true;
            args = args[1..];
            consumed += 1;
            accept_input = true;
            continue;
        }

        if (std.mem.eql(u8, args[0], "-o")) {
            if (args.len < 2) {
                std.log.err("expected output argument", .{});
                return;
            }

            output_path_opt = args[1];
            args = args[2..];
            consumed += 2;
            accept_input = false;
            continue;
        }

        if (accept_input) {
            input_path_opt = args[0];
            accept_input = false;
        } else {
            std.log.err("invalid argument", .{});
            return;
        }

        args = args[1..];
        consumed += 1;
    }

    const input_path = input_path_opt orelse {
        std.log.err("no input specified. exiting.", .{});
        return;
    };

    if (output_path_opt == null) {
        std.log.info("no output specified. using default output", .{});
    }

    const output_path = if (output_path_opt != null) output_path_opt.? else "output.ll";

    llvm.initializeNativeTarget();
    llvm.initializeAllTargetInfos();
    llvm.initializeNativeAsmParser();

    const progressNode = std.Progress.start(.{ .root_name = "Compilation" });

    const source = try readFile(&const_buffer, input_path);
    const module = try compile(gpa, progressNode, source);

    if (run) {
        const exec = llvm.ExecutionEngine.createForModule(module);
        const main_fn = exec.findFunction("main");
        _ = exec.runFunctionAsMain(main_fn, 0, &.{});
    } else {
        const out_nt = gpa.dupeZ(u8, output_path) catch @panic("OOM");
        module.printToFile(out_nt);
        gpa.free(out_nt);
    }
}
