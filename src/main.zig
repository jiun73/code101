const std = @import("std");
const llvm = @import("llvm");
const impl = @import("impl");

pub fn compile(gpa: std.mem.Allocator, progressNode: std.Progress.Node, source: []const u8) !llvm.Module {
    var tokens = try impl.Tokenizer.tokenize(gpa, progressNode, source);
    defer tokens.deinit(gpa);
    const emitNode = progressNode.start("LLVM Emit IR", tokens.items.len);
    const module = llvm.Module.create("programme");
    var ctx = impl.Context.init(gpa, progressNode, source, module);
    defer ctx.deinit();
    try ctx.build(gpa, tokens.items);
    emitNode.end();
    return module;
}

pub fn readFile(buffer: []u8, path: []const u8) ![]const u8 {
    return std.fs.cwd().readFile(path, buffer) catch |err| {
        switch (err) {
            error.FileNotFound => std.log.err("Fichier introuvable", .{}),
            error.FileTooBig => std.log.err("Fichier trop volumineux", .{}),
            else => std.log.err("Erreur inattendu", .{}),
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
        if (std.mem.eql(u8, args[0], "rouler") and !run and consumed == 0) {
            llvm.linkInMCJIT();
            llvm.initializeNativeAsmPrinter();

            run = true;
            args = args[1..];
            consumed += 1;
            accept_input = true;
            continue;
        }

        if (std.mem.eql(u8, args[0], "-s")) {
            if (args.len < 2) {
                std.log.err("argument de sortie attendu", .{});
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
            std.log.err("argument invalide", .{});
            return;
        }

        args = args[1..];
        consumed += 1;
    }

    const input_path = input_path_opt orelse {
        std.log.err("aucune entrée fournie. fin du programme.", .{});
        return;
    };

    const output_path = if (output_path_opt != null) output_path_opt.? else "sortie.ll";

    llvm.initializeNativeTarget();
    llvm.initializeAllTargetInfos();
    llvm.initializeNativeAsmParser();

    const progressNode = std.Progress.start(.{ .root_name = "Compilation" });

    const source = try readFile(&const_buffer, input_path);
    const module = try compile(gpa, progressNode, source);

    std.log.info("compilation effectué avec succès", .{});

    if (run) {
        std.log.info("liaison de la librarie espeak", .{});
        try llvm.loadLibraryPermanently("libespeak-ng.so");

        const file = @embedFile("test-espeak.ll");

        const espeak_bds = try llvm.parseIrInContext(module.getContext(), .fromSlice(file, "test-espeak.ll"));
        try module.link(espeak_bds);
        std.log.info("création de l'engin d'éxécution", .{});
        const exec = try llvm.ExecutionEngine.createForModule(module);
        const main_fn = exec.findFunction("main");
        std.log.info("exécution...", .{});
        _ = exec.runFunctionAsMain(main_fn, 0, &.{});
    } else {
        if (output_path_opt == null) {
            std.log.info("chemin de sortie non spécifié. utilisation de la sortie par défaut", .{});
        }
        const out_nt = gpa.dupeZ(u8, output_path) catch @panic("OOM");
        module.printToFile(out_nt);
        gpa.free(out_nt);
    }
}
