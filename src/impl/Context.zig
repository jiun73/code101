const std = @import("std");
const zllvm = @import("zllvm");
const target = zllvm.target;
const types = zllvm.types;
const core = zllvm.core;
const SyntaxTreeNode = @import("SyntaxTreeNode.zig").SyntaxTreeNode;
const OpStack = @import("OpStack.zig");
const Builder = @import("Builder.zig");
const nodes = @import("nodes.zig");
const log = @import("log.zig");
const fns = @import("fns.zig");
const uni = @import("unicode.util.zig");

const Context = @This();
const FnOrMain = union(enum) { main: void, fun: Builder.FunctionDefinition };

const CallCollector = struct {
    params: []Builder.Value,
    name: []const u8,
    paramCursor: ?usize = null,
    fndef: Builder.FunctionDefinition,

    pub fn start(gpa: std.mem.Allocator, name: []const u8, fndef: Builder.FunctionDefinition) CallCollector {
        const params = gpa.alloc(Builder.Value, fndef.params.len) catch @panic("OOM");
        return .{ .name = name, .params = params, .fndef = fndef };
    }

    pub fn deinit(cc: CallCollector, gpa: std.mem.Allocator) void {
        gpa.free(cc.params);
    }
};

const FunctionDefinitionCollectorTy = struct {
    name: []const u8,
    params: std.ArrayList(Builder.Param),
    returnType: ?Builder.DataType = null,

    pub fn toBuilderDef(def: FunctionDefinitionCollectorTy) Builder.FunctionDefinition {
        return .{
            .name = def.name,
            .params = def.params.items,
            .returnType = def.returnType,
        };
    }
};
const FunctionDefinitionCollector = union(enum) {
    main: void,
    fun: FunctionDefinitionCollectorTy,

    pub fn startMain() FunctionDefinitionCollector {
        return .main;
    }

    pub fn start(gpa: std.mem.Allocator, name: []const u8) FunctionDefinitionCollector {
        const params = std.ArrayList(Builder.Param).initCapacity(gpa, 8) catch @panic("OOM");

        return .{ .fun = .{ .name = name, .params = params } };
    }

    pub fn deinit(fndef: *FunctionDefinitionCollector, gpa: std.mem.Allocator) void {
        switch (fndef.*) {
            .fun => |*fun| {
                fun.params.deinit(gpa);
            },
            else => {},
        }
    }
};

progressNode: std.Progress.Node,
gpa: std.mem.Allocator,
counter: u32,

source: []const u8,
opStack: OpStack,
builder: Builder,
typeStack: std.ArrayList(Builder.DataType),
fndef: ?FunctionDefinitionCollector = null,
callCollector: ?CallCollector = null,

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

pub fn init(gpa: std.mem.Allocator, progressNode: std.Progress.Node, source: []const u8, module: zllvm.Module) Context {
    const opStack = OpStack.init(gpa);
    const builder = Builder.init(gpa, module);
    const typeStack = std.ArrayList(Builder.DataType).initCapacity(gpa, 4) catch @panic("OOM");

    return .{
        .source = source,
        .progressNode = progressNode,
        .gpa = gpa,
        .counter = 0,
        .opStack = opStack,
        .builder = builder,
        .typeStack = typeStack,
    };
}

pub fn deinit(ctx: *Context) void {
    ctx.opStack.deinit(ctx.gpa);
    ctx.builder.deinit(ctx.gpa);
    ctx.progressNode.end();
    ctx.typeStack.deinit(ctx.gpa);
}

fn printstack(loopbackStack: std.ArrayList(SyntaxTreeNode)) void {
    log.print("stack:", .{}, .Building);
    for (loopbackStack.items) |item| {
        log.print("[{?s}]", .{item.debug}, .Building);
    }
    log.ln(.Building);
}

pub fn build(ctx: *Context, gpa: std.mem.Allocator, tokens: [][]const u8) !void {
    return nodes.master.traverse(ctx, gpa, tokens);
}

pub fn buildTTSMessage(ctx: *Context, message: []const u8) !void {
    const message_nt = ctx.gpa.dupeZ(u8, message[1 .. message.len - 1]) catch @panic("OOM");
    defer ctx.gpa.free(message_nt);
    const str = ctx.builder.ir.globalStringPtr(message_nt, "message");
    ctx.builder.ttsString(str);
}

pub fn buildTTSMessage2(ctx: *Context, var_name: []const u8) !void {
    ctx.builder.ttsDouble(try ctx.builder.getVariableValue(var_name));
}

pub fn buildAsk(ctx: *Context, var_name: []const u8) !void {
    const var_name_nt = ctx.gpa.dupeZ(u8, var_name[0..var_name.len]) catch @panic("OOM");
    defer ctx.gpa.free(var_name_nt);
    const var_name_str = ctx.builder.ir.globalStringPtr(var_name_nt, "var_name");
    log.print("{s}", .{var_name}, .Building);
    const varn = ctx.builder.declare(ctx.gpa, var_name);
    const val = ctx.builder.ir.call(ctx.builder.askFn, &.{var_name_str}, "");
    _ = ctx.builder.ir.store(val, varn);
}

pub fn buildPrintMessage(ctx: *Context, message: []const u8) !void {
    const message_nt = ctx.gpa.dupeZ(u8, message[1 .. message.len - 1]) catch @panic("OOM");
    defer ctx.gpa.free(message_nt);
    const str = ctx.builder.ir.globalStringPtr(message_nt, "message");
    ctx.builder.printString(str);
}

pub fn buildMultiplyEq(ctx: *Context) !void {
    try ctx.builder.mulEq(try ctx.opStack.getDouble(), (try ctx.opStack.getDouble()).getRef());
}

pub fn buildMultiply(ctx: *Context) !void {
    ctx.opStack.pushOp(ctx.gpa, .Multiply);
    try ctx.opStack.resolve(ctx.gpa, &ctx.builder);
}

pub fn buildPrintResult(ctx: *Context) !void {
    const result = ctx.opStack.get();

    switch (result) {
        .bool => |val| ctx.builder.printBool(val),
        .double => |val| ctx.builder.printDecimal(val),
        .reference => {
            ctx.builder.printDecimal(try result.asDouble(&ctx.builder));
        },
        else => unreachable,
    }
}

pub fn buildPrintVar(ctx: *Context, var_name: []const u8) !void {
    const value = try ctx.builder.getAndLoadValue(var_name);
    ctx.builder.printDecimal(value);
}

pub fn buildVariablePush(ctx: *Context, var_name: []const u8) !void {
    log.println("pushing var {s}", .{var_name}, .Building);
    ctx.opStack.pushData(ctx.gpa, .{ .reference = var_name });
}

pub fn buildConstPush(ctx: *Context, value_str: []const u8) !void {
    const value_int = std.fmt.parseFloat(f64, value_str) catch @panic("invalid");
    const value = zllvm.Value.constDouble(value_int);
    log.println("pushing const {}", .{value_int}, .Building);
    ctx.opStack.pushData(ctx.gpa, .{ .double = value });
}

pub fn buildSleep(ctx: *Context, value_str: []const u8) !void {
    const value_int = std.fmt.parseInt(u32, value_str, 10) catch @panic("invalid");
    const value = zllvm.Value.constInt32(value_int);
    ctx.builder.sleep(value);
}

pub fn buildResultPush(_: *Context) !void {
    //unreachable;
}

pub fn buildCopyPush(ctx: *Context) !void {
    ctx.opStack.pushData(ctx.gpa, ctx.opStack.getLast());
}

pub fn buildDeclare(ctx: *Context, variable_name: []const u8) !void {
    ctx.opStack.pushData(ctx.gpa, .{ .label = variable_name });
    _ = try ctx.opStack.doOp(ctx.gpa, &ctx.builder, .{ .memory = .Declare });

    ctx.opStack.pushOp(ctx.gpa, .{ .control = .Result });
    ctx.opStack.pushData(ctx.gpa, .{ .reference = variable_name });
    ctx.opStack.pushOp(ctx.gpa, .{ .memory = .Store });
}

// pub fn pushResultToStack(ctx: *Context) void {
//     if (ctx.result != null) {
//         ctx.pushValueToStack(ctx.result.?);
//     } else @panic("result is null");
// }

pub fn pushOpFn(comptime op: OpStack.Op) SyntaxTreeNode.BuildFnNoTokens {
    const T = struct {
        pub fn fun(ctx: *Context) !void {
            ctx.opStack.pushOp(ctx.gpa, op);
        }
    };
    return T.fun;
}

pub fn doOpFn(comptime op: OpStack.Op) SyntaxTreeNode.BuildFnNoTokens {
    const T = struct {
        pub fn fun(ctx: *Context) !void {
            _ = try ctx.opStack.doOp(ctx.gpa, &ctx.builder, op);
        }
    };
    return T.fun;
}

pub fn buildRet(ctx: *Context) !void {
    const fn_name = try ctx.builder.scopes.getParentFunctionScopeName();
    log.println("getting function from scope {s}", .{fn_name}, .Building);
    const fn_record = try ctx.builder.scopes.getFunctionRecord(fn_name);
    defer ctx.builder.scopes.exitScope(ctx.gpa);

    if (std.mem.eql(u8, fn_name, "___main___")) {
        _ = ctx.builder.ir.ret(.constInt32(0));
        return;
    }

    if (fn_record.def) |def| {
        if (def.returnType == .Void) {
            _ = ctx.builder.ir.retvoid();
        } else {
            const result = try ctx.opStack.popValue(&ctx.builder);
            _ = ctx.builder.ir.ret(result);
        }
    } else @panic("Aucune définition de fonction !");
}

pub fn startExpr(ctx: *Context) !void {
    ctx.opStack.pushOp(ctx.gpa, .{ .control = .Result });
}

pub fn endExpr(ctx: *Context) !void {
    try ctx.opStack.resolve(ctx.gpa, &ctx.builder);
}

pub fn restartExpr(ctx: *Context) !void {
    try ctx.opStack.resolve(ctx.gpa, &ctx.builder);
    ctx.opStack.pushOp(ctx.gpa, .{ .control = .Result });
}

// pub fn buildSection(ctx: *Context, tokens: [][]const u8) !void {
//     const name = tokens[2];

//     if (std.mem.eql(u8, name, "principale")) {
//         try ctx.builder.main();
//     } else {
//         const str = name[1 .. name.len - 1];
//         try ctx.builder.function(ctx.gpa, str);
//     }
// }

pub fn startFunctionDefinition(ctx: *Context, name: []const u8) !void {
    if (std.mem.eql(u8, name, "principale")) {
        ctx.opStack.pushData(ctx.gpa, .{ .label = "___main___" });
        ctx.builder.scopes.enterScope(ctx.gpa, .init(ctx.gpa, .{ .function = "___main___" }));
        //try ctx.opStack.doOp(ctx.gpa, &ctx.builder, .{ .function_def = .DefineMain });
        //ctx.fndef = .startMain();
    } else {
        const fn_name = uni.stripFirstAndLast(name);

        ctx.opStack.pushData(ctx.gpa, .{ .label = fn_name });
        ctx.builder.scopes.enterScope(ctx.gpa, .init(ctx.gpa, .{ .function = fn_name }));

        //ctx.fndef = .start(ctx.gpa, name_tr);

        // const str = name[1 .. name.len - 1];
        // try ctx.builder.section(ctx.gpa, str);
    }

    // if (std.mem.eql(u8, name, "principale")) {
    //     ctx.fndef = .startMain();
    // } else {
    //     const name_tr = uni.stripFirstAndLast(name);
    //     ctx.fndef = .start(ctx.gpa, name_tr);

    //     // const str = name[1 .. name.len - 1];
    //     // try ctx.builder.section(ctx.gpa, str);
    // }
}

pub fn buildFunctionParam(ctx: *Context, name: []const u8) !void {
    ctx.opStack.pushData(ctx.gpa, .{ .label = name });

    // const fndef = &(ctx.fndef orelse @panic("Tentative d'ajouter un paramètre de fonction alors que nous ne sommes pas en train de définir une fonction"));

    // switch (fndef.*) {
    //     .fun => |*fun| {
    //         fun.params.append(ctx.gpa, .{ .name = name, .ty = .Real }) catch @panic("OOM");
    //         log.println("function param '{s}'", .{name}, .Building);
    //     },
    //     else => unreachable,
    // }
}

pub fn buildFunctionResult(_: *Context, _: [][]const u8) !void {
    // const fndef = &(ctx.fndef orelse @panic("Tentative d'ajouter un paramètre de fonction alors que nous ne sommes pas en train de définir une fonction"));

    // switch (fndef.*) {
    //     .fun => |*fun| {
    //         const ty = ctx.typeStack.pop() orelse @panic("TODO");
    //         fun.returnType = ty;
    //         log.println("function return '{}'", .{ty}, .Building);
    //     },
    //     else => unreachable,
    // }
}

pub const FunctionError = error{ERROR};

pub fn buildFunction(ctx: *Context) !void {
    try ctx.opStack.doOp(ctx.gpa, &ctx.builder, .{ .function_def = .DefineFunction });
}

pub fn buildCall(ctx: *Context) !void {
    try ctx.opStack.doOp(ctx.gpa, &ctx.builder, .{ .call = .Call });
}

pub fn startBuildCall(ctx: *Context, name: []const u8) !void {
    const fn_name = uni.stripFirstAndLast(name);
    ctx.opStack.pushData(ctx.gpa, .{ .label = fn_name });
}

pub fn buildCallParams(ctx: *Context, name: []const u8) !void {
    ctx.opStack.pushData(ctx.gpa, .{ .reference = name });
}

pub fn buildCallParamValue(ctx: *Context) !void {
    try ctx.opStack.doOp(ctx.gpa, &ctx.builder, .{ .call = .PromoteRefToArg });
}

pub fn pushType(comptime ty: Builder.DataType) SyntaxTreeNode.BuildFnNoTokens {
    const T = struct {
        pub fn fun(ctx: *Context) !void {
            ctx.opStack.pushData(ctx.gpa, .{ .type = ty });
        }
    };
    return T.fun;
}
