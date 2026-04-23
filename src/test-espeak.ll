; ModuleID = 'test-espeak.c'
source_filename = "test-espeak.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@output = dso_local global i32 3, align 4
@path = dso_local global ptr null, align 8
@buflength = dso_local global i32 500, align 4
@options = dso_local global i32 0, align 4
@isInit = dso_local global i32 0, align 4
@position = dso_local global i32 0, align 4
@position_type = dso_local global i32 0, align 4
@end_position = dso_local global i32 0, align 4
@flags = dso_local global i32 0, align 4
@.str = private unnamed_addr constant [7 x i8] c"mb-ca2\00", align 1
@.str.1 = private unnamed_addr constant [10 x i8] c"/dev/null\00", align 1
@identifier = dso_local global ptr null, align 8
@user_data = dso_local global ptr null, align 8
@__const.main.text = private unnamed_addr constant [27 x i8] c"Bonjour monde. Hello world\00", align 16

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @say(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store ptr %0, ptr %2, align 8
  %5 = load i32, ptr @isInit, align 4
  %6 = icmp ne i32 %5, 0
  br i1 %6, label %14, label %7

7:                                                ; preds = %1
  %8 = load i32, ptr @output, align 4
  %9 = load i32, ptr @buflength, align 4
  %10 = load ptr, ptr @path, align 8
  %11 = load i32, ptr @options, align 4
  %12 = call i32 @espeak_Initialize(i32 noundef %8, i32 noundef %9, ptr noundef %10, i32 noundef %11)
  %13 = call i32 @espeak_SetVoiceByName(ptr noundef @.str)
  store i32 1, ptr @isInit, align 4
  br label %14

14:                                               ; preds = %7, %1
  %15 = call i32 @dup(i32 noundef 2) #4
  store i32 %15, ptr %3, align 4
  %16 = call i32 (ptr, i32, ...) @open(ptr noundef @.str.1, i32 noundef 1)
  store i32 %16, ptr %4, align 4
  %17 = load i32, ptr %4, align 4
  %18 = call i32 @dup2(i32 noundef %17, i32 noundef 2) #4
  %19 = load i32, ptr %4, align 4
  %20 = call i32 @close(i32 noundef %19)
  %21 = load ptr, ptr %2, align 8
  %22 = load i32, ptr @buflength, align 4
  %23 = sext i32 %22 to i64
  %24 = load i32, ptr @position, align 4
  %25 = load i32, ptr @position_type, align 4
  %26 = load i32, ptr @end_position, align 4
  %27 = load i32, ptr @flags, align 4
  %28 = load ptr, ptr @identifier, align 8
  %29 = load ptr, ptr @user_data, align 8
  %30 = call i32 @espeak_Synth(ptr noundef %21, i64 noundef %23, i32 noundef %24, i32 noundef %25, i32 noundef %26, i32 noundef %27, ptr noundef %28, ptr noundef %29)
  %31 = load i32, ptr %3, align 4
  %32 = call i32 @dup2(i32 noundef %31, i32 noundef 2) #4
  %33 = load i32, ptr %3, align 4
  %34 = call i32 @close(i32 noundef %33)
  ret void
}

declare i32 @espeak_Initialize(i32 noundef, i32 noundef, ptr noundef, i32 noundef) #1

declare i32 @espeak_SetVoiceByName(ptr noundef) #1

; Function Attrs: nounwind
declare i32 @dup(i32 noundef) #2

declare i32 @open(ptr noundef, i32 noundef, ...) #1

; Function Attrs: nounwind
declare i32 @dup2(i32 noundef, i32 noundef) #2

declare i32 @close(i32 noundef) #1

declare i32 @espeak_Synth(ptr noundef, i64 noundef, i32 noundef, i32 noundef, i32 noundef, i32 noundef, ptr noundef, ptr noundef) #1

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #3

attributes #0 = { noinline nounwind optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #4 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Ubuntu clang version 20.1.8 (0ubuntu4)"}
