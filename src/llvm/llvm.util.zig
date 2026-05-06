const zllvm = @import("zllvm.zig");

pub fn toAsm(module: zllvm.Module) void {
    const triple = zllvm.TargetMachine.getDefaultTargetTriple();
    const trg = zllvm.Target.getFromTriple(triple);
    const cpu = zllvm.TargetMachine.getHostCPUName();
    const cpu_features = zllvm.TargetMachine.getHostCPUFeatures();

    const target_machine = zllvm.TargetMachine.create(trg, triple, cpu, cpu_features, .LLVMCodeGenLevelNone, .LLVMRelocDefault, .LLVMCodeModelDefault);

    const pm = zllvm.PassManager.create();
    const outfile = "output";

    target_machine.EmitToFile(module, outfile, .LLVMAssemblyFile);
    pm.run(module);
}
