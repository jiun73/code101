const std = @import("std");
const log = @import("log.zig");
const zllvm = @import("zllvm");
const ScopeStack = @import("ScopeStack.zig");

const Builder = @This();

pub const Value = zllvm.Value;
pub const Block = zllvm.BasicBlock;
pub const Function = zllvm.Function;
pub const Ref = []const u8;

pub const DataType = enum {
    Void,
    Int,
    Real,
    String,
    Bool,

    pub fn toLLVM(ty: DataType) zllvm.Type {
        switch (ty) {
            .Void => return .Void(),
            .Int => return .Int32(),
            .Real => return .Double(),
            .String => return zllvm.Type.Int8().Ptr(),
            .Bool => return .Bool(),
        }
    }
};
pub const Param = struct { name: []const u8, ty: DataType };
pub const FunctionDefinition = struct {
    params: []Param,
    returnType: DataType = .Void,
    name: []const u8,

    pub fn findParamIndex(def: FunctionDefinition, name: []const u8) ?usize {
        std.debug.print("{}\n", .{def.params.len});
        for (def.params, 0..) |param, i| {
            std.debug.print("param {}: {s}\n", .{ param, param.name });
            if (std.mem.eql(u8, param.name, name)) return i;
        }
        return null;
    }

    pub fn dupe(gpa: std.mem.Allocator, def: FunctionDefinition) FunctionDefinition {
        const params_dupe = gpa.dupe(Param, def.params) catch @panic("OOM");
        return .{
            .name = def.name,
            .params = params_dupe,
            .returnType = def.returnType,
        };
    }

    pub fn dealloc(def: FunctionDefinition, gpa: std.mem.Allocator) void {
        gpa.free(def.params);
    }
};

module: zllvm.Module,
ir: zllvm.Builder,
scopes: ScopeStack,

printfFn: zllvm.Function,
sqrtFn: zllvm.Function,
cbrtFn: zllvm.Function,
powFn: zllvm.Function,
sayFn: zllvm.Function,
sayDbFn: zllvm.Function,
sleepFn: zllvm.Function,
askFn: zllvm.Function,

fmtS: zllvm.Value,
fmtD: zllvm.Value,
fmtB: zllvm.Value,

pub fn init(gpa: std.mem.Allocator, module: zllvm.Module) Builder {
    const builder = zllvm.Builder.create();

    const printfFn = module.addFn("printf", .create(zllvm.Type.Int8(), &.{zllvm.Type.Int8().Ptr()}, true));
    const sqrtFn = module.addFn("llvm.sqrt.f64", .create(zllvm.Type.Double(), &.{zllvm.Type.Double()}, false));
    const cbrtFn = module.addFn("llvm.cbrt.f64", .create(zllvm.Type.Double(), &.{zllvm.Type.Double()}, false));
    const powFn = module.addFn("llvm.pow.f64", .create(zllvm.Type.Double(), &.{zllvm.Type.Double()}, false));
    const sayFn = module.addFn("say", .create(zllvm.Type.Void(), &.{zllvm.Type.Int8().Ptr()}, false));
    const sayDbFn = module.addFn("say_double", .create(zllvm.Type.Void(), &.{zllvm.Type.Double()}, false));
    const askFn = module.addFn("read_double", .create(zllvm.Type.Double(), &.{zllvm.Type.Int8().Ptr()}, false));
    const sleepFn = module.addFn("sleep", .create(zllvm.Type.Void(), &.{zllvm.Type.Int32()}, false));

    const fmt_b = zllvm.Value.constString("%d\n", false);
    const fmt_b_val = module.addGlobal(fmt_b.getType(), "fmt_b").setInitializer(fmt_b).setGlobalConstant(true).setLinkage(.LLVMInternalLinkage).setUnnamedAddr(true);

    const fmt_d = zllvm.Value.constString("%.2f\n", false);
    const fmt_d_val = module.addGlobal(fmt_d.getType(), "fmt_d").setInitializer(fmt_d).setGlobalConstant(true).setLinkage(.LLVMInternalLinkage).setUnnamedAddr(true);

    const fmt_s = zllvm.Value.constString("%s\n", false);
    const fmt_s_val = module.addGlobal(fmt_s.getType(), "fmt_s").setInitializer(fmt_s).setGlobalConstant(true).setLinkage(.LLVMInternalLinkage).setUnnamedAddr(true);

    const st = ScopeStack.init(gpa);
    // const vars = std.StringHashMap(SavedVar).init(gpa);
    // const fns = std.StringHashMap(zllvm.Function).init(gpa);
    // const fndefs = std.StringHashMap(FunctionDefinition).init(gpa);

    return .{
        .printfFn = printfFn,
        .cbrtFn = cbrtFn,
        .powFn = powFn,
        .sqrtFn = sqrtFn,
        .askFn = askFn,
        //.vars = vars,
        .module = module,
        .ir = builder,
        .fmtD = fmt_d_val,
        .fmtS = fmt_s_val,
        .fmtB = fmt_b_val,
        //.fns = fns,
        //.fndefs = fndefs,
        .scopes = st,
        .sayDbFn = sayDbFn,
        .sayFn = sayFn,
        .sleepFn = sleepFn,
    };
}

pub fn deinit(b: *Builder, gpa: std.mem.Allocator) void {
    b.scopes.deinit(gpa);
    b.ir.dispose();
}

pub fn getVariableRaw(b: *Builder, var_name: []const u8) !Value {
    const record = try b.scopes.getVariableRecord(var_name);

    return record.value;

    // const v = b.vars.get(var_name) orelse {
    //     log.println("Variable '{s}' not found", .{var_name}, .Building);
    //     return Error.VariableNotDeclared;
    // };
}

pub fn getVariableValue(b: *Builder, var_name: []const u8) !Value {
    const record = try b.scopes.getVariableRecord(var_name);

    if (record.isPointerToValue) {
        return b.load(record.value);
    }

    return record.value;

    // const v = b.vars.get(var_name) orelse {
    //     log.println("Variable '{s}' not found", .{var_name}, .Building);
    //     return Error.VariableNotDeclared;
    // };
}

pub fn store(b: *Builder, LHS: Ref, RHS: Value) !Value {
    log.println("store", .{}, .Building);
    return b.ir.store(RHS, try b.getVariableRaw(LHS));
}

pub fn rem(b: *Builder, LHS: Value, RHS: Value) Value {
    log.println("rem", .{}, .Building);
    return b.ir.frem(LHS, RHS, "");
}

pub fn div(b: *Builder, LHS: Value, RHS: Value) Value {
    log.println("mul", .{}, .Building);
    return b.ir.fdiv(LHS, RHS, "");
}

pub fn mul(b: *Builder, LHS: Value, RHS: Value) Value {
    log.println("mul", .{}, .Building);
    return b.ir.fmul(LHS, RHS, "");
}

pub fn mulEq(b: *Builder, LHS: Ref, RHS: Value) !void {
    const v = try b.getVariableValue(LHS);
    const result = b.ir.fmul(v, try RHS.getValue(b), "");
    b.setVar(LHS, result);
    log.println("mulEq", .{}, .Building);
}

pub fn add(b: *Builder, LHS: Value, RHS: Value) Value {
    log.println("add", .{}, .Building);
    return b.ir.fadd(LHS, RHS, "");
}

pub fn sub(b: *Builder, LHS: Value, RHS: Value) Value {
    log.println("sub", .{}, .Building);
    return b.ir.fsub(LHS, RHS, "");
}

pub fn eq(b: *Builder, LHS: Value, RHS: Value) Value {
    log.println("sub", .{}, .Building);
    return b.ir.fcmp(.LLVMRealOEQ, LHS, RHS, "");
}

pub fn neq(b: *Builder, LHS: Value, RHS: Value) Value {
    log.println("sub", .{}, .Building);
    return b.ir.fcmp(.LLVMRealONE, LHS, RHS, "");
}

pub fn gt(b: *Builder, LHS: Value, RHS: Value) Value {
    log.println("sub", .{}, .Building);
    return b.ir.fcmp(.LLVMRealOGT, LHS, RHS, "");
}

pub fn gte(b: *Builder, LHS: Value, RHS: Value) Value {
    log.println("sub", .{}, .Building);
    return b.ir.fcmp(.LLVMRealOGE, LHS, RHS, "");
}

pub fn lt(b: *Builder, LHS: Value, RHS: Value) Value {
    log.println("sub", .{}, .Building);
    return b.ir.fcmp(.LLVMRealOLT, LHS, RHS, "");
}

pub fn lte(b: *Builder, LHS: Value, RHS: Value) Value {
    log.println("sub", .{}, .Building);
    return b.ir.fcmp(.LLVMRealOLE, LHS, RHS, "");
}

pub fn square(b: *Builder, val: Value) Value {
    log.println("square", .{}, .Building);
    return b.ir.fmul(val, val, "");
}

pub fn squareRoot(b: *Builder, val: Value) Value {
    log.println("root", .{}, .Building);
    return b.ir.call(b.sqrtFn, &.{val}, "");
}

pub fn ttsString(b: *Builder, value: Value) void {
    _ = b.ir.call(b.sayFn, &.{value}, "");
}

pub fn ttsDouble(b: *Builder, value: Value) void {
    _ = b.ir.call(b.sayDbFn, &.{value}, "");
}

pub fn sleep(b: *Builder, value: Value) void {
    _ = b.ir.call(b.sleepFn, &.{value}, "");
}

pub fn printString(b: *Builder, value: Value) void {
    _ = b.ir.call(b.printfFn, &.{ b.fmtS, value }, "");
}

pub fn printBool(b: *Builder, value: Value) void {
    _ = b.ir.call(b.printfFn, &.{ b.fmtB, value }, "");
}

pub fn printDecimal(b: *Builder, value: Value) void {
    _ = b.ir.call(b.printfFn, &.{ b.fmtD, value }, "");
}

pub fn setLoadedVar(b: *Builder, var_name: []const u8, ptr: zllvm.Value) void {
    const lvar = b.ir.load2(zllvm.Type.Double(), ptr, "");
    b.vars.put(var_name, lvar) catch @panic("OOM");
}

pub fn getAndLoadValue(b: *Builder, var_name: []const u8) !zllvm.Value {
    const ptr = try b.getVariableValue(var_name);
    return b.ir.load2(.Double(), ptr, "");
}

pub fn load(b: *Builder, ptr: Value) Value {
    return b.ir.load2(.Double(), ptr, "");
}

pub fn declare(b: *Builder, gpa: std.mem.Allocator, var_name: []const u8) Value {
    log.println("declaration", .{}, .Building);
    const ptr = b.ir.allocaDupeZ(.Double(), var_name, gpa);
    b.scopes.getCurrentScope().setVariableValuePtr(var_name, ptr);
    return ptr;
}

pub fn defineMain(b: *Builder, gpa: std.mem.Allocator) !void {
    const fun = b.module.addFn("main", .create(zllvm.Type.Int32(), &.{ zllvm.Type.Int32(), zllvm.Type.Int8().Ptr().Ptr() }, false));
    const entry = fun.appendBasicBlock("entree");
    b.ir.positionAtEnd(entry);
    b.scopes.getGlobalScope().setExternalFunction("___main___", fun);
    b.scopes.enterScope(gpa, .init(gpa, .{ .block = entry }));
}

pub fn defineFunction(b: *Builder, gpa: std.mem.Allocator, def: FunctionDefinition) void {
    const name_nt = gpa.dupeZ(u8, def.name) catch @panic("OOM");
    defer gpa.free(name_nt);

    log.println("param cnt {}", .{def.params.len}, .Building);

    const paramsLLVM = gpa.alloc(zllvm.Type, def.params.len) catch @panic("OOM");
    defer gpa.free(paramsLLVM);

    for (def.params, 0..) |param, i| {
        paramsLLVM[i] = param.ty.toLLVM();
    }

    const fun = b.module.addFn(name_nt, .create(def.returnType.toLLVM(), paramsLLVM, false));
    const entry = fun.appendBasicBlock("entree");
    b.ir.positionAtEnd(entry);

    for (def.params, 0..) |param, i| {
        const value = fun.getParam(i);
        b.scopes.getCurrentScope().setVariableValue(param.name, value);
        log.println("param {s}", .{param.name}, .Building);
    }

    b.scopes.getGlobalScope().setFunction(def, fun);
    b.scopes.enterScope(gpa, .init(gpa, .{ .block = entry }));
}

// pub fn section(b: *Builder, gpa: std.mem.Allocator, name: []const u8) !void {
//     //const fnName = tokens[2];
//     const name_nt = gpa.dupeZ(u8, name) catch @panic("OOM");
//     defer gpa.free(name_nt);

//     const fun = b.module.addFn(name_nt, .create(llvm.Type.Int32(), &.{ llvm.Type.Int32(), llvm.Type.Int8().Ptr().Ptr() }, false));
//     const entry = fun.appendBasicBlock("entry");
//     b.ir.positionAtEnd(entry);
//     b.fns.put(name, fun) catch @panic("OOM");
// }

pub fn call(b: *Builder, name: []const u8, args: []Value) !Value {
    const fn_record = try b.scopes.getFunctionRecord(name);
    return b.ir.call(fn_record.body, args, "");
}

pub fn cond(b: *Builder, gpa: std.mem.Allocator, condition: Value) !void {
    const fn_name = try b.scopes.getParentFunctionScopeName();
    const record = try b.scopes.getFunctionRecord(fn_name);
    const fun = record.body;
    const true_block = fun.appendBasicBlock("true");
    const false_block = fun.appendBasicBlock("false");
    const then_block = fun.appendBasicBlock("then");
    _ = b.ir.condBr(condition, true_block, false_block);
    b.ir.positionAtEnd(true_block);

    b.scopes.getCurrentScope().nextBlock = then_block;
    b.scopes.enterScope(gpa, .init(gpa, .{ .block = true_block }));
    b.scopes.getCurrentScope().elseBlock = false_block;
}

pub fn br(b: *Builder, gpa: std.mem.Allocator, condition: Value) !void {
    const fn_name = try b.scopes.getParentFunctionScopeName();
    const record = try b.scopes.getFunctionRecord(fn_name);
    const fun = record.body;
    const true_block = fun.appendBasicBlock("true");
    const false_block = fun.appendBasicBlock("false");
    const then_block = fun.appendBasicBlock("then");
    _ = b.ir.condBr(condition, true_block, false_block);
    b.ir.positionAtEnd(true_block);

    b.scopes.getCurrentScope().nextBlock = then_block;
    b.scopes.enterScope(gpa, .init(gpa, .{ .block = true_block }));
    b.scopes.getCurrentScope().elseBlock = false_block;
}
