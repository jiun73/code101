; ModuleID = 'programme'
source_filename = "programme"

@fmt_d = internal unnamed_addr constant [4 x i8] c"%d\0A\00"
@fmt_s = internal unnamed_addr constant [4 x i8] c"%s\0A\00"
@message = private unnamed_addr constant [15 x i8] c"bonjour monde.\00", align 1
@message.1 = private unnamed_addr constant [9 x i8] c"message.\00", align 1
@message.2 = private unnamed_addr constant [28 x i8] c"le nombre i est \C3\A9gal \C3\A0 %d\00", align 1

declare i8 @printf(ptr, ...)

define i32 @main(i32 %0, ptr %1) {
entry:
  %2 = call i8 (ptr, ...) @printf(ptr @fmt_s, ptr @message)
  %3 = call i8 (ptr, ...) @printf(ptr @fmt_s, ptr @message.1)
  %i = alloca i32, align 4
  store i32 10, ptr %i, align 4
  %4 = call i8 (ptr, ...) @printf(ptr @fmt_s, ptr @message.2)
  %n = alloca i32, align 4
  store i32 12, ptr %n, align 4
  %5 = load ptr, ptr %i, align 8
  %6 = call i8 (ptr, ...) @printf(ptr @fmt_d, ptr %5)
  %7 = load ptr, ptr %n, align 8
  %8 = call i8 (ptr, ...) @printf(ptr @fmt_d, ptr %7)
  ret i32 0
}
