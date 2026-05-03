; ModuleID = 'programme'
source_filename = "programme"

@fmt_d = internal unnamed_addr constant [6 x i8] c"%.2f\0A\00"
@fmt_s = internal unnamed_addr constant [4 x i8] c"%s\0A\00"
@message = private unnamed_addr constant [9 x i8] c"Distance\00", align 1

declare i8 @printf(ptr, ...)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.sqrt.f64(double) #0

declare double @llvm.cbrt.f64(double)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.pow.f64(double) #0

declare void @say(ptr)

declare void @sleep(i32)

define double @"hypot\C3\A9nuse"(double %0, double %1) {
entree:
  call void @say(ptr @message)
  %2 = fmul double %0, %0
  %3 = fmul double %1, %1
  %4 = fadd double %3, %2
  %5 = call double @llvm.sqrt.f64(double %4)
  ret double %5
}

define i32 @main(i32 %0, ptr %1) {
entree:
  %2 = call double @llvm.sqrt.f64(double 2.000000e+00)
  %3 = call double @llvm.sqrt.f64(double 2.000000e+00)
  %4 = call double @"hypot\C3\A9nuse"(double %2, double %3)
  %5 = call i8 (ptr, ...) @printf(ptr @fmt_d, double %4)
  ret i32 0
}

attributes #0 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
