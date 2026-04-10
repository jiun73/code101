const std = @import("std");
const llvm = @import("llvm.zig");
const target = llvm.target;
const types = llvm.types;
const core = llvm.core;
const SyntaxTreeNode = @import("SyntaxTreeNode.zig");
const fns = @import("fns.zig");
const nodes = @import("nodes.zig");

const Context = @This();

const ValOrRef = union(enum) {
    value: llvm.Value,
    ref: []const u8,

    pub fn getValue(vr: ValOrRef, ctx: *Context) llvm.Value {
        switch (vr) {
            .value => |val| return val,
            .ref => |ref| return ctx.getVar(ref),
        }
    }
};

const Op = enum { Add, Mul, Square, SquareRoot, None };

const VNode = struct {
    next: []const u8,
    build: ?SyntaxTreeNode.BuildFn = null,
    tokens: SyntaxTreeNode.TokenUsageType = .Current,
};

progressNode: std.Progress.Node,
gpa: std.mem.Allocator,
module: llvm.Module,
builder: llvm.Builder,
counter: u32,

vars: std.StringHashMap(llvm.Value),
varStack: std.ArrayList(ValOrRef),
opStack: std.ArrayList(Op),
result: ?llvm.Value,

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
    _ = module.addFn("llvm.sqrt.f64", .create(llvm.Type.Double(), &.{llvm.Type.Double()}, false));
    _ = module.addFn("llvm.cbrt.f64", .create(llvm.Type.Double(), &.{llvm.Type.Double()}, false));
    _ = module.addFn("llvm.pow.f64", .create(llvm.Type.Double(), &.{llvm.Type.Double()}, false));

    const fmt_d = llvm.Value.constString("%.2f\n", false);
    _ = module.addGlobal(fmt_d.getType(), "fmt_d").setInitializer(fmt_d).setGlobalConstant(true).setLinkage(.LLVMInternalLinkage).setUnnamedAddr(true);

    const fmt_s = llvm.Value.constString("%s\n", false);
    _ = module.addGlobal(fmt_s.getType(), "fmt_s").setInitializer(fmt_s).setGlobalConstant(true).setLinkage(.LLVMInternalLinkage).setUnnamedAddr(true);

    const vars = std.StringHashMap(llvm.Value).init(gpa);
    const varStack = std.ArrayList(ValOrRef).initCapacity(gpa, 32) catch @panic("OOM");
    const opStack = std.ArrayList(Op).initCapacity(gpa, 32) catch @panic("OOM");

    return .{
        .progressNode = progressNode,
        .gpa = gpa,
        .counter = 0,
        .module = module,
        .builder = builder,
        .vars = vars,
        .varStack = varStack,
        .opStack = opStack,
        .result = null,
    };
}

pub fn toAsm(ctx: *Context) void {
    const triple = llvm.TargetMachine.getDefaultTargetTriple();
    const trg = llvm.Target.getFromTriple(triple);
    const cpu = llvm.TargetMachine.getHostCPUName();
    const cpu_features = llvm.TargetMachine.getHostCPUFeatures();

    const target_machine = llvm.TargetMachine.create(trg, triple, cpu, cpu_features, .LLVMCodeGenLevelNone, .LLVMRelocDefault, .LLVMCodeModelDefault);

    const pm = llvm.PassManager.create();
    const outfile = "output";

    target_machine.EmitToFile(ctx.module, outfile, .LLVMAssemblyFile);
    pm.run(ctx.module);
}

pub fn deinit(ctx: *Context) void {
    ctx.vars.deinit();
    ctx.varStack.deinit(ctx.gpa);
    ctx.opStack.deinit(ctx.gpa);
    ctx.progressNode.end();
}

const CompilerError = error{ NoLbNextNode, InvalidStackPop };

fn printstack(loopbackStack: std.ArrayList(SyntaxTreeNode)) void {
    std.debug.print("stack:", .{});
    for (loopbackStack.items) |item| {
        std.debug.print("[{?s}]", .{item.debug});
    }
    std.debug.print("\n", .{});
}

pub fn traverseNodes(ctx: *Context, startNode: SyntaxTreeNode, startTokens: [][]const u8, gpa: std.mem.Allocator) !void {
    var tokens = startTokens;
    var currentNode: SyntaxTreeNode = startNode;
    var loopbackStack = std.ArrayList(SyntaxTreeNode).initCapacity(gpa, 32) catch @panic("OOM");
    defer loopbackStack.deinit(gpa);

    var savedTokensStack = std.ArrayList([][]const u8).initCapacity(gpa, 32) catch @panic("OOM");
    defer savedTokensStack.deinit(gpa);

    mainloop: while (true) {
        ctx.progressNode.setCompletedItems(tokens.len);
        if (currentNode.debug != null) {
            std.debug.print("current node: {s} ({any} tokens)\n", .{ currentNode.debug.?, tokens.len });
        }

        if (tokens.len == 0) {
            if (currentNode.loopback == .Master or currentNode.loopback == .End) {
                return;
            } else {
                return SyntaxTreeNode.MatchError.OutOfTokens;
            }
        }

        try switch (currentNode.loopback) {
            .After => {
                std.debug.print("after:{?s} - ", .{currentNode.debug});
                var copy = currentNode;
                copy.next = copy.after;
                copy.tokens = .Current;
                copy.debug = copy.debug_after;
                copy.loopback = .None;
                try loopbackStack.append(gpa, copy);
                printstack(loopbackStack);
            },
            .JumpAfter => {
                std.debug.print("jumpafter:{?s} - ", .{currentNode.debug});
                try loopbackStack.append(gpa, SyntaxTreeNode{
                    .next = &.{
                        SyntaxTreeNode{
                            .loopback = .Jump,
                            .build = currentNode.build_after,
                        },
                    },
                });
                printstack(loopbackStack);
            },
            .Self => {
                std.debug.print("self:{?s} - ", .{currentNode.debug});
                try loopbackStack.append(gpa, currentNode);
                printstack(loopbackStack);
            },
            .Master => loopbackStack.append(gpa, currentNode),
            .Jump => {
                const last = loopbackStack.pop() orelse return CompilerError.InvalidStackPop;
                currentNode = last;

                if (currentNode.loopback == .After) {
                    currentNode.next = currentNode.after;
                }
                std.debug.print("jump => [{?s}] - ", .{currentNode.debug});
                printstack(loopbackStack);
                continue :mainloop;
            },
            .JumpPrevious => {
                _ = loopbackStack.pop();
                currentNode = loopbackStack.pop() orelse return CompilerError.InvalidStackPop;

                std.debug.print("popjump => [{?s}] - ", .{currentNode.debug});
                printstack(loopbackStack);
                continue :mainloop;
            },
            .Jump2Previous => {
                _ = loopbackStack.pop();
                _ = loopbackStack.pop();
                currentNode = loopbackStack.pop() orelse return CompilerError.InvalidStackPop;

                std.debug.print("popjump => [{?s}] - ", .{currentNode.debug});
                printstack(loopbackStack);
                continue :mainloop;
            },
            .None => {},
            .End => {},
            .BranchAfter => {},
        };

        for (currentNode.next, 0..) |*next, i| {
            const result_err = next.*.isMatch(tokens);

            if (result_err) |result| {
                if (currentNode.loopback == .BranchAfter) {
                    var copy = currentNode;
                    copy.next = copy.after[i..];
                    copy.tokens = .Current;
                    copy.debug = null;
                    copy.loopback = .None;
                    try loopbackStack.append(gpa, copy);
                    std.debug.print("branch #{} => [{?s}] - ", .{ i, copy.debug });
                    printstack(loopbackStack);
                }

                tokens = tokens[result.len..];
                currentNode = next.*;
                if (currentNode.build != null) {
                    if (currentNode.tokens == .Saved) {
                        currentNode.build.?(ctx, savedTokensStack.pop() orelse @panic("out of saved tokens"));
                    } else {
                        currentNode.build.?(ctx, result);
                    }
                }
                if (currentNode.tokens == .Save) {
                    try savedTokensStack.append(gpa, result);
                }
                continue :mainloop;
            } else |_| {
                std.debug.print("checking next...\n", .{});
                continue;
            }
        }

        if (currentNode.debug != null) {
            std.debug.print("no match found for node {s}. exiting\n", .{currentNode.debug.?});
        }

        return SyntaxTreeNode.MatchError.DoesNotMatch;
    }
}

pub fn buildPrintMessage(ctx: *Context, tokens: [][]const u8) void {
    const message = tokens[3];
    const message_nt = ctx.gpa.dupeZ(u8, message[1 .. message.len - 1]) catch @panic("OOM");
    defer ctx.gpa.free(message_nt);
    const str = ctx.builder.globalStringPtr(message_nt, "message");
    ctx.buildPrintS(str);
    ctx.clearResult();
}

pub fn buildMultiplyEq(ctx: *Context, _: [][]const u8) void {
    const LHS = ctx.getFromStack().getValue(ctx);
    const RHS_ref = ctx.getFromStack();

    switch (RHS_ref) {
        .ref => {},
        else => @panic("MulEq RHS must be a ref!"),
    }

    const res = ctx.builder.fmul(LHS, RHS_ref.getValue(ctx), "");
    ctx.vars.put(RHS_ref.ref, res) catch @panic("OOM");
    ctx.setResult(res);
    std.debug.print("muleq done\n", .{});
}

pub fn buildMultiply(ctx: *Context, _: [][]const u8) void {
    const res = ctx.doMul();
    ctx.setResult(res);
    std.debug.print("mul done\n", .{});
}

pub fn doMul(ctx: *Context) llvm.Value {
    const LHS = ctx.getFromStack().getValue(ctx);
    const RHS = ctx.getFromStack().getValue(ctx);

    std.debug.print("mul\n", .{});

    return ctx.builder.fmul(LHS, RHS, "");
}

pub fn doAdd(ctx: *Context) llvm.Value {
    const LHS = ctx.getFromStack().getValue(ctx);
    const RHS = ctx.getFromStack().getValue(ctx);

    std.debug.print("add\n", .{});

    return ctx.builder.fadd(LHS, RHS, "");
}

pub fn doSquare(ctx: *Context) llvm.Value {
    const val = ctx.getFromStack().getValue(ctx);

    std.debug.print("square\n", .{});

    return ctx.builder.fmul(val, val, "");
}

pub fn doSquareRoot(ctx: *Context) llvm.Value {
    const value = ctx.getFromStack().getValue(ctx);

    std.debug.print("root\n", .{});

    const sqrt = ctx.module.getFn("llvm.sqrt.f64");
    return ctx.builder.call(sqrt, &.{value}, "");
}

pub fn doOp(ctx: *Context, op: Op) void {
    switch (op) {
        .Mul => ctx.pushValueToStack(ctx.doMul()),
        .Add => ctx.pushValueToStack(ctx.doAdd()),
        .Square => ctx.pushValueToStack(ctx.doSquare()),
        .SquareRoot => ctx.pushValueToStack(ctx.doSquareRoot()),
        .None => {},
    }
}

pub fn resolveOpStack(ctx: *Context, _: [][]const u8) void {
    while (ctx.opStack.items.len > 0) {
        const op = ctx.opStack.pop() orelse unreachable;
        ctx.doOp(op);
    }
}

pub fn buildIntDecl(ctx: *Context, tokens: [][]const u8) void {
    const var_name = tokens[4];
    const value = ctx.getFromStack().getValue(ctx);

    const ptr = ctx.builder.allocaDupeZ(.Double(), var_name, ctx.gpa);
    _ = ctx.builder.store(value, ptr);
    ctx.setLoadedVar(var_name, ptr);
    ctx.clearResult();

    std.debug.print("declaration\n", .{});
}

pub fn buildPrintResult(ctx: *Context, _: [][]const u8) void {
    ctx.buildPrintD(ctx.getResult());
    ctx.clearResult();
}

pub fn buildPrintVar(ctx: *Context, tokens: [][]const u8) void {
    const var_name = tokens[4];
    const bvar = ctx.getVar(var_name);
    ctx.buildPrintD(bvar);
    ctx.clearResult();
}

pub fn buildVariablePush(ctx: *Context, tokens: [][]const u8) void {
    const var_name = tokens[0];
    std.debug.print("pushing var {s}\n", .{var_name});
    ctx.pushRefToStack(var_name);
}

pub fn buildConstPush(ctx: *Context, tokens: [][]const u8) void {
    const value_str = tokens[0];
    const value_int = std.fmt.parseFloat(f64, value_str) catch @panic("invalid");
    const value = llvm.Value.constDouble(value_int);
    std.debug.print("pushing const {}\n", .{value_int});
    ctx.pushValueToStack(value);
}

pub fn buildSetLastAsReturn(ctx: *Context, _: [][]const u8) void {
    const value = ctx.getFromStack().getValue(ctx);
    if (ctx.varStack.items.len > 1) @panic("stack was not entirely consummed");
    ctx.setResult(value);
}

pub fn buildResultPush(ctx: *Context, _: [][]const u8) void {
    ctx.pushResultToStack();
}

pub fn buildCopyPush(ctx: *Context, _: [][]const u8) void {
    ctx.varStack.append(ctx.gpa, ctx.varStack.getLast()) catch @panic("OOM");
}

pub fn buildPrintS(ctx: *Context, value: llvm.Value) void {
    const printf = ctx.module.getFn("printf");
    const fmt = ctx.module.getGlobal("fmt_s");
    _ = ctx.builder.call(printf, &.{ fmt, value }, "");
}

pub fn buildPrintD(ctx: *Context, value: llvm.Value) void {
    const printf = ctx.module.getFn("printf");
    const fmt = ctx.module.getGlobal("fmt_d");
    _ = ctx.builder.call(printf, &.{ fmt, value }, "");
}

pub fn pushValueToStack(ctx: *Context, value: llvm.Value) void {
    ctx.varStack.append(ctx.gpa, .{ .value = value }) catch @panic("OOM");
}

pub fn pushRefToStack(ctx: *Context, ref: []const u8) void {
    ctx.varStack.append(ctx.gpa, .{ .ref = ref }) catch @panic("OOM");
}

pub fn getResult(ctx: *Context) llvm.Value {
    return ctx.result orelse @panic("no result to give!");
}

pub fn getVar(ctx: *Context, var_name: []const u8) llvm.Value {
    return ctx.vars.get(var_name) orelse @panic("variable was not declared");
}

pub fn setVar(ctx: *Context, var_name: []const u8, value: llvm.Value) void {
    ctx.vars.put(var_name, value) catch @panic("OOM");
}

pub fn setLoadedVar(ctx: *Context, var_name: []const u8, ptr: llvm.Value) void {
    const lvar = ctx.builder.load2(llvm.Type.Double(), ptr, "");
    ctx.vars.put(var_name, lvar) catch @panic("OOM");
}

pub fn getAndLoadValue(ctx: *Context, var_name: []const u8) llvm.Value {
    const ptr = ctx.getVar(var_name);
    return ctx.builder.load2(ptr, "");
}

pub fn getFromStack(ctx: *Context) ValOrRef {
    return ctx.varStack.pop() orelse @panic("out of stack");
}

pub fn pushResultToStack(ctx: *Context) void {
    if (ctx.result != null) {
        ctx.pushValueToStack(ctx.result.?);
    } else @panic("result is null");
}

pub fn pushOp(ctx: *Context, op: Op) void {
    ctx.opStack.append(ctx.gpa, op) catch @panic("OOM");
}

pub fn pushMulOp(ctx: *Context, _: [][]const u8) void {
    ctx.pushOp(.Mul);
}

pub fn pushAddOp(ctx: *Context, _: [][]const u8) void {
    ctx.pushOp(.Add);
}

pub fn pushSquareOp(ctx: *Context, _: [][]const u8) void {
    ctx.pushOp(.Square);
}

pub fn pushSquareRootOp(ctx: *Context, _: [][]const u8) void {
    ctx.pushOp(.SquareRoot);
}

pub fn clearResult(ctx: *Context) void {
    ctx.result = null;
}

pub fn setResult(ctx: *Context, value: llvm.Value) void {
    ctx.result = value;
}
