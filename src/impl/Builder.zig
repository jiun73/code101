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

    pub fn getRef(vr: ValueRef) Ref {
        switch (vr) {
            .ref => |ref| return ref,
            else => @panic("trying to cast value to ref"),
        }
    }
};

pub const Error = error{VariableNotDeclared};

module: llvm.Module,
ir: llvm.Builder,
vars: std.StringHashMap(Value),

printfFn: llvm.Function,
sqrtFn: llvm.Function,
cbrtFn: llvm.Function,
powFn: llvm.Function,

fmtS: llvm.Value,
fmtD: llvm.Value,

pub fn init(gpa: std.mem.Allocator, module: llvm.Module) Builder {
    const builder = llvm.Builder.create();

    const printfFn = module.addFn("printf", .create(llvm.Type.Int8(), &.{llvm.Type.Int8().Ptr()}, true));
    const sqrtFn = module.addFn("llvm.sqrt.f64", .create(llvm.Type.Double(), &.{llvm.Type.Double()}, false));
    const cbrtFn = module.addFn("llvm.cbrt.f64", .create(llvm.Type.Double(), &.{llvm.Type.Double()}, false));
    const powFn = module.addFn("llvm.pow.f64", .create(llvm.Type.Double(), &.{llvm.Type.Double()}, false));

    const fmt_d = llvm.Value.constString("%.2f\n", false);
    const fmt_d_val = module.addGlobal(fmt_d.getType(), "fmt_d").setInitializer(fmt_d).setGlobalConstant(true).setLinkage(.LLVMInternalLinkage).setUnnamedAddr(true);

    const fmt_s = llvm.Value.constString("%s\n", false);
    const fmt_s_val = module.addGlobal(fmt_s.getType(), "fmt_s").setInitializer(fmt_s).setGlobalConstant(true).setLinkage(.LLVMInternalLinkage).setUnnamedAddr(true);

    const vars = std.StringHashMap(Value).init(gpa);

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
    };
}

pub fn deinit(b: *Builder) void {
    b.vars.deinit();
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

pub fn getAndLoadValue(b: *Builder, var_name: []const u8) llvm.Value {
    const ptr = b.getVar(var_name);
    return b.ir.load2(ptr, "");
}

pub fn declare(b: *Builder, gpa: std.mem.Allocator, var_name: []const u8, value: Value) void {
    std.debug.print("declaration\n", .{});
    const ptr = b.ir.allocaDupeZ(.Double(), var_name, gpa);
    _ = b.ir.store(value, ptr);
    b.setLoadedVar(var_name, ptr);
}
