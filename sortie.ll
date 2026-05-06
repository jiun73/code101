; ModuleID = 'programme'
source_filename = "programme"

@fmt_b = internal unnamed_addr constant [4 x i8] c"%d\0A\00"
@fmt_d = internal unnamed_addr constant [6 x i8] c"%.2f\0A\00"
@fmt_s = internal unnamed_addr constant [4 x i8] c"%s\0A\00"

declare i8 @printf(ptr, ...)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.sqrt.f64(double) #0

declare double @llvm.cbrt.f64(double)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.pow.f64(double) #0

declare void @say(ptr)

declare void @sleep(i32)

define i32 @main(i32 %0, ptr %1) {
entree:
  %x = alloca double, align 8
  store double 3.000000e+00, ptr %x, align 8
  %2 = call i8 (ptr, ...) @printf(ptr @fmt_d, ptr %x)
  %3 = fcmp ogt ptr %x, double 2.000000e+00
  %4 = call i8 (ptr, ...) @printf(ptr @fmt_b, i1 %3)
  ret i32 0
}

attributes #0 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
