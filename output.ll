; ModuleID = 'programme'
source_filename = "programme"

@fmt_d = internal unnamed_addr constant [6 x i8] c"%.2f\0A\00"
@fmt_s = internal unnamed_addr constant [4 x i8] c"%s\0A\00"

declare i8 @printf(ptr, ...)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.sqrt.f64(double) #0

declare double @llvm.cbrt.f64(double)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.pow.f64(double) #0

define i32 @main(i32 %0, ptr %1) {
entry:
  %i = alloca double, align 8
  store double 4.000000e+00, ptr %i, align 8
  %2 = load double, ptr %i, align 8
  %3 = call i8 (ptr, ...) @printf(ptr @fmt_d, double 1.380000e+02)
  ret i32 0
}

attributes #0 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
