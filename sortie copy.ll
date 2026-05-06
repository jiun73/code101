; ModuleID = 'programme'
source_filename = "programme"

@fmt_b = internal unnamed_addr constant [4 x i8] c"%d\0A\00"
@fmt_d = internal unnamed_addr constant [6 x i8] c"%.2f\0A\00"
@fmt_s = internal unnamed_addr constant [4 x i8] c"%s\0A\00"
@message = private unnamed_addr constant [9 x i8] c"Distance\00", align 1
@var_name = private unnamed_addr constant [2 x i8] c"x\00", align 1
@var_name.1 = private unnamed_addr constant [2 x i8] c"y\00", align 1

declare i8 @printf(ptr, ...)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.sqrt.f64(double) #0

declare double @llvm.cbrt.f64(double)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.pow.f64(double) #0

declare void @say(ptr)

declare double @read_double(ptr)

declare void @sleep(i32)

define double @"hypot\C3\A9nuse"(double %0, double %1) {
entree:
  call void @say(ptr @message)
  %2 = load double, double %0, align 8
  %3 = fmul double %2, %2
  %4 = load double, double %1, align 8
  %5 = fmul double %4, %4
  %6 = fadd double %3, %5
  %7 = call double @llvm.sqrt.f64(double %6)
  ret double %7
}

define i32 @main(i32 %0, ptr %1) {
entree:
  %x = alloca double, align 8
  %2 = call double @read_double(ptr @var_name)
  store double %2, ptr %x, align 8
  %y = alloca double, align 8
  %3 = call double @read_double(ptr @var_name.1)
  store double %3, ptr %y, align 8
  %4 = call double @"hypot\C3\A9nuse"(ptr %x, ptr %y)
  %5 = call i8 (ptr, ...) @printf(ptr @fmt_d, double %4)
  ret i32 0
}

attributes #0 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
