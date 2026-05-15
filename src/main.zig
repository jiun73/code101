const std = @import("std");
const zllvm = @import("zllvm");
const impl = @import("impl");

// Déclaration de la structure d'options globale pour le package root
pub const std_options: std.Options = .{
    .logFn = myLogFn,
};

// Fonction de journalisation personnalisée compatible Zig 0.15.2
fn myLogFn(
    comptime level: std.log.Level,
    comptime scope: @Type(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    _ = level;
    _ = scope;

    // 1. Ouvrir le fichier de sortie d'erreur standard via le descripteur brut POSIX
    const file = std.fs.File{ .handle = std.posix.STDERR_FILENO };

    // 2. Passer obligatoirement un tampon à la fonction writer()
    // Ici, un tableau vide '&.{}' désactive la mise en tampon pour envoyer le texte immédiatement
    var file_writer = file.writer(&.{});

    // 3. Utiliser le champ '.interface' pour accéder à la méthode print
    file_writer.interface.print(format, args) catch {
        return;
    };
}

pub fn compile(gpa: std.mem.Allocator, progressNode: std.Progress.Node, source: []const u8) !zllvm.Module {
    var tokens = try impl.Tokenizer.tokenize(gpa, progressNode, source);
    defer tokens.deinit(gpa);
    const emitNode = progressNode.start("LLVM Emit IR", tokens.items.len);
    const module = zllvm.Module.create("programme");
    var ctx = impl.Context.init(gpa, progressNode, source, module);
    defer ctx.deinit();
    try ctx.build(gpa, tokens.items);
    emitNode.end();
    return module;
}

pub fn readFile(buffer: []u8, path: []const u8) ![]const u8 {
    return std.fs.cwd().readFile(path, buffer);
}

pub fn toAsm(module: zllvm.Module, output: [:0]const u8) void {
    const triple = zllvm.TargetMachine.getDefaultTargetTriple();
    defer zllvm.disposeMessage(triple); // Libération requise par LLVM

    const trg = zllvm.Target.getFromTriple(triple);

    const cpu = zllvm.TargetMachine.getHostCPUName();
    defer zllvm.disposeMessage(cpu); // Libération requise par LLVM

    const cpu_features = zllvm.TargetMachine.getHostCPUFeatures();
    defer zllvm.disposeMessage(cpu_features); // Libération requise par LLVM

    const target_machine = zllvm.TargetMachine.create(trg, triple, cpu, cpu_features, .LLVMCodeGenLevelNone, .LLVMRelocPIC, .LLVMCodeModelDefault);
    defer target_machine.dispose(); // Ne pas oublier de détruire la machine cible

    // Correction : Utilisation du pointeur brut (.ptr) pour l'interopérabilité C
    // Note : Selon l'implémentation de zllvm, EmitToFile peut renvoyer un booléen d'erreur à vérifier
    _ = target_machine.EmitToFile(module, output, .LLVMObjectFile);

    // Note de logique LLVM : Un PassManager vide exécuté APRÈS l'émission du fichier
    // n'a aucun effet et peut causer un comportement indéfini si le module a été altéré.
    const pm = zllvm.PassManager.create();
    defer pm.dispose();
    _ = pm.run(module);
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

    std.log.info("code101\n", .{});
    //std.log.info("LLVM: {}", .{zllvm.getVersion()});

    var input_path_opt: ?[]const u8 = null;
    var output_path_opt: ?[]const u8 = null;
    var run: bool = false;
    var llvm: bool = false;
    var accept_input: bool = true;
    var consumed: usize = 0;

    while (args.len > 0) {
        if (std.mem.eql(u8, args[0], "rouler") and !run and consumed == 0) {
            zllvm.linkInMCJIT();
            zllvm.initializeNativeAsmPrinter();

            run = true;
            args = args[1..];
            consumed += 1;
            accept_input = true;
            continue;
        }

        if (std.mem.eql(u8, args[0], "-s")) {
            if (args.len < 2) {
                std.log.err("argument de sortie attendu\n", .{});
                return;
            }

            output_path_opt = args[1];
            args = args[2..];
            consumed += 2;
            accept_input = false;
            continue;
        }

        if (std.mem.eql(u8, args[0], "--arbre")) {
            impl.log.setLogTy(.Tree);
            args = args[1..];
            consumed += 1;
            continue;
        }

        if (std.mem.eql(u8, args[0], "--llvm") and !run) {
            llvm = true;
            args = args[1..];
            consumed += 1;
            continue;
        }

        if (std.mem.eql(u8, args[0][0..3], "--V")) {
            const flags = args[0][3..];
            for (flags) |c| {
                switch (c) {
                    'c' => impl.log.setLogTy(.Building),
                    'o' => impl.log.setLogTy(.Ops),
                    'm' => impl.log.setLogTy(.Matching),
                    'M' => impl.log.setLogTy(.MatchingVerbose),
                    's' => impl.log.setLogTy(.Scopes),
                    'j' => impl.log.setLogTy(.Tokenize),
                    else => {
                        std.log.err("argument invalide\n", .{});
                        return;
                    },
                }
            }

            args = args[1..];
            consumed += 1;
            continue;
        }

        if (accept_input) {
            input_path_opt = args[0];
            accept_input = false;
        } else {
            std.log.err("argument invalide\n", .{});
            return;
        }

        args = args[1..];
        consumed += 1;
    }

    const input_path = input_path_opt orelse {
        std.log.err("aucune entrée fournie. fin du programme.\n", .{});
        return;
    };

    var output_path = if (output_path_opt != null) output_path_opt.? else "sortie";

    zllvm.initializeNativeTarget();
    zllvm.initializeAllTargetInfos();
    zllvm.initializeNativeAsmParser();

    const progressNode = std.Progress.start(.{ .root_name = "Compilation" });

    const source = readFile(&const_buffer, input_path) catch |err| {
        switch (err) {
            error.IsDir => std.log.err("Le chemin fourni est un dossier\n", .{}),
            error.FileTooBig => std.log.err("Fichier trop volumineux!\n", .{}),
            error.FileNotFound => std.log.err("Fichier inexistant!\n", .{}),
            else => std.log.err("Erreur inattendue pendant la lecture du fichier\n", .{}),
        }
        return;
    };
    const module = compile(gpa, progressNode, source) catch |err| {
        switch (err) {
            error.DoesNotMatch => std.log.err("Erreur de syntaxe!\n", .{}),
            else => std.log.err("Erreur de compilation\n", .{}),
        }
        return;
    };

    std.log.info("compilation effectué avec succès\n", .{});

    if (run) {
        std.log.info("liaison de la librarie espeak\n", .{});
        _ = zllvm.support.LLVMLoadLibraryPermanently(null);
        try zllvm.loadLibraryPermanently("libespeak-ng.so");

        const file = @embedFile("code101_lib");
        const espeak_bds = try zllvm.parseBc(.fromSlice(file, "lib.bc"));
        try module.link(espeak_bds);
        std.log.info("création de l'engin d'éxécution\n", .{});
        const exec = try zllvm.ExecutionEngine.createMCJITForModule(module);
        //exec.runStaticConstructors();
        const main_fn = exec.findFunction("main");
        std.log.info("exécution...\n\n", .{});
        _ = exec.runFunctionAsMain(main_fn, 0, &.{});
    } else {
        if (output_path_opt == null) {
            output_path = if (llvm) "sortie.ll" else "sortie.o";
            std.log.info("chemin de sortie non spécifié. utilisation de la sortie par défaut\n", .{});
        }
        const out_nt = gpa.dupeZ(u8, output_path) catch @panic("OOM");
        if (llvm) {
            module.printToFile(out_nt);
        } else {
            const file = @embedFile("code101_lib");
            const espeak_bds = try zllvm.parseBc(.fromSlice(file, "lib.bc"));
            try module.link(espeak_bds);
            zllvm.initializeNativeAsmPrinter();
            toAsm(module, out_nt);
            std.log.info("fichier object créé\n", .{});
            std.log.info("'clang sortie.o -lespeak-ng -lm -o sortie.exe' pour créer un exécutable\n", .{});
        }
        gpa.free(out_nt);
    }
}
