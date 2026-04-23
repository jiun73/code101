const std = @import("std");
const llvm = @import("llvm");

const Builder = @This();

pub const Value = llvm.Value;
pub const Ref = []const u8;

pub const ValueRef = union(enum) {
    value: Value,
    ref: Ref,

    pub fn getValue(vr: ValueRef, b: *Builder) Error!Value {
        switch (vr) {
            .value => |val| return val,
            .ref => |ref| return try b.getVar(ref),
        }
    }

    pub fn getValueLoad(vr: ValueRef, b: *Builder) Error!Value {
        const value = vr.getValue(b);
        return b.ir.load2(.Double(), value, "");
    }

    pub fn getRef(vr: ValueRef) Ref {
        switch (vr) {
            .ref => |ref| return ref,
            else => @panic("trying to cast value to ref"),
        }
    }

    pub fn print(vr: ValueRef) void {
        switch (vr) {
            .ref => |ref| std.debug.print("[{s}]", .{ref}),
            .value => |val| std.debug.print("[{x}]", .{@intFromPtr(val.ref)}),
        }
    }
};

pub const Error = error{VariableNotDeclared};

module: llvm.Module,
ir: llvm.Builder,
vars: std.StringHashMap(Value),
fns: std.StringHashMap(llvm.Function),

printfFn: llvm.Function,
sqrtFn: llvm.Function,
cbrtFn: llvm.Function,
powFn: llvm.Function,
sayFn: llvm.Function,
sleepFn: llvm.Function,

fmtS: llvm.Value,
fmtD: llvm.Value,

pub fn init(gpa: std.mem.Allocator, module: llvm.Module) Builder {
    const builder = llvm.Builder.create();

    const printfFn = module.addFn("printf", .create(llvm.Type.Int8(), &.{llvm.Type.Int8().Ptr()}, true));
    const sqrtFn = module.addFn("llvm.sqrt.f64", .create(llvm.Type.Double(), &.{llvm.Type.Double()}, false));
    const cbrtFn = module.addFn("llvm.cbrt.f64", .create(llvm.Type.Double(), &.{llvm.Type.Double()}, false));
    const powFn = module.addFn("llvm.pow.f64", .create(llvm.Type.Double(), &.{llvm.Type.Double()}, false));
    const sayFn = module.addFn("say", .create(llvm.Type.Void(), &.{llvm.Type.Int8().Ptr()}, false));
    const sleepFn = module.addFn("sleep", .create(llvm.Type.Void(), &.{llvm.Type.Int32()}, false));

    const fmt_d = llvm.Value.constString("%.2f\n", false);
    const fmt_d_val = module.addGlobal(fmt_d.getType(), "fmt_d").setInitializer(fmt_d).setGlobalConstant(true).setLinkage(.LLVMInternalLinkage).setUnnamedAddr(true);

    const fmt_s = llvm.Value.constString("%s\n", false);
    const fmt_s_val = module.addGlobal(fmt_s.getType(), "fmt_s").setInitializer(fmt_s).setGlobalConstant(true).setLinkage(.LLVMInternalLinkage).setUnnamedAddr(true);

    const vars = std.StringHashMap(Value).init(gpa);
    const fns = std.StringHashMap(llvm.Function).init(gpa);

    return .{
        .printfFn = printfFn,
        .cbrtFn = cbrtFn,
        .powFn = powFn,
        .sqrtFn = sqrtFn,
        .vars = vars,
        .module = module,
        .ir = builder,
        .fmtD = fmt_d_val,
        .fmtS = fmt_s_val,
        .fns = fns,
        .sayFn = sayFn,
        .sleepFn = sleepFn,
    };
}

pub fn deinit(b: *Builder) void {
    b.vars.deinit();
    b.fns.deinit();
    b.ir.dispose();
}

pub fn getVar(b: *Builder, var_name: []const u8) Error!Value {
    return b.vars.get(var_name) orelse {
        std.debug.print("Variable '{s}' not found\n", .{var_name});
        return Error.VariableNotDeclared;
    };
}

pub fn setVar(b: *Builder, var_name: []const u8, value: Value) void {
    b.vars.put(var_name, value) catch @panic("OOM");
}

pub fn store(b: *Builder, RHS: ValueRef, LHS: Ref) Error!Value {
    std.debug.print("store\n", .{});
    return b.ir.store(try RHS.getValue(b), try b.getVar(LHS));
}

pub fn rem(b: *Builder, RHS: ValueRef, LHS: ValueRef) Error!Value {
    std.debug.print("rem\n", .{});
    return b.ir.frem(try LHS.getValue(b), try RHS.getValue(b), "");
}

pub fn div(b: *Builder, RHS: ValueRef, LHS: ValueRef) Error!Value {
    std.debug.print("mul\n", .{});
    return b.ir.fdiv(try LHS.getValue(b), try RHS.getValue(b), "");
}

pub fn mul(b: *Builder, LHS: ValueRef, RHS: ValueRef) Error!Value {
    std.debug.print("mul\n", .{});
    return b.ir.fmul(try LHS.getValue(b), try RHS.getValue(b), "");
}

pub fn mulEq(b: *Builder, RHS: ValueRef, LHS: Ref) Error!void {
    const result = b.ir.fmul(try b.getVar(LHS), try RHS.getValue(b), "");
    b.setVar(LHS, result);
    std.debug.print("mulEq\n", .{});
}

pub fn add(b: *Builder, LHS: ValueRef, RHS: ValueRef) Error!Value {
    std.debug.print("add\n", .{});
    return b.ir.fadd(try LHS.getValue(b), try RHS.getValue(b), "");
}

pub fn sub(b: *Builder, RHS: ValueRef, LHS: ValueRef) Error!Value {
    std.debug.print("sub\n", .{});
    return b.ir.fsub(try LHS.getValue(b), try RHS.getValue(b), "");
}

pub fn square(b: *Builder, OP: ValueRef) Error!Value {
    std.debug.print("square\n", .{});
    const val = try OP.getValue(b);
    return b.ir.fmul(val, val, "");
}

pub fn squareRoot(b: *Builder, OP: ValueRef) Error!Value {
    std.debug.print("root\n", .{});

    const value = try OP.getValue(b);
    return b.ir.call(b.sqrtFn, &.{value}, "");
}

pub fn ttsString(b: *Builder, value: Value) void {
    _ = b.ir.call(b.sayFn, &.{value}, "");
}

pub fn sleep(b: *Builder, value: Value) void {
    _ = b.ir.call(b.sleepFn, &.{value}, "");
}

pub fn printString(b: *Builder, value: Value) void {
    _ = b.ir.call(b.printfFn, &.{ b.fmtS, value }, "");
}

pub fn printDecimal(b: *Builder, value: Value) void {
    _ = b.ir.call(b.printfFn, &.{ b.fmtD, value }, "");
}

pub fn setLoadedVar(b: *Builder, var_name: []const u8, ptr: llvm.Value) void {
    const lvar = b.ir.load2(llvm.Type.Double(), ptr, "");
    b.vars.put(var_name, lvar) catch @panic("OOM");
}

pub fn getAndLoadValue(b: *Builder, var_name: []const u8) Error!llvm.Value {
    const ptr = try b.getVar(var_name);
    return b.ir.load2(.Double(), ptr, "");
}

pub fn declare(b: *Builder, gpa: std.mem.Allocator, var_name: []const u8) Value {
    std.debug.print("declaration\n", .{});
    const ptr = b.ir.allocaDupeZ(.Double(), var_name, gpa);
    //_ = b.ir.store(value, ptr);
    b.setVar(var_name, ptr);
    return ptr;
}

pub fn mainSection(b: *Builder) !void {
    //const fnName = tokens[2];

    const fun = b.module.addFn("main", .create(llvm.Type.Int32(), &.{ llvm.Type.Int32(), llvm.Type.Int8().Ptr().Ptr() }, false));
    const entry = fun.appendBasicBlock("entry");
    b.ir.positionAtEnd(entry);
}

pub fn section(b: *Builder, gpa: std.mem.Allocator, name: []const u8) !void {
    //const fnName = tokens[2];
    const name_nt = gpa.dupeZ(u8, name) catch @panic("OOM");
    defer gpa.free(name_nt);

    const fun = b.module.addFn(name_nt, .create(llvm.Type.Int32(), &.{ llvm.Type.Int32(), llvm.Type.Int8().Ptr().Ptr() }, false));
    const entry = fun.appendBasicBlock("entry");
    b.ir.positionAtEnd(entry);
    b.fns.put(name, fun) catch @panic("OOM");
}

pub fn call(b: *Builder, name: []const u8) !void {
    std.debug.print("getting fn {s}\n", .{name});
    const fun = b.fns.get(name) orelse @panic("wrong fns");

    _ = b.ir.call(fun, &.{}, "");
}
