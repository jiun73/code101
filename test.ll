; ModuleID = 'test'
source_filename = "test"

@str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

declare i8 @printf(ptr %0, ...)

define i32 @main(i32 %0, ptr %1) {
entry:
  %test = call i8 (ptr, ...) @printf(ptr @str, i32 %0)
  %sum = add i32 %0, ptr %1
  %test1 = call i8 (ptr, ...) @printf(ptr @str, i32 %sum)
  ret i32 %sum
}