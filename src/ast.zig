const std = @import("std");
const llvm = @import("llvm.zig");
const target = llvm.target;
const types = llvm.types;
const core = llvm.core;

pub const VariableNode = struct {};

pub const FunctionNode = struct {};

pub const AnyNode = union(enum) {
    variable: VariableNode,
    function: FunctionNode,
};

pub const NodeBuilder = struct {
    node: AnyNode,
};

fn errorhandle(msg: [*:0]const u8) callconv(.c) void {
    std.debug.print("EROROOROROR {s}", .{msg});
}

pub const Builder = struct {
    gpa: std.mem.Allocator,
    module: llvm.Module,
    builder: llvm.Builder,
    counter: u32,

    vars: std.StringHashMap(llvm.Value),

    pub fn init(gpa: std.mem.Allocator) Builder {
        _ = target.LLVMInitializeNativeTarget();
        _ = target.LLVMInitializeNativeAsmPrinter();
        _ = target.LLVMInitializeNativeAsmParser();
        _ = target.LLVMInitializeAllTargetInfos();
        _ = target.LLVMInitializeAllTargets();
        _ = target.LLVMInitializeAllTargetMCs();
        llvm.error_handling.LLVMEnablePrettyStackTrace();
        llvm.error_handling.LLVMInstallFatalErrorHandler(errorhandle);

        // Create a new LLVM module
        const module = llvm.Module.create("test");
        const main_fn = module.addFnCreateType("dum", llvm.Type.Int32(), &.{ llvm.Type.Int32(), llvm.Type.Int8().Ptr().Ptr() }, false);

        const entry = main_fn.appendBasicBlock("entry");
        const builder = llvm.Builder.create();
        _ = module.addFnCreateType("printf", llvm.Type.Int8(), &.{llvm.Type.Int8().Ptr()}, true);
        //const gb = llvm.Module.createBasicBlock("global");
        builder.positionAtEnd(entry);
        _ = builder.globalStringPtr("%d\n", "fmt_d");
        _ = builder.globalStringPtr("%s\n", "fmt_s");
        _ = builder.retvoid();

        const vars = std.StringHashMap(llvm.Value).init(gpa);

        return .{
            .gpa = gpa,
            .counter = 0,
            .module = module,
            .builder = builder,
            .vars = vars,
        };
    }

    pub fn toEXE(builder: *Builder) void {
        const target_name = llvm.target_machine.LLVMGetDefaultTargetTriple();
        var target_ref: types.LLVMTargetRef = null;
        _ = llvm.target_machine.LLVMGetTargetFromTriple(target_name, @ptrCast(&target_ref), null);
        const cpu = llvm.target_machine.LLVMGetHostCPUName();
        const cpu_features = llvm.target_machine.LLVMGetHostCPUFeatures();

        std.debug.print("{s}\n{s}\n{s}\n", .{ target_name, cpu, cpu_features });
        std.debug.print("{any}\n", .{target_ref});

        const target_machine = llvm.target_machine.LLVMCreateTargetMachine(@ptrCast(target_ref), target_name, cpu, cpu_features, .LLVMCodeGenLevelNone, .LLVMRelocDefault, .LLVMCodeModelDefault);

        const pm: llvm.types.LLVMPassManagerRef = llvm.core.LLVMCreatePassManager();
        const outfile = "output";

        _ = llvm.target_machine.LLVMTargetMachineEmitToFile(target_machine, builder.module.toC(), outfile, .LLVMAssemblyFile, null);
        _ = llvm.core.LLVMRunPassManager(pm, builder.module.toC());
    }

    pub fn deinit(builder: *Builder) void {
        builder.vars.deinit();
    }
};
