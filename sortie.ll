; ModuleID = 'programme'
source_filename = "programme"

@fmt_b = internal unnamed_addr constant [4 x i8] c"%d\0A\00"
@fmt_d = internal unnamed_addr constant [6 x i8] c"%.2f\0A\00"
@fmt_s = internal unnamed_addr constant [4 x i8] c"%s\0A\00"
@var_name = private unnamed_addr constant [2 x i8] c"i\00", align 1

declare i8 @printf(ptr, ...)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.sqrt.f64(double) #0

declare double @llvm.cbrt.f64(double)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.pow.f64(double) #0

declare void @say(ptr)

declare void @say_double(double)

declare double @read_double(ptr)

declare void @sleep(i32)

define i1 @"est un nombre premier"(double %0) {
entree:
  br label %"1"

"1":                                              ; preds = %entree
  %1 = call i8 (ptr, ...) @printf(ptr @fmt_d, double %0)
  %2 = fcmp oeq double %0, 0.000000e+00
  %3 = fcmp oeq double %0, 1.000000e+00
  %4 = or i1 %2, %3
  br i1 %4, label %true, label %false

true:                                             ; preds = %"1"
  ret i1 false

false:                                            ; preds = %"1"
  %n = alloca double, align 8
  store double 2.000000e+00, ptr %n, align 8
  br label %then

then:                                             ; preds = %false
  br label %"2"

"2":                                              ; preds = %true4, %then
  %5 = load double, ptr %n, align 8
  %6 = call i8 (ptr, ...) @printf(ptr @fmt_d, double %5)
  %7 = call double @llvm.sqrt.f64(double %0)
  %8 = load double, ptr %n, align 8
  %9 = fcmp ole double %7, %8
  br i1 %9, label %true1, label %false2

true1:                                            ; preds = %"2"
  ret i1 true

false2:                                           ; preds = %"2"
  br label %"3"

then3:                                            ; No predecessors!
  br label %"3"

"3":                                              ; preds = %then3, %false2
  %10 = load double, ptr %n, align 8
  %11 = frem double %0, %10
  %12 = fcmp one double %11, 0.000000e+00
  br i1 %12, label %true4, label %false5

true4:                                            ; preds = %"3"
  %13 = load double, ptr %n, align 8
  %14 = fadd double %13, 1.000000e+00
  store double %14, ptr %n, align 8
  br label %"2"

false5:                                           ; preds = %"3"
  ret i1 false

then6:                                            ; No predecessors!
}

define i32 @main(i32 %0, ptr %1) {
entree:
  %i = alloca double, align 8
  %2 = call double @read_double(ptr @var_name)
  store double %2, ptr %i, align 8
  %3 = load double, ptr %i, align 8
  %4 = call i1 @"est un nombre premier"(double %3)
  %5 = call i8 (ptr, ...) @printf(ptr @fmt_b, i1 %4)
  ret i32 0
}

attributes #0 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
