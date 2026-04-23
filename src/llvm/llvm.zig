const llvm = @import("cllvm");
const std = @import("std");
pub const C = llvm;
pub const clang = @import("clang");
pub const irreader = llvm.irreader;
pub const linker = llvm.linker;
pub const target = llvm.target;
pub const types = llvm.types;
pub const core = llvm.core;
pub const jit = llvm.jit;
pub const engine = llvm.engine;
pub const support = llvm.support;
pub const error_handling = llvm.error_handling;
pub const errors = llvm.errors;
pub const target_machine = llvm.target_machine;
pub const util = @import("llvm.util.zig");

pub const Error = error{
    loadLibraryPermanentlyError,
    parseIrInContextError,
    linkError,
    CouldNotCreateExecutionEngine,
};

pub fn parseIrInContext(ctx: Context, buff: MemBuff) Error!Module {
    var mod: types.LLVMModuleRef = undefined;
    if (irreader.LLVMParseIRInContext(ctx.toC(), buff.toC(), &mod, null) != 0) {
        return Error.parseIrInContextError;
    }
    return .toZig(mod);
}

pub fn loadLibraryPermanently(path: [:0]const u8) Error!void {
    if (support.LLVMLoadLibraryPermanently(path) != 0) {
        return Error.loadLibraryPermanentlyError;
    }
}

pub fn initializeNativeTarget() void {
    _ = target.LLVMInitializeNativeTarget();
}

pub fn initializeNativeAsmPrinter() void {
    _ = target.LLVMInitializeNativeAsmPrinter();
}

pub fn initializeNativeAsmParser() void {
    _ = target.LLVMInitializeNativeAsmParser();
}

pub fn initializeAllTargetInfos() void {
    _ = target.LLVMInitializeAllTargetInfos();
}

pub fn initializeAllTargets() void {
    _ = target.LLVMInitializeAllTargets();
}

pub fn initializeAllTargetMCs() void {
    _ = target.LLVMInitializeAllTargetMCs();
}

pub const MemBuff = struct {
    ref: types.LLVMMemoryBufferRef,

    pub fn fromFile(path: [:0]const u8) MemBuff {
        var membuff: types.LLVMMemoryBufferRef = undefined;
        core.LLVMCreateMemoryBufferWithContentsOfFile(path, &membuff, null);
        return .toZig(membuff);
    }

    pub fn fromSlice(data: []const u8, name: [:0]const u8) MemBuff {
        const membuff: types.LLVMMemoryBufferRef = core.LLVMCreateMemoryBufferWithMemoryRange(@ptrCast(data.ptr), data.len, name, 0);
        return .toZig(membuff);
    }

    pub fn dispose(buff: MemBuff) void {
        core.LLVMDisposeMemoryBuffer(buff.toC());
    }

    pub fn toZig(ref: types.LLVMMemoryBufferRef) MemBuff {
        return .{ .ref = ref };
    }

    pub fn toC(t: MemBuff) types.LLVMMemoryBufferRef {
        return t.ref;
    }
};

pub const Module = struct {
    ref: types.LLVMModuleRef,

    pub fn getContext(module: Module) Context {
        return .toZig(core.LLVMGetModuleContext(module.toC()));
    }

    pub fn create(name: [*:0]const u8) Module {
        return .toZig(core.LLVMModuleCreateWithName(name));
    }

    pub fn dispose(module: Module) void {
        return core.LLVMDisposeModule(module.ref);
    }

    pub fn dump(module: Module) void {
        core.LLVMDumpModule(module.ref);
    }

    pub fn link(dest: Module, src: Module) Error!void {
        if (linker.LLVMLinkModules2(dest.toC(), src.toC()) != 0) {
            return Error.linkError;
        }
    }

    pub fn printToFile(module: Module, path: [*:0]const u8) void {
        _ = core.LLVMPrintModuleToFile(module.toC(), path, null);
    }

    pub fn writeBitecodeToFile(module: Module, path: [*:0]const u8) c_int {
        return llvm.bitwriter.LLVMWriteBitcodeToFile(module.toC(), path);
    }

    pub fn addAlias2(module: Module, ty: Type, addrSpace: c_uint, aliasee: Value, name: [*:0]const u8) Value {
        return .toZig(core.LLVMAddAlias2(module.toC(), ty.toC(), addrSpace, aliasee.toC(), name));
    }

    pub fn addGlobal(module: Module, ty: Type, name: [*:0]const u8) Value {
        return .toZig(core.LLVMAddGlobal(module.toC(), ty.toC(), name));
    }

    pub fn addGlobalIFunc(module: Module, name: [:0]const u8, ty: Type, addrSpace: c_uint, resolver: Value) Value {
        return .toZig(core.LLVMAddGlobalIFunc(module.toC(), name, name.len, ty, addrSpace, resolver));
    }

    pub fn addGlobalInAddressSpace(module: Module, name: [*:0]const u8, ty: Type, addrSpace: c_uint) Value {
        return .toZig(core.LLVMAddGlobalInAddressSpace(module.toC(), ty, name, addrSpace));
    }

    pub fn appendInlineAsm(module: Module, asmb: [*:0]const u8, len: usize) Value {
        return .toZig(core.LLVMAppendModuleInlineAsm(module.toC(), asmb, len));
    }

    pub fn setTarget(module: Module, triple: [*:0]const u8) void {
        core.LLVMSetTarget(module, triple);
    }

    pub fn addFn(module: Module, name: [*:0]const u8, t: FunctionType) Function {
        return .toZig(core.LLVMAddFunction(module.ref, name, t.toC()));
    }

    pub fn getFn(module: Module, name: [*:0]const u8) Function {
        return .toZig(core.LLVMGetNamedFunction(module.ref, name));
    }

    pub fn getGlobal(module: Module, name: [*:0]const u8) Value {
        return .toZig(core.LLVMGetNamedGlobal(module.ref, name));
    }

    pub fn createBasicBlock(name: [*:0]const u8) BasicBlock {
        return .toZig(core.LLVMCreateBasicBlockInContext(core.LLVMGetGlobalContext(), name));
    }

    pub fn toZig(ref: types.LLVMModuleRef) Module {
        return .{ .ref = ref };
    }

    pub fn toC(t: Module) types.LLVMModuleRef {
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

pub const Function = struct {
    value: *types.LLVMOpaqueValue,

    pub fn toZig(value: ?*types.LLVMOpaqueValue) Function {
        return .{ .value = value orelse @panic("null") };
    }

    pub fn toC(t: Function) *types.LLVMOpaqueValue {
        return t.value;
    }

    pub fn appendBasicBlock(fun: Function, name: [*:0]const u8) BasicBlock {
        return .toZig(core.LLVMAppendBasicBlock(fun.toC(), name));
    }

    pub fn getParam(fun: Function, index: usize) Value {
        return .toZig(core.LLVMGetParam(fun.toC(), @intCast(index)));
    }

    pub fn getParams(fun: Function) []const Value {
        var ptr: ?*types.LLVMValueRef = null;
        core.LLVMGetParams(fun.toC(), &ptr);
        const len = core.LLVMCountParams(fun.toC());
        return .{ .ptr = ptr, .len = len };
    }

    pub fn getType(fun: Function) FunctionType {
        return .toZig(core.LLVMGlobalGetValueType(fun.toC()));
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

pub const Type = struct {
    ref: types.LLVMTypeRef,

    pub fn Void() Type {
        return .toZig(core.LLVMVoidType());
    }

    pub fn Int8() Type {
        return .toZig(core.LLVMInt8Type());
    }

    pub fn Int16() Type {
        return .toZig(core.LLVMInt16Type());
    }

    pub fn Int32() Type {
        return .toZig(core.LLVMInt32Type());
    }

    pub fn Int64() Type {
        return .toZig(core.LLVMInt64Type());
    }

    pub fn Float() Type {
        return .toZig(core.LLVMFloatType());
    }

    pub fn Double() Type {
        return .toZig(core.LLVMDoubleType());
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

    pub fn toString(v: Type) [*:0]const u8 {
        return core.LLVMPrintTypeToString(v.toC());
    }
};

pub const Linkage = types.LLVMLinkage;

pub const Value = struct {
    ref: types.LLVMValueRef,

    pub fn getType(v: Value) Type {
        return .toZig(core.LLVMTypeOf(v.toC()));
    }

    pub fn setInitializer(v: Value, c: Value) Value {
        core.LLVMSetInitializer(v.toC(), c.toC());
        return v;
    }

    pub fn setLinkage(v: Value, linkage: Linkage) Value {
        core.LLVMSetLinkage(v.toC(), linkage);
        return v;
    }

    pub fn setUnnamedAddr(v: Value, hasUnnamedAddr: bool) Value {
        core.LLVMSetUnnamedAddr(v.toC(), @intFromBool(hasUnnamedAddr));
        return v;
    }

    pub fn setGlobalConstant(v: Value, isConstant: bool) Value {
        core.LLVMSetGlobalConstant(v.toC(), @intFromBool(isConstant));
        return v;
    }

    pub fn constString(str: [*:0]const u8, dontNullTerminate: bool) Value {
        return .toZig(core.LLVMConstString(str, @intCast(std.mem.len(str)), @intFromBool(dontNullTerminate)));
    }

    pub fn constUInt8(value: u8) Value {
        return .toZig(core.LLVMConstInt(Type.Int8().toC(), value, 0));
    }

    pub fn constUInt16(value: u16) Value {
        return .toZig(core.LLVMConstInt(Type.Int16().toC(), value, 0));
    }

    pub fn constUInt32(value: u32) Value {
        return .toZig(core.LLVMConstInt(Type.Int32().toC(), value, 0));
    }

    pub fn constUInt64(value: u64) Value {
        return .toZig(core.LLVMConstInt(Type.Int64().toC(), value, 0));
    }

    pub fn constInt8(value: u8) Value {
        return .toZig(core.LLVMConstInt(Type.Int8().toC(), value, 1));
    }

    pub fn constInt16(value: u16) Value {
        return .toZig(core.LLVMConstInt(Type.Int16().toC(), value, 1));
    }

    pub fn constInt32(value: u32) Value {
        return .toZig(core.LLVMConstInt(Type.Int32().toC(), value, 1));
    }

    pub fn constFloat(value: f32) Value {
        return .toZig(core.LLVMConstReal(Type.Float().toC(), value));
    }

    pub fn constDouble(value: f64) Value {
        return .toZig(core.LLVMConstReal(Type.Double().toC(), value));
    }

    pub fn constInt64(value: u64) Value {
        return .toZig(core.LLVMConstInt(Type.Int64().toC(), value, 1));
    }

    pub fn toString(v: Value) [*:0]const u8 {
        return core.LLVMPrintValueToString(v.toC());
    }

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

    pub fn load2(builder: Builder, ty: Type, ptr: Value, name: [*:0]const u8) Value {
        return .toZig(core.LLVMBuildLoad2(builder.toC(), ty.toC(), ptr.toC(), name));
    }

    pub fn store(builder: Builder, value: Value, ptr: Value) Value {
        return .toZig(core.LLVMBuildStore(builder.toC(), value.toC(), ptr.toC()));
    }

    pub fn alloca(builder: Builder, ty: Type, name: [*:0]const u8) Value {
        return .toZig(core.LLVMBuildAlloca(builder.toC(), ty.toC(), name));
    }

    pub fn allocaDupeZ(builder: Builder, ty: Type, name: []const u8, gpa: std.mem.Allocator) Value {
        const var_name_nt = gpa.dupeZ(u8, name) catch @panic("OOM");
        defer gpa.free(var_name_nt);
        return builder.alloca(ty, var_name_nt);
    }

    pub fn mul(builder: Builder, LHS: Value, RHS: Value, retName: [*:0]const u8) Value {
        return .toZig(core.LLVMBuildMul(builder.toC(), LHS.toC(), RHS.toC(), retName));
    }

    pub fn frem(builder: Builder, LHS: Value, RHS: Value, retName: [*:0]const u8) Value {
        return .toZig(core.LLVMBuildFRem(builder.toC(), LHS.toC(), RHS.toC(), retName));
    }

    pub fn fdiv(builder: Builder, LHS: Value, RHS: Value, retName: [*:0]const u8) Value {
        return .toZig(core.LLVMBuildFDiv(builder.toC(), LHS.toC(), RHS.toC(), retName));
    }

    pub fn fmul(builder: Builder, LHS: Value, RHS: Value, retName: [*:0]const u8) Value {
        return .toZig(core.LLVMBuildFMul(builder.toC(), LHS.toC(), RHS.toC(), retName));
    }

    pub fn add(builder: Builder, LHS: Value, RHS: Value, retName: [*:0]const u8) Value {
        return .toZig(core.LLVMBuildAdd(builder.toC(), LHS.toC(), RHS.toC(), retName));
    }

    pub fn fadd(builder: Builder, LHS: Value, RHS: Value, retName: [*:0]const u8) Value {
        return .toZig(core.LLVMBuildFAdd(builder.toC(), LHS.toC(), RHS.toC(), retName));
    }

    pub fn sub(builder: Builder, LHS: Value, RHS: Value, retName: [*:0]const u8) Value {
        return .toZig(core.LLVMBuildSub(builder.toC(), LHS.toC(), RHS.toC(), retName));
    }

    pub fn fsub(builder: Builder, LHS: Value, RHS: Value, retName: [*:0]const u8) Value {
        return .toZig(core.LLVMBuildFSub(builder.toC(), LHS.toC(), RHS.toC(), retName));
    }

    pub fn load(builder: Builder, ty: Type, val: Value, retName: [*:0]const u8) Value {
        return .toZig(core.LLVMBuildLoad2(builder.toC(), ty.toC(), val.toC(), retName));
    }

    pub fn call(builder: Builder, fun: Function, args: []const Value, retName: [*:0]const u8) Value {
        return .toZig(core.LLVMBuildCall2(builder.toC(), fun.getType().toC(), fun.toC(), @ptrCast(@constCast(args)), @intCast(args.len), retName));
    }

    pub fn ret(builder: Builder, value: Value) Value {
        return .toZig(core.LLVMBuildRet(builder.ref, value.ref));
    }

    pub fn retvoid(builder: Builder) Value {
        return .toZig(core.LLVMBuildRetVoid(builder.ref));
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

pub const Target = struct {
    ref: types.LLVMTargetRef,

    pub fn getFromTriple(triple: [*:0]const u8) Target {
        var ref: types.LLVMTargetRef = null;
        _ = llvm.target_machine.LLVMGetTargetFromTriple(@ptrCast(triple), @ptrCast(&ref), null);
        return .toZig(ref);
    }

    pub fn toZig(ref: types.LLVMTargetRef) Target {
        return .{ .ref = ref };
    }

    pub fn toC(t: Target) types.LLVMTargetRef {
        return t.ref;
    }
};

pub const CodeGenOptLevel = types.LLVMCodeGenOptLevel;
pub const RelocMode = types.LLVMRelocMode;
pub const CodeModel = types.LLVMCodeModel;
pub const CodeGenFileType = types.LLVMCodeGenFileType;

pub const TargetMachine = struct {
    ref: types.LLVMTargetMachineRef,

    pub fn toZig(ref: types.LLVMTargetMachineRef) TargetMachine {
        return .{ .ref = ref };
    }

    pub fn toC(t: TargetMachine) types.LLVMTargetMachineRef {
        return t.ref;
    }

    pub fn getDefaultTargetTriple() [*:0]const u8 {
        return @ptrCast(llvm.target_machine.LLVMGetDefaultTargetTriple());
    }

    pub fn getHostCPUName() [*:0]const u8 {
        return @ptrCast(llvm.target_machine.LLVMGetHostCPUName());
    }

    pub fn getHostCPUFeatures() [*:0]const u8 {
        return @ptrCast(llvm.target_machine.LLVMGetHostCPUFeatures());
    }

    pub fn create(
        trg: Target,
        target_name: [*:0]const u8,
        cpu: [*:0]const u8,
        cpu_features: [*:0]const u8,
        codeGenOptLevel: CodeGenOptLevel,
        relocMode: RelocMode,
        codeModel: CodeModel,
    ) TargetMachine {
        return .toZig(
            llvm.target_machine.LLVMCreateTargetMachine(
                @ptrCast(trg.toC()),
                target_name,
                cpu,
                cpu_features,
                codeGenOptLevel,
                relocMode,
                codeModel,
            ),
        );
    }

    pub fn EmitToFile(tm: TargetMachine, module: Module, outfile: [:0]const u8, codegen: CodeGenFileType) void {
        _ = llvm.target_machine.LLVMTargetMachineEmitToFile(
            tm.toC(),
            module.toC(),
            outfile,
            codegen,
            null,
        );
    }
};

pub const PassManager = struct {
    ref: llvm.types.LLVMPassManagerRef,

    pub fn toZig(ref: types.LLVMPassManagerRef) PassManager {
        return .{ .ref = ref };
    }

    pub fn toC(t: PassManager) types.LLVMPassManagerRef {
        return t.ref;
    }

    pub fn create() PassManager {
        return .toZig(llvm.core.LLVMCreatePassManager());
    }

    pub fn run(pm: PassManager, module: Module) void {
        _ = llvm.core.LLVMRunPassManager(pm.toC(), module.toC());
    }
};

pub const OrcLLJitBuilder = struct {
    ref: llvm.types.LLVMOrcLLJITBuilderRef,

    pub fn toZig(ref: types.LLVMOrcLLJITBuilderRef) OrcLLJitBuilder {
        return .{ .ref = ref };
    }

    pub fn toC(t: OrcLLJitBuilder) types.LLVMOrcLLJITBuilderRef {
        return t.ref;
    }

    pub fn create() Context {
        return .toZig(jit.LLVMOrcCreateLLJITBuilder());
    }

    pub fn dispose(c: OrcLLJitBuilder) void {
        jit.LLVMOrcDisposeLLJITBuilder(c.toC());
    }
};

pub const OrcLLJit = struct {
    ref: llvm.types.LLVMOrcLLJITRef,

    pub fn toZig(ref: types.LLVMOrcLLJITRef) OrcLLJit {
        return .{ .ref = ref };
    }

    pub fn toC(t: OrcLLJit) types.LLVMOrcLLJITRef {
        return t.ref;
    }

    pub fn create(builder: OrcLLJitBuilder) Context {
        var ref: types.LLVMOrcLLJITRef = undefined;
        jit.LLVMOrcCreateLLJIT(&ref, builder.toC());
        return .toZig(ref);
    }

    pub fn dispose(c: Context) void {
        jit.LLVMOrcDisposeLLJIT(c.toC());
    }
};

pub fn linkInMCJIT() void {
    engine.LLVMLinkInMCJIT();
}

pub const ExecutionEngine = struct {
    ref: llvm.types.LLVMExecutionEngineRef,

    pub fn toZig(ref: llvm.types.LLVMExecutionEngineRef) ExecutionEngine {
        return .{ .ref = ref };
    }

    pub fn toC(t: ExecutionEngine) llvm.types.LLVMExecutionEngineRef {
        return t.ref;
    }

    pub fn createForModule(mod: Module) Error!ExecutionEngine {
        var ref: llvm.types.LLVMExecutionEngineRef = undefined;
        if (engine.LLVMCreateExecutionEngineForModule(&ref, mod.toC(), null) != 0) {
            return Error.CouldNotCreateExecutionEngine;
        }
        return .toZig(ref);
    }

    pub fn findFunction(exec: ExecutionEngine, name: [:0]const u8) Function {
        var fun: llvm.types.LLVMValueRef = undefined;
        if (engine.LLVMFindFunction(exec.toC(), name, &fun) == 1) {
            @panic("error");
        }
        return .toZig(fun);
    }

    pub fn runFunctionAsMain(exec: ExecutionEngine, fun: Function, argc: c_uint, argv: [][:0]const u8) c_int {
        return engine.LLVMRunFunctionAsMain(exec.toC(), fun.toC(), argc, @ptrCast(argv), null);
    }
};

pub const Context = struct {
    ref: llvm.types.LLVMContextRef,

    pub fn toZig(ref: types.LLVMContextRef) Context {
        return .{ .ref = ref };
    }

    pub fn toC(t: Context) types.LLVMContextRef {
        return t.ref;
    }

    pub fn create() Context {
        return .toZig(core.LLVMContextCreate());
    }

    pub fn global() Context {
        return .toZig(core.LLVMGetGlobalContext());
    }

    pub fn dispose(c: Context) void {
        core.LLVMContextDispose(c.toC());
    }
};
