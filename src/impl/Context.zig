const std = @import("std");
const llvm = @import("llvm");
const target = llvm.target;
const types = llvm.types;
const core = llvm.core;
const SyntaxTreeNode = @import("SyntaxTreeNode.zig").SyntaxTreeNode;
const OpStack = @import("OpStack.zig");
const Builder = @import("Builder.zig");
const nodes = @import("nodes.zig");

const Context = @This();
const FnOrMain = union(enum) { main: void, fun: Builder.FunctionDefinition };

progressNode: std.Progress.Node,
gpa: std.mem.Allocator,
counter: u32,

fndef: ?FnOrMain = null,
source: []const u8,
opStack: OpStack,
builder: Builder,
typeStack: std.ArrayList(Builder.DataType),

pub fn getSliceTo(source: []const u8, char: *const u8) []const u8 {
    const diff = @intFromPtr(char) - @intFromPtr(source.ptr);
    return source[0..diff];
}

pub fn getLineNumber(data: []const u8) struct { cnt: usize, lastLn: *const u8 } {
    var cnt: usize = 1;
    var lastLn: *const u8 = @ptrCast(data.ptr);
    for (data) |*c| {
        if (c.* == '\n') {
            lastLn = c;
            cnt += 1;
        }
    }
    return .{ .cnt = cnt, .lastLn = lastLn };
}

pub fn getLineSlice(data: []const u8) []const u8 {
    for (data, 0..) |c, i| {
        if (c == '\n') return data[0..i];
    }
    return data;
}

pub fn getPositionalInfo(data: []const u8, char: *const u8) struct { charnbr: usize, linenbr: usize, line: []const u8 } {
    const slc = getSliceTo(data, char);
    const ln = getLineNumber(slc);

    const iln = @intFromPtr(ln.lastLn) -| @intFromPtr(data.ptr) +| 1;
    const line = getLineSlice(data[iln..]);

    return .{ .linenbr = ln.cnt, .charnbr = @intFromPtr(char) -| @intFromPtr(ln.lastLn) -| 1, .line = line };
}

pub fn printLineError(ctx: *Context, char: *const u8) void {
    const pos = getPositionalInfo(ctx.source, char);
    const cnt = std.fmt.count("{c} ({}:{}) ", .{ char.*, pos.linenbr, pos.charnbr });
    std.debug.print("{c} ({}:{}) {s}\n", .{ char.*, pos.linenbr, pos.charnbr, pos.line });
    for (0..cnt) |_| {
        std.debug.print("-", .{});
    }
    var view = std.unicode.Utf8View.init(pos.line) catch @panic("");
    var iter = view.iterator();
    var c: usize = 1;
    while (iter.nextCodepoint()) |_| {
        if (c >= pos.charnbr) break;
        std.debug.print(" ", .{});
        c += 1;
    }

    std.debug.print("^ ici\n", .{});
}

pub fn init(gpa: std.mem.Allocator, progressNode: std.Progress.Node, source: []const u8, module: llvm.Module) Context {
    const opStack = OpStack.init(gpa);
    const builder = Builder.init(gpa, module);

    return .{
        .source = source,
        .progressNode = progressNode,
        .gpa = gpa,
        .counter = 0,
        .opStack = opStack,
        .builder = builder,
    };
}

pub fn deinit(ctx: *Context) void {
    ctx.opStack.deinit(ctx.gpa);
    ctx.builder.deinit();
    ctx.progressNode.end();
}

fn printstack(loopbackStack: std.ArrayList(SyntaxTreeNode)) void {
    std.debug.print("stack:", .{});
    for (loopbackStack.items) |item| {
        std.debug.print("[{?s}]", .{item.debug});
    }
    std.debug.print("\n", .{});
}

pub fn build(ctx: *Context, gpa: std.mem.Allocator, tokens: [][]const u8) !void {
    return nodes.master.traverse(ctx, gpa, tokens);
}

const DEBUG_CTX = false;
fn debugPrint(comptime fmt: []const u8, args: anytype) void {
    if (DEBUG_CTX) std.debug.print(fmt, args);
}

pub fn buildTTSMessage(ctx: *Context, tokens: [][]const u8) !void {
    const message = tokens[1];
    const message_nt = ctx.gpa.dupeZ(u8, message[1 .. message.len - 1]) catch @panic("OOM");
    defer ctx.gpa.free(message_nt);
    const str = ctx.builder.ir.globalStringPtr(message_nt, "message");
    ctx.builder.ttsString(str);
    ctx.opStack.clearResult();
}

pub fn buildPrintMessage(ctx: *Context, tokens: [][]const u8) !void {
    const message = tokens[3];
    const message_nt = ctx.gpa.dupeZ(u8, message[1 .. message.len - 1]) catch @panic("OOM");
    defer ctx.gpa.free(message_nt);
    const str = ctx.builder.ir.globalStringPtr(message_nt, "message");
    ctx.builder.printString(str);
    ctx.opStack.clearResult();
}

pub fn buildMultiplyEq(ctx: *Context, _: [][]const u8) !void {
    try ctx.builder.mulEq(try ctx.opStack.getVal(), (try ctx.opStack.getVal()).getRef());
    ctx.opStack.clearResult();
}

pub fn buildMultiply(ctx: *Context, _: [][]const u8) !void {
    ctx.opStack.pushOp(ctx.gpa, .Mul);
    try ctx.opStack.resolve(ctx.gpa, &ctx.builder);
}

pub fn buildPrintResult(ctx: *Context, _: [][]const u8) !void {
    ctx.builder.printDecimal(try ctx.opStack.getResultSafe());
}

pub fn buildPrintVar(ctx: *Context, tokens: [][]const u8) !void {
    const var_name = tokens[4];
    const value = try ctx.builder.getAndLoadValue(var_name);
    ctx.builder.printDecimal(value);
    ctx.opStack.clearResult();
}

pub fn buildVariablePush(ctx: *Context, tokens: [][]const u8) !void {
    const var_name = tokens[0];
    std.debug.print("pushing var {s}\n", .{var_name});
    ctx.opStack.pushRef(ctx.gpa, var_name);
}

pub fn buildConstPush(ctx: *Context, tokens: [][]const u8) !void {
    const value_str = tokens[0];
    const value_int = std.fmt.parseFloat(f64, value_str) catch @panic("invalid");
    const value = llvm.Value.constDouble(value_int);
    std.debug.print("pushing const {}\n", .{value_int});
    ctx.opStack.pushVal(ctx.gpa, value);
}

pub fn buildSleep(ctx: *Context, tokens: [][]const u8) !void {
    const value_str = tokens[1];
    const value_int = std.fmt.parseInt(u32, value_str, 10) catch @panic("invalid");
    const value = llvm.Value.constInt32(value_int);
    ctx.builder.sleep(value);
}

pub fn buildResultPush(ctx: *Context, _: [][]const u8) !void {
    ctx.opStack.pushVal(ctx.gpa, ctx.opStack.result.?);
}

pub fn buildCopyPush(ctx: *Context, _: [][]const u8) !void {
    ctx.opStack.push(ctx.gpa, ctx.opStack.getLast());
}

pub fn buildDeclare(ctx: *Context, tokens: [][]const u8) !void {
    const var_name = tokens[4];
    _ = ctx.builder.declare(ctx.gpa, var_name);
    ctx.opStack.pushRef(ctx.gpa, var_name);
    ctx.opStack.pushOp(ctx.gpa, .Store);
}

// pub fn pushResultToStack(ctx: *Context) void {
//     if (ctx.result != null) {
//         ctx.pushValueToStack(ctx.result.?);
//     } else @panic("result is null");
// }

pub fn pushOpFn(comptime op: OpStack.Op) fn (*Context, [][]const u8) anyerror!void {
    const T = struct {
        pub fn fun(ctx: *Context, _: [][]const u8) !void {
            ctx.opStack.pushOp(ctx.gpa, op);
        }
    };
    return T.fun;
}

pub fn buildRet(ctx: *Context, _: [][]const u8) !void {
    _ = ctx.builder.ir.ret(llvm.Value.constInt32(0));
}

pub fn endExpression(ctx: *Context, _: [][]const u8) !void {
    try ctx.opStack.resolve(ctx.gpa, &ctx.builder);
    ctx.opStack.setResult(&ctx.builder) catch |err| switch (err) {
        OpStack.Error.NoLeftover => {}, //we allow expressions to resolve with no result
        else => return err,
    };
    ctx.opStack.clear();
    std.debug.print("expr end\n", .{});
}

pub fn resolveExpression(ctx: *Context, _: [][]const u8) !void {
    try ctx.opStack.resolve(ctx.gpa, &ctx.builder);
}

pub fn buildSection(ctx: *Context, tokens: [][]const u8) !void {
    const name = tokens[2];

    if (std.mem.eql(u8, name, "principale")) {
        try ctx.builder.main();
    } else {
        const str = name[1 .. name.len - 1];
        try ctx.builder.function(ctx.gpa, str);
    }
}

pub fn startFunctionDefinition(ctx: *Context, tokens: [][]const u8) !void {
    const name = tokens[2];

    if (std.mem.eql(u8, name, "principale")) {
        ctx.fndef = .{ .main = {} };
    } else {
        const name_tr = name[1 .. name.len - 1];
        ctx.fndef = .{ .fun = .init(ctx.gpa, name_tr) };

        // const str = name[1 .. name.len - 1];
        // try ctx.builder.section(ctx.gpa, str);
    }
}

pub fn defineFunctionParam(ctx: *Context, tokens: [][]const u8) !void {
    const name = tokens[0];
    const fndef = &(ctx.fndef orelse @panic("Tentative d'ajouter un paramètre de fonction alors que nous ne sommes pas en train de définir une fonction"));

    switch (fndef.*) {
        FnOrMain.fun => |*fun| {
            fun.params.append(ctx.gpa, .{ .name = name, .ty = .Real }) catch @panic("OOM");
            std.debug.print("define '{s}' {}\n", .{ name, fun });
        },
        else => unreachable,
    }
}

pub const FunctionError = error{ERROR};

pub fn buildFunction(ctx: *Context, _: [][]const u8) !void {
    const fndef = &(ctx.fndef orelse @panic("Tentative de contruire une fonction sans la définir"));

    switch (fndef.*) {
        .main => try ctx.builder.main(),
        .fun => |*fun| {
            ctx.builder.function(ctx.gpa, fun.*);
            std.debug.print("build fn '{s}'\n", .{fun.name});
            fun.deinit(ctx.gpa);
        },
    }
}

pub fn buildCall(ctx: *Context, tokens: [][]const u8) !void {
    const name = tokens[6];
    const str = name[1 .. name.len - 1];
    try ctx.builder.call(str);
}
