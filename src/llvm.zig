const llvm = @import("llvm");
const target = llvm.target;
const types = llvm.types;
const core = llvm.core;

pub const Module = struct {
    ref: types.LLVMModuleRef,

    pub fn create(name: [*:0]const u8) Module {
        return .toZig(core.LLVMModuleCreateWithName(name));
    }

    pub fn dispose(module: Module) void {
        return core.LLVMDisposeModule(module.ref);
    }

    pub fn dump(module: Module) void {
        core.LLVMDumpModule(module.ref);
    }

    pub fn writeBitecodeToFile(module: Module, path: [*:0]const u8) c_int {
        return llvm.bitwriter.LLVMWriteBitcodeToFile(module.toC(), path);
    }

    pub fn addFn(module: Module, name: [*:0]const u8, t: FunctionType) FunctionWithType {
        const fun = Function.toZig(core.LLVMAddFunction(module.ref, name, t.toC()));
        return .create(fun, t);
    }

    pub fn addFnCreateType(module: Module, name: [*:0]const u8, ret: Type, params: []const Type, isVarArg: bool) FunctionWithType {
        const t: FunctionType = .create(ret, params, isVarArg);
        const fun: Function = .toZig(core.LLVMAddFunction(module.ref, name, t.toC()));
        return .create(fun, t);
    }

    pub fn toZig(ref: types.LLVMModuleRef) Module {
        return .{ .ref = ref };
    }

    pub fn toC(t: Module) types.LLVMModuleRef {
        return t.ref;
    }
};

pub const Type = struct {
    ref: types.LLVMTypeRef,

    pub fn Int8() Type {
        return .toZig(core.LLVMInt8Type());
    }

    pub fn Int32() Type {
        return .toZig(core.LLVMInt32Type());
    }

    pub fn Ptr(t: Type) Type {
        return .toZig(core.LLVMPointerType(t.toC(), 0));
    }

    pub fn PtrAddrSpace(t: Type, addrSpace: c_uint) Type {
        return .toZig(core.LLVMPointerType(t.toC(), addrSpace));
    }

    pub fn toZig(ref: types.LLVMTypeRef) Type {
        return .{ .ref = ref };
    }

    pub fn toC(t: Type) types.LLVMTypeRef {
        return t.ref;
    }
};

pub const FunctionType = struct {
    ref: types.LLVMTypeRef,

    pub fn create(ret: Type, params: []const Type, isVarArg: bool) FunctionType {
        return .toZig(core.LLVMFunctionType(ret.ref, @ptrCast(@constCast(params)), @intCast(params.len), if (isVarArg) 1 else 0));
    }

    pub fn toZig(ref: types.LLVMTypeRef) FunctionType {
        return .{ .ref = ref };
    }

    pub fn toC(t: FunctionType) types.LLVMTypeRef {
        return t.ref;
    }
};

pub const FunctionWithType = struct {
    t: FunctionType,
    fun: Function,

    pub fn create(fun: Function, t: FunctionType) FunctionWithType {
        return .{ .fun = fun, .t = t };
    }

    pub fn appendBasicBlock(fun: FunctionWithType, name: [*:0]const u8) BasicBlock {
        return fun.fun.appendBasicBlock(name);
    }

    pub fn getParam(fun: FunctionWithType, index: usize) Value {
        return fun.fun.getParam(index);
    }
};

pub const Function = struct {
    value: ?*types.LLVMOpaqueValue,

    pub fn toZig(value: ?*types.LLVMOpaqueValue) Function {
        return .{ .value = value };
    }

    pub fn toC(t: Function) ?*types.LLVMOpaqueValue {
        return t.value;
    }

    pub fn appendBasicBlock(fun: Function, name: [*:0]const u8) BasicBlock {
        return .toZig(core.LLVMAppendBasicBlock(fun.toC(), name));
    }

    pub fn getParam(fun: Function, index: usize) Value {
        return .toZig(core.LLVMGetParam(fun.toC(), @intCast(index)));
    }
};

pub const BasicBlock = struct {
    ref: types.LLVMBasicBlockRef,

    pub fn toZig(ref: types.LLVMBasicBlockRef) BasicBlock {
        return .{ .ref = ref };
    }

    pub fn toC(t: BasicBlock) types.LLVMBasicBlockRef {
        return t.ref;
    }
};

pub const Value = struct {
    ref: types.LLVMValueRef,

    pub fn toZig(ref: types.LLVMValueRef) Value {
        return .{ .ref = ref };
    }

    pub fn toC(t: Value) types.LLVMValueRef {
        return t.ref;
    }
};

pub const Builder = struct {
    ref: types.LLVMBuilderRef,

    pub fn create() Builder {
        return .toZig(core.LLVMCreateBuilder());
    }

    pub fn dispose(module: Builder) void {
        return core.LLVMDisposeBuilder(module.toC());
    }

    pub fn positionAtEnd(builder: Builder, block: BasicBlock) void {
        core.LLVMPositionBuilderAtEnd(builder.toC(), block.toC());
    }

    pub fn add(builder: Builder, LHS: Value, RHS: Value, retName: [*:0]const u8) Value {
        return .toZig(core.LLVMBuildAdd(builder.toC(), LHS.toC(), RHS.toC(), retName));
    }

    pub fn load(builder: Builder, ty: Type, val: Value, retName: [*:0]const u8) Value {
        return .toZig(core.LLVMBuildLoad2(builder.toC(), ty.toC(), val.toC(), retName));
    }

    pub fn call(builder: Builder, fun: FunctionWithType, args: []const Value, retName: [*:0]const u8) Value {
        return .toZig(core.LLVMBuildCall2(builder.toC(), fun.t.toC(), fun.fun.toC(), @ptrCast(@constCast(args)), @intCast(args.len), retName));
    }

    pub fn ret(builder: Builder, value: Value) Value {
        return .toZig(core.LLVMBuildRet(builder.ref, value.ref));
    }

    pub fn globalStringPtr(builder: Builder, value: [*:0]const u8, name: [*:0]const u8) Value {
        return .toZig(core.LLVMBuildGlobalStringPtr(builder.toC(), value, name));
    }

    pub fn toZig(ref: types.LLVMBuilderRef) Builder {
        return .{ .ref = ref };
    }

    pub fn toC(t: Builder) types.LLVMBuilderRef {
        return t.ref;
    }
};
