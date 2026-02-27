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

    pub fn create(gpa: std.mem.Allocator) Builder {
        _ = target.LLVMInitializeNativeTarget();
        _ = target.LLVMInitializeNativeAsmPrinter();
        _ = target.LLVMInitializeNativeAsmParser();
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

        return .{
            .gpa = gpa,
            .counter = 0,
            .module = module,
            .builder = builder,
        };
    }
};
