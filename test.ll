; ModuleID = 'programme'
source_filename = "programme"

@fmt_d = internal unnamed_addr constant [4 x i8] c"%d\0A\00"
@fmt_s = internal unnamed_addr constant [4 x i8] c"%s\0A\00"
@message = private unnamed_addr constant [16 x i8] c"\22bonjour monde\22\00", align 1
@message.1 = private unnamed_addr constant [17 x i8] c"\22bonjour monde2\22\00", align 1

declare i8 @printf(ptr %0, ...)

define i32 @main(i32 %0, ptr %1) {
entry:
  %2 = call i8 (ptr, ...) @printf(ptr @fmt_s, ptr @message)
  %3 = call i8 (ptr, ...) @printf(ptr @fmt_s, ptr @message.1)
  %i = alloca i32, align 4
  store i32 1, ptr %i, align 4
  %4 = call i8 (ptr, ...) @printf(ptr @fmt_d, ptr %i)
  %5 = call i8 (ptr, ...) @printf(ptr @fmt_d, ptr %i)
  ret ptr @main
}