const std = @import("std");
const llvm = @import("llvm.zig");
const target = llvm.target;
const types = llvm.types;
const core = llvm.core;
const SyntaxTreeNode = @import("SyntaxTreeNode.zig");
const fns = @import("fns.zig");
const nodes = @import("nodes.zig");

const Context = @This();

progressNode: std.Progress.Node,
gpa: std.mem.Allocator,
module: llvm.Module,
builder: llvm.Builder,
counter: u32,

vars: std.StringHashMap(llvm.Value),

pub fn init(gpa: std.mem.Allocator, progressNode: std.Progress.Node) Context {
    llvm.initializeAllTargetInfos();
    llvm.initializeAllTargetMCs();
    llvm.initializeAllTargets();
    llvm.initializeNativeAsmParser();
    llvm.initializeNativeTarget();

    // Create a new LLVM module
    const module = llvm.Module.create("programme");
    const builder = llvm.Builder.create();

    _ = module.addFn("printf", .create(llvm.Type.Int8(), &.{llvm.Type.Int8().Ptr()}, true));

    const fmt_d = llvm.Value.constString("%d\n", false);
    _ = module.addGlobal(fmt_d.getType(), "fmt_d").setInitializer(fmt_d).setGlobalConstant(true).setLinkage(.LLVMInternalLinkage).setUnnamedAddr(true);

    const fmt_s = llvm.Value.constString("%s\n", false);
    _ = module.addGlobal(fmt_s.getType(), "fmt_s").setInitializer(fmt_s).setGlobalConstant(true).setLinkage(.LLVMInternalLinkage).setUnnamedAddr(true);

    const vars = std.StringHashMap(llvm.Value).init(gpa);

    return .{
        .progressNode = progressNode,
        .gpa = gpa,
        .counter = 0,
        .module = module,
        .builder = builder,
        .vars = vars,
    };
}

pub fn toAsm(builder: *Context) void {
    const triple = llvm.TargetMachine.getDefaultTargetTriple();
    const trg = llvm.Target.getFromTriple(triple);
    const cpu = llvm.TargetMachine.getHostCPUName();
    const cpu_features = llvm.TargetMachine.getHostCPUFeatures();

    const target_machine = llvm.TargetMachine.create(trg, triple, cpu, cpu_features, .LLVMCodeGenLevelNone, .LLVMRelocDefault, .LLVMCodeModelDefault);

    const pm = llvm.PassManager.create();
    const outfile = "output";

    target_machine.EmitToFile(builder.module, outfile, .LLVMAssemblyFile);
    pm.run(builder.module);
}

pub fn deinit(builder: *Context) void {
    builder.vars.deinit();
    builder.progressNode.end();
}

const CompilerError = error{ NoLbNextNode, InvalidStackPop };

fn printstack(loopbackStack: std.ArrayList(*const SyntaxTreeNode)) void {
    std.debug.print("stack:", .{});
    for (loopbackStack.items) |item| {
        std.debug.print("[{?s}]", .{item.debug});
    }
    std.debug.print("\n", .{});
}

pub fn traverseNodes(ctx: *Context, startNode: SyntaxTreeNode, startTokens: [][]const u8, gpa: std.mem.Allocator) !void {
    var tokens = startTokens;
    var currentNode: *const SyntaxTreeNode = &startNode;
    var loopbackStack = std.ArrayList(*const SyntaxTreeNode).initCapacity(gpa, 32) catch @panic("OOM");
    defer loopbackStack.deinit(gpa);

    mainloop: while (true) {
        if (currentNode.debug != null) {
            ctx.progressNode.setCompletedItems(tokens.len);
            //std.debug.print("current node: {s} ({any} tokens)\n", .{ currentNode.debug.?, tokens.len });
        }

        if (tokens.len == 0) {
            if (currentNode.loopback == .Master or currentNode.loopback == .End) {
                return;
            } else {
                return SyntaxTreeNode.MatchError.OutOfTokens;
            }
        }

        try switch (currentNode.loopback) {
            .Next => {
                //std.debug.print("lbnext:{?s} - ", .{currentNode.lbnext.?.debug});
                try loopbackStack.append(gpa, currentNode.lbnext orelse return CompilerError.NoLbNextNode);
                //printstack(loopbackStack);
            },
            .Self => {
                //std.debug.print("lb:{?s} - ", .{currentNode.debug});
                try loopbackStack.append(gpa, currentNode);
                //printstack(loopbackStack);
            },
            .Master => loopbackStack.append(gpa, currentNode),
            .Jump => {
                const last = loopbackStack.pop() orelse return CompilerError.InvalidStackPop;
                currentNode = last;
                //std.debug.print("jump => [{?s}] - ", .{currentNode.debug});
                //printstack(loopbackStack);
                continue :mainloop;
            },
            .JumpPrevious => {
                _ = loopbackStack.pop();
                currentNode = loopbackStack.pop() orelse return CompilerError.InvalidStackPop;
                //std.debug.print("popjump => [{?s}] - ", .{currentNode.debug});
                //printstack(loopbackStack);
                continue :mainloop;
            },
            .None => {},
            .End => {},
        };

        for (currentNode.next) |*next| {
            const result_err = next.*.isMatch(tokens);

            if (result_err) |result| {
                tokens = tokens[result.len..];
                currentNode = next;
                if (currentNode.build != null) {
                    currentNode.build.?(ctx, result);
                }
                continue :mainloop;
            } else |_| {
                //std.debug.print("checking next...\n", .{});
                continue;
            }
        }

        if (currentNode.debug != null) {
            std.debug.print("no match found for node {s}. exiting\n", .{currentNode.debug.?});
        }

        return SyntaxTreeNode.MatchError.DoesNotMatch;
    }
}
