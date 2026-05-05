; ModuleID = 'programme'
source_filename = "programme"

@fmt_d = internal unnamed_addr constant [6 x i8] c"%.2f\0A\00"
@fmt_s = internal unnamed_addr constant [4 x i8] c"%s\0A\00"
@message = private unnamed_addr constant [12 x i8] c"Je sait pas\00", align 1

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
  call void @say(ptr @message)
  ret i32 0
}

attributes #0 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
