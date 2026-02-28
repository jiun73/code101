const std = @import("std");
const llvm = @import("llvm");
const target = llvm.target;
const types = llvm.types;
const core = llvm.core;

const b = @import("llvm.zig");

pub fn e() void {
    // Initialize LLVM
    _ = target.LLVMInitializeNativeTarget();
    _ = target.LLVMInitializeNativeAsmPrinter();
    _ = target.LLVMInitializeNativeAsmParser();

    // Create a new LLVM module
    const module = b.Module.create("test");

    const printf_fn = module.addFn("printf", .create(b.Type.Int8(), &.{b.Type.Int8().Ptr()}, true));
    const main_fn = module.addFn("main", .create(b.Type.Int32(), &.{ b.Type.Int32(), b.Type.Int8().Ptr().Ptr() }, false));

    const entry = main_fn.appendBasicBlock("entry");
    const builder = b.Builder.create();
    builder.positionAtEnd(entry);
    const str = builder.globalStringPtr("%d\n", "str");
    const str2 = builder.globalStringPtr("%s\n", "str2");

    const arg1 = main_fn.getParam(0);
    const arg2 = main_fn.getParam(1);

    const first_cmd = builder.load(b.Type.Int8().Ptr(), arg2, "str_cmd");

    const ttt = module.getFn("printf");

    _ = builder.call(ttt, &.{ str, arg1 }, "test");
    _ = builder.call(printf_fn, &.{ str2, first_cmd }, "test2");

    //const sum = builder.buildAdd(arg1, arg2, "sum");

    //_ = builder.buildCall(printf_fn, &.{ str, sum }, "test");

    _ = builder.ret(arg1);

    // Dump the LLVM module to stdout
    module.dump();
    _ = module.writeBitecodeToFile("./output.bc");

    // Clean up LLVM resources
    builder.dispose();
    module.dispose();
    core.LLVMShutdown();
}
