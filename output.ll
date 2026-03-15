; ModuleID = 'programme'
source_filename = "programme"

@fmt_d = internal unnamed_addr constant [4 x i8] c"%d\0A\00"
@fmt_s = internal unnamed_addr constant [4 x i8] c"%s\0A\00"

declare i8 @printf(ptr, ...)

define i32 @main(i32 %0, ptr %1) {
entry:
  %i = alloca i32, align 4
  store i32 10, ptr %i, align 4
  %2 = load i32, ptr %i, align 4
  %3 = mul i32 5, %2
  %4 = mul i32 %3, %3
  %5 = mul i32 %4, %4
  %6 = call i8 (ptr, ...) @printf(ptr @fmt_d, i32 %5)
  %7 = call i8 (ptr, ...) @printf(ptr @fmt_d, i32 %3)
  ret i32 0
}
