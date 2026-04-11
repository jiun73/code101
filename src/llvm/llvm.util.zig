const llvm = @import("llvm.zig");

pub fn toAsm(module: llvm.Module) void {
    const triple = llvm.TargetMachine.getDefaultTargetTriple();
    const trg = llvm.Target.getFromTriple(triple);
    const cpu = llvm.TargetMachine.getHostCPUName();
    const cpu_features = llvm.TargetMachine.getHostCPUFeatures();

    const target_machine = llvm.TargetMachine.create(trg, triple, cpu, cpu_features, .LLVMCodeGenLevelNone, .LLVMRelocDefault, .LLVMCodeModelDefault);

    const pm = llvm.PassManager.create();
    const outfile = "output";

    target_machine.EmitToFile(module, outfile, .LLVMAssemblyFile);
    pm.run(module);
}
