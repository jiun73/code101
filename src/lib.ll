; ModuleID = 'BitcodeBuffer'
source_filename = "test TTS"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux6.17.0-gnu2.42.0"

; Function Attrs: nounwind uwtable
define dso_local void @say(ptr nonnull readonly align 1 %0) local_unnamed_addr #0 !dbg !580 {
Entry:
  %.sroa.025.i.i = alloca i8, align 1
  %.sroa.0.i.i = alloca i8, align 1
    #dbg_value(ptr %0, !585, !DIExpression(), !586)
    #dbg_value(ptr %0, !587, !DIExpression(), !591)
    #dbg_value(i8 0, !593, !DIExpression(), !594)
  call void @llvm.lifetime.start.p0(i64 1, ptr nonnull %.sroa.025.i.i), !dbg !595
  call void @llvm.lifetime.start.p0(i64 1, ptr nonnull %.sroa.0.i.i), !dbg !595
    #dbg_value(ptr %0, !600, !DIExpression(), !601)
    #dbg_value(i64 0, !602, !DIExpression(), !603)
    #dbg_value(i64 4096, !604, !DIExpression(), !605)
    #dbg_value(<64 x i8> zeroinitializer, !606, !DIExpression(), !611)
    #dbg_value(i1 true, !612, !DIExpression(), !616)
  %1 = ptrtoint ptr %0 to i64, !dbg !595
    #dbg_value(i64 %1, !618, !DIExpression(), !595)
  %2 = and i64 %1, 4095, !dbg !619
    #dbg_value(i64 %2, !620, !DIExpression(), !619)
  %3 = icmp samesign ult i64 %2, 4033, !dbg !621
  br i1 %3, label %Then1.i.i, label %Loop.preheader.i.i, !dbg !621, !prof !623

Loop.preheader.i.i:                               ; preds = %Entry
    #dbg_value(i64 0, !602, !DIExpression(), !603)
  %4 = and i64 %1, 63, !dbg !624
  %.not28.i.i = icmp eq i64 %4, 0, !dbg !624
  br i1 %.not28.i.i, label %Block2.i.i, label %Then3.preheader.i.i, !dbg !624

Then3.preheader.i.i:                              ; preds = %Loop.preheader.i.i
  %5 = trunc i64 %1 to i6, !dbg !630
  %6 = sub i6 0, %5, !dbg !630
  %7 = sub nuw nsw i64 64, %4, !dbg !630
  br label %Then3.i.i, !dbg !630

Block2.i.i:                                       ; preds = %Else4.i.i, %Else2.i.i, %Loop.preheader.i.i
  %.0.i.i = phi i64 [ %21, %Else2.i.i ], [ 0, %Loop.preheader.i.i ], [ %7, %Else4.i.i ], !dbg !603
    #dbg_value(i64 %.0.i.i, !602, !DIExpression(), !603)
  %8 = getelementptr inbounds i8, ptr %0, i64 %.0.i.i, !dbg !633
  %9 = ptrtoint ptr %8 to i64, !dbg !634
    #dbg_value(i64 %9, !635, !DIExpression(), !639)
    #dbg_value(i64 64, !641, !DIExpression(), !639)
    #dbg_value(i64 %9, !642, !DIExpression(), !646)
    #dbg_value(i64 64, !648, !DIExpression(), !646)
  %10 = and i64 %9, 63, !dbg !649
  %11 = icmp eq i64 %10, 0, !dbg !649
    #dbg_value(i1 %11, !612, !DIExpression(), !650)
  tail call void @llvm.assume(i1 %11), !dbg !653
  br label %Loop1.i.i, !dbg !655

Then1.i.i:                                        ; preds = %Entry
  %12 = load <64 x i8>, ptr %0, align 1, !dbg !656
    #dbg_value(<64 x i8> %12, !658, !DIExpression(), !656)
  %13 = icmp eq <64 x i8> %12, zeroinitializer, !dbg !659
    #dbg_value(<64 x i1> %13, !660, !DIExpression(), !659)
  %14 = bitcast <64 x i1> %13 to i64, !dbg !663
  %.not19.i.i = icmp eq i64 %14, 0, !dbg !663
  br i1 %.not19.i.i, label %Else2.i.i, label %simd.firstTrue__anon_2131.exit.i.i, !dbg !663

simd.firstTrue__anon_2131.exit.i.i:               ; preds = %Then1.i.i
    #dbg_value(<64 x i1> %13, !665, !DIExpression(), !675)
    #dbg_value(<64 x i6> splat (i6 -1), !678, !DIExpression(), !681)
  %15 = select <64 x i1> %13, <64 x i6> <i6 0, i6 1, i6 2, i6 3, i6 4, i6 5, i6 6, i6 7, i6 8, i6 9, i6 10, i6 11, i6 12, i6 13, i6 14, i6 15, i6 16, i6 17, i6 18, i6 19, i6 20, i6 21, i6 22, i6 23, i6 24, i6 25, i6 26, i6 27, i6 28, i6 29, i6 30, i6 31, i6 -32, i6 -31, i6 -30, i6 -29, i6 -28, i6 -27, i6 -26, i6 -25, i6 -24, i6 -23, i6 -22, i6 -21, i6 -20, i6 -19, i6 -18, i6 -17, i6 -16, i6 -15, i6 -14, i6 -13, i6 -12, i6 -11, i6 -10, i6 -9, i6 -8, i6 -7, i6 -6, i6 -5, i6 -4, i6 -3, i6 -2, i6 -1>, <64 x i6> splat (i6 -1), !dbg !682
    #dbg_value(<64 x i6> %15, !683, !DIExpression(), !682)
  %16 = tail call i6 @llvm.vector.reduce.umin.v64i6(<64 x i6> %15), !dbg !684
  store i6 %16, ptr %.sroa.0.i.i, align 1, !dbg !684, !alias.scope !685
  %.sroa.0.i.i.0..sroa.0.i.i.0..sroa.0.i.i.0..sroa.0.i.0..sroa.0.i.0..sroa.0.0..sroa.0.0..sroa.0.0..i.i = load i8, ptr %.sroa.0.i.i, align 1, !dbg !688
  %17 = and i8 %.sroa.0.i.i.0..sroa.0.i.i.0..sroa.0.i.i.0..sroa.0.i.0..sroa.0.i.0..sroa.0.0..sroa.0.0..sroa.0.0..i.i, 63, !dbg !689
  %18 = zext nneg i8 %17 to i64, !dbg !689
  br label %mem.len__anon_1750.exit, !dbg !690

Else2.i.i:                                        ; preds = %Then1.i.i
    #dbg_value(i64 %1, !691, !DIExpression(), !695)
    #dbg_value(i64 64, !697, !DIExpression(), !695)
  %19 = add nuw i64 %1, 63, !dbg !698
    #dbg_value(i64 %19, !699, !DIExpression(), !701)
    #dbg_value(i64 64, !703, !DIExpression(), !701)
  %20 = and i64 %19, -64, !dbg !704
  %21 = sub nuw i64 %20, %1, !dbg !705
    #dbg_value(i64 %21, !602, !DIExpression(), !603)
  br label %Block2.i.i, !dbg !706

Then3.i.i:                                        ; preds = %Else4.i.i, %Then3.preheader.i.i
  %.129.i.i = phi i64 [ %25, %Else4.i.i ], [ 0, %Then3.preheader.i.i ]
  %22 = getelementptr inbounds nuw i8, ptr %0, i64 %.129.i.i, !dbg !630
    #dbg_value(i64 %.129.i.i, !602, !DIExpression(), !603)
  %23 = load i8, ptr %22, align 1, !dbg !630
  %24 = icmp eq i8 %23, 0, !dbg !630
  br i1 %24, label %mem.len__anon_1750.exit, label %Else4.i.i, !dbg !630

Else4.i.i:                                        ; preds = %Then3.i.i
  %25 = add nuw nsw i64 %.129.i.i, 1, !dbg !707
    #dbg_value(i64 %25, !602, !DIExpression(), !603)
  %lftr.wideiv = trunc i64 %25 to i6, !dbg !624
  %exitcond = icmp eq i6 %lftr.wideiv, %6, !dbg !624
  br i1 %exitcond, label %Block2.i.i, label %Then3.i.i, !dbg !624

Loop1.i.i:                                        ; preds = %Loop1.i.i, %Block2.i.i
  %.2.i.i = phi i64 [ %.0.i.i, %Block2.i.i ], [ %30, %Loop1.i.i ], !dbg !709
    #dbg_value(i64 %.2.i.i, !602, !DIExpression(), !603)
  %26 = getelementptr inbounds i8, ptr %0, i64 %.2.i.i, !dbg !710
    #dbg_value(ptr %26, !713, !DIExpression(), !715)
  %27 = load <64 x i8>, ptr %26, align 64, !dbg !716
  %28 = icmp eq <64 x i8> %27, zeroinitializer, !dbg !716
    #dbg_value(<64 x i1> %28, !717, !DIExpression(), !716)
  %29 = bitcast <64 x i1> %28 to i64, !dbg !718
  %.not20.i.i = icmp eq i64 %29, 0, !dbg !718
  %30 = add nuw i64 %.2.i.i, 64, !dbg !720
    #dbg_value(i64 %30, !602, !DIExpression(), !603)
  br i1 %.not20.i.i, label %Loop1.i.i, label %simd.firstTrue__anon_2131.exit24.i.i, !dbg !718

simd.firstTrue__anon_2131.exit24.i.i:             ; preds = %Loop1.i.i
    #dbg_value(<64 x i1> %28, !665, !DIExpression(), !721)
    #dbg_value(<64 x i6> splat (i6 -1), !678, !DIExpression(), !724)
  %31 = select <64 x i1> %28, <64 x i6> <i6 0, i6 1, i6 2, i6 3, i6 4, i6 5, i6 6, i6 7, i6 8, i6 9, i6 10, i6 11, i6 12, i6 13, i6 14, i6 15, i6 16, i6 17, i6 18, i6 19, i6 20, i6 21, i6 22, i6 23, i6 24, i6 25, i6 26, i6 27, i6 28, i6 29, i6 30, i6 31, i6 -32, i6 -31, i6 -30, i6 -29, i6 -28, i6 -27, i6 -26, i6 -25, i6 -24, i6 -23, i6 -22, i6 -21, i6 -20, i6 -19, i6 -18, i6 -17, i6 -16, i6 -15, i6 -14, i6 -13, i6 -12, i6 -11, i6 -10, i6 -9, i6 -8, i6 -7, i6 -6, i6 -5, i6 -4, i6 -3, i6 -2, i6 -1>, <64 x i6> splat (i6 -1), !dbg !725
    #dbg_value(<64 x i6> %31, !683, !DIExpression(), !725)
  %32 = tail call i6 @llvm.vector.reduce.umin.v64i6(<64 x i6> %31), !dbg !726
  store i6 %32, ptr %.sroa.025.i.i, align 1, !dbg !726, !alias.scope !727
  %.sroa.025.i.i.0..sroa.025.i.i.0..sroa.025.i.i.0..sroa.025.i.0..sroa.025.i.0..sroa.025.0..sroa.025.0..sroa.025.0..i.i = load i8, ptr %.sroa.025.i.i, align 1, !dbg !730
  %33 = and i8 %.sroa.025.i.i.0..sroa.025.i.i.0..sroa.025.i.i.0..sroa.025.i.0..sroa.025.i.0..sroa.025.0..sroa.025.0..sroa.025.0..i.i, 63, !dbg !731
  %34 = zext nneg i8 %33 to i64, !dbg !731
  %35 = add nuw i64 %.2.i.i, %34, !dbg !731
  br label %mem.len__anon_1750.exit, !dbg !732

mem.len__anon_1750.exit:                          ; preds = %Then3.i.i, %simd.firstTrue__anon_2131.exit.i.i, %simd.firstTrue__anon_2131.exit24.i.i
  %common.ret.op.i.i = phi i64 [ %18, %simd.firstTrue__anon_2131.exit.i.i ], [ %35, %simd.firstTrue__anon_2131.exit24.i.i ], [ %.129.i.i, %Then3.i.i ]
  call void @llvm.lifetime.end.p0(i64 1, ptr nonnull %.sroa.025.i.i), !dbg !603
  call void @llvm.lifetime.end.p0(i64 1, ptr nonnull %.sroa.0.i.i), !dbg !603
  %36 = tail call i32 @espeak_Synth(ptr nonnull readonly align 1 %0, i64 %common.ret.op.i.i, i32 0, i32 0, i32 0, i32 1, ptr align 4 null, ptr align 1 null), !dbg !733
  ret void, !dbg !735
}

; Function Attrs: nounwind uwtable
declare i32 @espeak_Synth(ptr readonly align 1, i64, i32, i32, i32, i32, ptr align 4, ptr align 1) local_unnamed_addr #0

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i6 @llvm.vector.reduce.umin.v64i6(<64 x i6>) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write)
declare void @llvm.assume(i1 noundef) #2

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #3

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #3

attributes #0 = { nounwind uwtable "frame-pointer"="all" "target-cpu"="znver4" "target-features"="+64bit,+adx,+aes,+allow-light-256-bit,+avx,+avx2,+avx512bf16,+avx512bitalg,+avx512bw,+avx512cd,+avx512dq,+avx512f,+avx512ifma,+avx512vbmi,+avx512vbmi2,+avx512vl,+avx512vnni,+avx512vpopcntdq,+bmi,+bmi2,+branchfusion,+clflushopt,+clwb,+clzero,+cmov,+crc32,+cx16,+cx8,+evex512,+f16c,+fast-15bytenop,+fast-bextr,+fast-dpwssd,+fast-imm16,+fast-lzcnt,+fast-movbe,+fast-scalar-fsqrt,+fast-scalar-shift-masks,+fast-variable-perlane-shuffle,+fast-vector-fsqrt,+fma,+fsgsbase,+fsrm,+fxsr,+gfni,+idivq-to-divl,+invpcid,+lzcnt,+macrofusion,+mmx,+movbe,+mwaitx,+nopl,+pclmul,+pku,+popcnt,+prfchw,+rdpid,+rdpru,+rdrnd,+rdseed,+sahf,+sbb-dep-breaking,+sha,+shstk,+slow-shld,+sse,+sse2,+sse3,+sse4.1,+sse4.2,+sse4a,+ssse3,+vaes,+vpclmulqdq,+vzeroupper,+wbnoinvd,+x87,+xsave,+xsavec,+xsaveopt,+xsaves,-16bit-mode,-32bit-mode,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-amx-transpose,-avx10.1-256,-avx10.1-512,-avx10.2-256,-avx10.2-512,-avx512fp16,-avx512vp2intersect,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-branch-hint,-ccmp,-cf,-cldemote,-cmpccxadd,-egpr,-enqcmd,-ermsb,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-7bytenop,-fast-gather,-fast-hops,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma4,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-movdir64b,-movdiri,-movrs,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pconfig,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-ptwrite,-push2pop2,-raoint,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-serialize,-seses,-sgx,-sha512,-slow-3ops-lea,-slow-incdec,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse-unaligned-mem,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-waitpkg,-widekl,-xop,-zu" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write) }
attributes #3 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!578, !579}

!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, producer: "zig 0.15.2", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, enums: !2, globals: !486, splitDebugInlining: false)
!1 = !DIFile(filename: "test TTS", directory: "/home/alex/repos/tts")
!2 = !{!3, !20, !26, !31, !104, !140, !209, !242, !256, !273, !288, !296, !466, !472, !479}
!3 = !DICompositeType(tag: DW_TAG_enumeration_type, name: "builtin.CompilerBackend", scope: !4, file: !4, line: 1027, baseType: !5, size: 64, align: 64, elements: !6)
!4 = !DIFile(filename: "builtin.zig", directory: "/home/alex/.config/Code/User/globalStorage/ziglang.vscode-zig/zig/x86_64-linux-0.15.2/lib/std")
!5 = !DIBasicType(name: "u64", size: 64, encoding: DW_ATE_unsigned)
!6 = !{!7, !8, !9, !10, !11, !12, !13, !14, !15, !16, !17, !18, !19}
!7 = !DIEnumerator(name: "other", value: 0, isUnsigned: true)
!8 = !DIEnumerator(name: "stage1", value: 1, isUnsigned: true)
!9 = !DIEnumerator(name: "stage2_llvm", value: 2, isUnsigned: true)
!10 = !DIEnumerator(name: "stage2_c", value: 3, isUnsigned: true)
!11 = !DIEnumerator(name: "stage2_wasm", value: 4, isUnsigned: true)
!12 = !DIEnumerator(name: "stage2_arm", value: 5, isUnsigned: true)
!13 = !DIEnumerator(name: "stage2_x86_64", value: 6, isUnsigned: true)
!14 = !DIEnumerator(name: "stage2_aarch64", value: 7, isUnsigned: true)
!15 = !DIEnumerator(name: "stage2_x86", value: 8, isUnsigned: true)
!16 = !DIEnumerator(name: "stage2_riscv64", value: 9, isUnsigned: true)
!17 = !DIEnumerator(name: "stage2_sparc64", value: 10, isUnsigned: true)
!18 = !DIEnumerator(name: "stage2_spirv", value: 11, isUnsigned: true)
!19 = !DIEnumerator(name: "stage2_powerpc", value: 12, isUnsigned: true)
!20 = !DICompositeType(tag: DW_TAG_enumeration_type, name: "builtin.OutputMode", scope: !4, file: !4, line: 782, baseType: !21, size: 8, align: 8, elements: !22)
!21 = !DIBasicType(name: "u2", size: 8, encoding: DW_ATE_unsigned)
!22 = !{!23, !24, !25}
!23 = !DIEnumerator(name: "Exe", value: 0, isUnsigned: true)
!24 = !DIEnumerator(name: "Lib", value: 1, isUnsigned: true)
!25 = !DIEnumerator(name: "Obj", value: 2, isUnsigned: true)
!26 = !DICompositeType(tag: DW_TAG_enumeration_type, name: "builtin.LinkMode", scope: !4, file: !4, line: 790, baseType: !27, size: 8, align: 8, elements: !28)
!27 = !DIBasicType(name: "u1", size: 8, encoding: DW_ATE_unsigned)
!28 = !{!29, !30}
!29 = !DIEnumerator(name: "static", value: 0, isUnsigned: true)
!30 = !DIEnumerator(name: "dynamic", value: 1, isUnsigned: true)
!31 = !DICompositeType(tag: DW_TAG_enumeration_type, name: "Target.Cpu.Arch", scope: !33, file: !32, line: 1777, baseType: !57, size: 8, align: 8, elements: !58)
!32 = !DIFile(filename: "Target.zig", directory: "/home/alex/.config/Code/User/globalStorage/ziglang.vscode-zig/zig/x86_64-linux-0.15.2/lib/std")
!33 = !DICompositeType(tag: DW_TAG_structure_type, name: "Target.Cpu", scope: !0, size: 448, align: 64, elements: !34)
!34 = !{!35, !55, !56}
!35 = !DIDerivedType(tag: DW_TAG_member, name: "model", scope: !33, baseType: !36, size: 64, align: 64)
!36 = !DIDerivedType(tag: DW_TAG_pointer_type, name: "*Target.Cpu.Model", baseType: !37, size: 64, align: 64)
!37 = !DICompositeType(tag: DW_TAG_structure_type, name: "Target.Cpu.Model", scope: !0, size: 576, align: 64, elements: !38)
!38 = !{!39, !47, !48}
!39 = !DIDerivedType(tag: DW_TAG_member, name: "name", scope: !37, baseType: !40, size: 128, align: 64)
!40 = !DICompositeType(tag: DW_TAG_structure_type, name: "[]u8", scope: !0, size: 128, align: 64, elements: !41)
!41 = !{!42, !45}
!42 = !DIDerivedType(tag: DW_TAG_member, name: "ptr", scope: !40, baseType: !43, size: 64, align: 64)
!43 = !DIDerivedType(tag: DW_TAG_pointer_type, name: "*u8", baseType: !44, size: 64, align: 8)
!44 = !DIBasicType(name: "u8", size: 8, encoding: DW_ATE_unsigned)
!45 = !DIDerivedType(tag: DW_TAG_member, name: "len", scope: !40, baseType: !46, size: 64, align: 64, offset: 64)
!46 = !DIBasicType(name: "usize", size: 64, encoding: DW_ATE_unsigned)
!47 = !DIDerivedType(tag: DW_TAG_member, name: "llvm_name", scope: !37, baseType: !40, size: 128, align: 64, offset: 128)
!48 = !DIDerivedType(tag: DW_TAG_member, name: "features", scope: !37, baseType: !49, size: 320, align: 64, offset: 256)
!49 = !DICompositeType(tag: DW_TAG_structure_type, name: "Target.Cpu.Feature.Set", scope: !0, size: 320, align: 64, elements: !50)
!50 = !{!51}
!51 = !DIDerivedType(tag: DW_TAG_member, name: "ints", scope: !49, baseType: !52, size: 320, align: 64)
!52 = !DICompositeType(tag: DW_TAG_array_type, baseType: !46, size: 320, align: 64, elements: !53)
!53 = !{!54}
!54 = !DISubrange(count: 5, lowerBound: 0)
!55 = !DIDerivedType(tag: DW_TAG_member, name: "features", scope: !33, baseType: !49, size: 320, align: 64, offset: 64)
!56 = !DIDerivedType(tag: DW_TAG_member, name: "arch", scope: !33, baseType: !31, size: 8, align: 8, offset: 384)
!57 = !DIBasicType(name: "u6", size: 8, encoding: DW_ATE_unsigned)
!58 = !{!59, !60, !61, !62, !63, !64, !65, !66, !67, !68, !69, !70, !71, !72, !73, !74, !75, !76, !77, !78, !79, !80, !81, !82, !83, !84, !85, !86, !87, !88, !89, !90, !91, !92, !93, !94, !95, !96, !97, !98, !99, !100, !101, !102, !103}
!59 = !DIEnumerator(name: "amdgcn", value: 0, isUnsigned: true)
!60 = !DIEnumerator(name: "arc", value: 1, isUnsigned: true)
!61 = !DIEnumerator(name: "arm", value: 2, isUnsigned: true)
!62 = !DIEnumerator(name: "armeb", value: 3, isUnsigned: true)
!63 = !DIEnumerator(name: "thumb", value: 4, isUnsigned: true)
!64 = !DIEnumerator(name: "thumbeb", value: 5, isUnsigned: true)
!65 = !DIEnumerator(name: "aarch64", value: 6, isUnsigned: true)
!66 = !DIEnumerator(name: "aarch64_be", value: 7, isUnsigned: true)
!67 = !DIEnumerator(name: "avr", value: 8, isUnsigned: true)
!68 = !DIEnumerator(name: "bpfel", value: 9, isUnsigned: true)
!69 = !DIEnumerator(name: "bpfeb", value: 10, isUnsigned: true)
!70 = !DIEnumerator(name: "csky", value: 11, isUnsigned: true)
!71 = !DIEnumerator(name: "hexagon", value: 12, isUnsigned: true)
!72 = !DIEnumerator(name: "kalimba", value: 13, isUnsigned: true)
!73 = !DIEnumerator(name: "lanai", value: 14, isUnsigned: true)
!74 = !DIEnumerator(name: "loongarch32", value: 15, isUnsigned: true)
!75 = !DIEnumerator(name: "loongarch64", value: 16, isUnsigned: true)
!76 = !DIEnumerator(name: "m68k", value: 17, isUnsigned: true)
!77 = !DIEnumerator(name: "mips", value: 18, isUnsigned: true)
!78 = !DIEnumerator(name: "mipsel", value: 19, isUnsigned: true)
!79 = !DIEnumerator(name: "mips64", value: 20, isUnsigned: true)
!80 = !DIEnumerator(name: "mips64el", value: 21, isUnsigned: true)
!81 = !DIEnumerator(name: "msp430", value: 22, isUnsigned: true)
!82 = !DIEnumerator(name: "or1k", value: 23, isUnsigned: true)
!83 = !DIEnumerator(name: "nvptx", value: 24, isUnsigned: true)
!84 = !DIEnumerator(name: "nvptx64", value: 25, isUnsigned: true)
!85 = !DIEnumerator(name: "powerpc", value: 26, isUnsigned: true)
!86 = !DIEnumerator(name: "powerpcle", value: 27, isUnsigned: true)
!87 = !DIEnumerator(name: "powerpc64", value: 28, isUnsigned: true)
!88 = !DIEnumerator(name: "powerpc64le", value: 29, isUnsigned: true)
!89 = !DIEnumerator(name: "propeller", value: 30, isUnsigned: true)
!90 = !DIEnumerator(name: "riscv32", value: 31, isUnsigned: true)
!91 = !DIEnumerator(name: "riscv64", value: 32, isUnsigned: true)
!92 = !DIEnumerator(name: "s390x", value: 33, isUnsigned: true)
!93 = !DIEnumerator(name: "sparc", value: 34, isUnsigned: true)
!94 = !DIEnumerator(name: "sparc64", value: 35, isUnsigned: true)
!95 = !DIEnumerator(name: "spirv32", value: 36, isUnsigned: true)
!96 = !DIEnumerator(name: "spirv64", value: 37, isUnsigned: true)
!97 = !DIEnumerator(name: "ve", value: 38, isUnsigned: true)
!98 = !DIEnumerator(name: "wasm32", value: 39, isUnsigned: true)
!99 = !DIEnumerator(name: "wasm64", value: 40, isUnsigned: true)
!100 = !DIEnumerator(name: "x86", value: 41, isUnsigned: true)
!101 = !DIEnumerator(name: "x86_64", value: 42, isUnsigned: true)
!102 = !DIEnumerator(name: "xcore", value: 43, isUnsigned: true)
!103 = !DIEnumerator(name: "xtensa", value: 44, isUnsigned: true)
!104 = !DICompositeType(tag: DW_TAG_enumeration_type, name: "Target.Os.WindowsVersion", scope: !105, file: !32, line: 311, baseType: !133, size: 32, align: 32, elements: !182)
!105 = !DICompositeType(tag: DW_TAG_structure_type, name: "Target.Os", scope: !0, size: 1472, align: 64, elements: !106)
!106 = !{!107, !139}
!107 = !DIDerivedType(tag: DW_TAG_member, name: "version_range", scope: !105, baseType: !108, size: 1408, align: 64)
!108 = !DICompositeType(tag: DW_TAG_union_type, name: "Target.Os.VersionRange", scope: !0, size: 1408, align: 64, elements: !109)
!109 = !{!110, !122, !127, !134}
!110 = !DIDerivedType(tag: DW_TAG_member, name: "semver", scope: !108, baseType: !111, size: 896, align: 64)
!111 = !DICompositeType(tag: DW_TAG_structure_type, name: "SemanticVersion.Range", scope: !0, size: 896, align: 64, elements: !112)
!112 = !{!113, !121}
!113 = !DIDerivedType(tag: DW_TAG_member, name: "min", scope: !111, baseType: !114, size: 448, align: 64)
!114 = !DICompositeType(tag: DW_TAG_structure_type, name: "SemanticVersion", scope: !0, size: 448, align: 64, elements: !115)
!115 = !{!116, !117, !118, !119, !120}
!116 = !DIDerivedType(tag: DW_TAG_member, name: "major", scope: !114, baseType: !46, size: 64, align: 64)
!117 = !DIDerivedType(tag: DW_TAG_member, name: "minor", scope: !114, baseType: !46, size: 64, align: 64, offset: 64)
!118 = !DIDerivedType(tag: DW_TAG_member, name: "patch", scope: !114, baseType: !46, size: 64, align: 64, offset: 128)
!119 = !DIDerivedType(tag: DW_TAG_member, name: "pre", scope: !114, baseType: !40, size: 128, align: 64, offset: 192)
!120 = !DIDerivedType(tag: DW_TAG_member, name: "build", scope: !114, baseType: !40, size: 128, align: 64, offset: 320)
!121 = !DIDerivedType(tag: DW_TAG_member, name: "max", scope: !111, baseType: !114, size: 448, align: 64, offset: 448)
!122 = !DIDerivedType(tag: DW_TAG_member, name: "hurd", scope: !108, baseType: !123, size: 1344, align: 64)
!123 = !DICompositeType(tag: DW_TAG_structure_type, name: "Target.Os.HurdVersionRange", scope: !0, size: 1344, align: 64, elements: !124)
!124 = !{!125, !126}
!125 = !DIDerivedType(tag: DW_TAG_member, name: "range", scope: !123, baseType: !111, size: 896, align: 64)
!126 = !DIDerivedType(tag: DW_TAG_member, name: "glibc", scope: !123, baseType: !114, size: 448, align: 64, offset: 896)
!127 = !DIDerivedType(tag: DW_TAG_member, name: "linux", scope: !108, baseType: !128, size: 1408, align: 64)
!128 = !DICompositeType(tag: DW_TAG_structure_type, name: "Target.Os.LinuxVersionRange", scope: !0, size: 1408, align: 64, elements: !129)
!129 = !{!130, !131, !132}
!130 = !DIDerivedType(tag: DW_TAG_member, name: "range", scope: !128, baseType: !111, size: 896, align: 64)
!131 = !DIDerivedType(tag: DW_TAG_member, name: "glibc", scope: !128, baseType: !114, size: 448, align: 64, offset: 896)
!132 = !DIDerivedType(tag: DW_TAG_member, name: "android", scope: !128, baseType: !133, size: 32, align: 32, offset: 1344)
!133 = !DIBasicType(name: "u32", size: 32, encoding: DW_ATE_unsigned)
!134 = !DIDerivedType(tag: DW_TAG_member, name: "windows", scope: !108, baseType: !135, size: 64, align: 32)
!135 = !DICompositeType(tag: DW_TAG_structure_type, name: "Target.Os.WindowsVersion.Range", scope: !0, size: 64, align: 32, elements: !136)
!136 = !{!137, !138}
!137 = !DIDerivedType(tag: DW_TAG_member, name: "min", scope: !135, baseType: !104, size: 32, align: 32)
!138 = !DIDerivedType(tag: DW_TAG_member, name: "max", scope: !135, baseType: !104, size: 32, align: 32, offset: 32)
!139 = !DIDerivedType(tag: DW_TAG_member, name: "tag", scope: !105, baseType: !140, size: 8, align: 8, offset: 1408)
!140 = !DICompositeType(tag: DW_TAG_enumeration_type, name: "Target.Os.Tag", scope: !105, file: !32, line: 213, baseType: !57, size: 8, align: 8, elements: !141)
!141 = !{!142, !143, !144, !145, !146, !147, !148, !149, !150, !151, !152, !153, !154, !155, !156, !157, !158, !159, !160, !161, !162, !163, !164, !165, !166, !167, !168, !169, !170, !171, !172, !173, !174, !175, !176, !177, !178, !179, !180, !181}
!142 = !DIEnumerator(name: "freestanding", value: 0, isUnsigned: true)
!143 = !DIEnumerator(name: "other", value: 1, isUnsigned: true)
!144 = !DIEnumerator(name: "contiki", value: 2, isUnsigned: true)
!145 = !DIEnumerator(name: "fuchsia", value: 3, isUnsigned: true)
!146 = !DIEnumerator(name: "hermit", value: 4, isUnsigned: true)
!147 = !DIEnumerator(name: "aix", value: 5, isUnsigned: true)
!148 = !DIEnumerator(name: "haiku", value: 6, isUnsigned: true)
!149 = !DIEnumerator(name: "hurd", value: 7, isUnsigned: true)
!150 = !DIEnumerator(name: "linux", value: 8, isUnsigned: true)
!151 = !DIEnumerator(name: "plan9", value: 9, isUnsigned: true)
!152 = !DIEnumerator(name: "rtems", value: 10, isUnsigned: true)
!153 = !DIEnumerator(name: "serenity", value: 11, isUnsigned: true)
!154 = !DIEnumerator(name: "zos", value: 12, isUnsigned: true)
!155 = !DIEnumerator(name: "dragonfly", value: 13, isUnsigned: true)
!156 = !DIEnumerator(name: "freebsd", value: 14, isUnsigned: true)
!157 = !DIEnumerator(name: "netbsd", value: 15, isUnsigned: true)
!158 = !DIEnumerator(name: "openbsd", value: 16, isUnsigned: true)
!159 = !DIEnumerator(name: "driverkit", value: 17, isUnsigned: true)
!160 = !DIEnumerator(name: "ios", value: 18, isUnsigned: true)
!161 = !DIEnumerator(name: "macos", value: 19, isUnsigned: true)
!162 = !DIEnumerator(name: "tvos", value: 20, isUnsigned: true)
!163 = !DIEnumerator(name: "visionos", value: 21, isUnsigned: true)
!164 = !DIEnumerator(name: "watchos", value: 22, isUnsigned: true)
!165 = !DIEnumerator(name: "illumos", value: 23, isUnsigned: true)
!166 = !DIEnumerator(name: "solaris", value: 24, isUnsigned: true)
!167 = !DIEnumerator(name: "windows", value: 25, isUnsigned: true)
!168 = !DIEnumerator(name: "uefi", value: 26, isUnsigned: true)
!169 = !DIEnumerator(name: "ps3", value: 27, isUnsigned: true)
!170 = !DIEnumerator(name: "ps4", value: 28, isUnsigned: true)
!171 = !DIEnumerator(name: "ps5", value: 29, isUnsigned: true)
!172 = !DIEnumerator(name: "emscripten", value: 30, isUnsigned: true)
!173 = !DIEnumerator(name: "wasi", value: 31, isUnsigned: true)
!174 = !DIEnumerator(name: "amdhsa", value: 32, isUnsigned: true)
!175 = !DIEnumerator(name: "amdpal", value: 33, isUnsigned: true)
!176 = !DIEnumerator(name: "cuda", value: 34, isUnsigned: true)
!177 = !DIEnumerator(name: "mesa3d", value: 35, isUnsigned: true)
!178 = !DIEnumerator(name: "nvcl", value: 36, isUnsigned: true)
!179 = !DIEnumerator(name: "opencl", value: 37, isUnsigned: true)
!180 = !DIEnumerator(name: "opengl", value: 38, isUnsigned: true)
!181 = !DIEnumerator(name: "vulkan", value: 39, isUnsigned: true)
!182 = !{!183, !184, !185, !186, !187, !188, !189, !190, !191, !192, !193, !194, !195, !196, !197, !198, !199, !200, !201, !202, !203, !204, !205, !206, !207, !208}
!183 = !DIEnumerator(name: "nt4", value: 67108864, isUnsigned: true)
!184 = !DIEnumerator(name: "win2k", value: 83886080, isUnsigned: true)
!185 = !DIEnumerator(name: "xp", value: 83951616, isUnsigned: true)
!186 = !DIEnumerator(name: "ws2003", value: 84017152, isUnsigned: true)
!187 = !DIEnumerator(name: "vista", value: 100663296, isUnsigned: true)
!188 = !DIEnumerator(name: "win7", value: 100728832, isUnsigned: true)
!189 = !DIEnumerator(name: "win8", value: 100794368, isUnsigned: true)
!190 = !DIEnumerator(name: "win8_1", value: 100859904, isUnsigned: true)
!191 = !DIEnumerator(name: "win10", value: 167772160, isUnsigned: true)
!192 = !DIEnumerator(name: "win10_th2", value: 167772161, isUnsigned: true)
!193 = !DIEnumerator(name: "win10_rs1", value: 167772162, isUnsigned: true)
!194 = !DIEnumerator(name: "win10_rs2", value: 167772163, isUnsigned: true)
!195 = !DIEnumerator(name: "win10_rs3", value: 167772164, isUnsigned: true)
!196 = !DIEnumerator(name: "win10_rs4", value: 167772165, isUnsigned: true)
!197 = !DIEnumerator(name: "win10_rs5", value: 167772166, isUnsigned: true)
!198 = !DIEnumerator(name: "win10_19h1", value: 167772167, isUnsigned: true)
!199 = !DIEnumerator(name: "win10_vb", value: 167772168, isUnsigned: true)
!200 = !DIEnumerator(name: "win10_mn", value: 167772169, isUnsigned: true)
!201 = !DIEnumerator(name: "win10_fe", value: 167772170, isUnsigned: true)
!202 = !DIEnumerator(name: "win10_co", value: 167772171, isUnsigned: true)
!203 = !DIEnumerator(name: "win10_ni", value: 167772172, isUnsigned: true)
!204 = !DIEnumerator(name: "win10_cu", value: 167772173, isUnsigned: true)
!205 = !DIEnumerator(name: "win11_zn", value: 167772174, isUnsigned: true)
!206 = !DIEnumerator(name: "win11_ga", value: 167772175, isUnsigned: true)
!207 = !DIEnumerator(name: "win11_ge", value: 167772176, isUnsigned: true)
!208 = !DIEnumerator(name: "win11_dt", value: 167772177, isUnsigned: true)
!209 = !DICompositeType(tag: DW_TAG_enumeration_type, name: "Target.Abi", scope: !32, file: !32, line: 952, baseType: !210, size: 8, align: 8, elements: !211)
!210 = !DIBasicType(name: "u5", size: 8, encoding: DW_ATE_unsigned)
!211 = !{!212, !213, !214, !215, !216, !217, !218, !219, !220, !221, !222, !223, !224, !225, !226, !227, !228, !229, !230, !231, !232, !233, !234, !235, !236, !237, !238, !239, !240, !241}
!212 = !DIEnumerator(name: "none", value: 0, isUnsigned: true)
!213 = !DIEnumerator(name: "gnu", value: 1, isUnsigned: true)
!214 = !DIEnumerator(name: "gnuabin32", value: 2, isUnsigned: true)
!215 = !DIEnumerator(name: "gnuabi64", value: 3, isUnsigned: true)
!216 = !DIEnumerator(name: "gnueabi", value: 4, isUnsigned: true)
!217 = !DIEnumerator(name: "gnueabihf", value: 5, isUnsigned: true)
!218 = !DIEnumerator(name: "gnuf32", value: 6, isUnsigned: true)
!219 = !DIEnumerator(name: "gnusf", value: 7, isUnsigned: true)
!220 = !DIEnumerator(name: "gnux32", value: 8, isUnsigned: true)
!221 = !DIEnumerator(name: "code16", value: 9, isUnsigned: true)
!222 = !DIEnumerator(name: "eabi", value: 10, isUnsigned: true)
!223 = !DIEnumerator(name: "eabihf", value: 11, isUnsigned: true)
!224 = !DIEnumerator(name: "ilp32", value: 12, isUnsigned: true)
!225 = !DIEnumerator(name: "android", value: 13, isUnsigned: true)
!226 = !DIEnumerator(name: "androideabi", value: 14, isUnsigned: true)
!227 = !DIEnumerator(name: "musl", value: 15, isUnsigned: true)
!228 = !DIEnumerator(name: "muslabin32", value: 16, isUnsigned: true)
!229 = !DIEnumerator(name: "muslabi64", value: 17, isUnsigned: true)
!230 = !DIEnumerator(name: "musleabi", value: 18, isUnsigned: true)
!231 = !DIEnumerator(name: "musleabihf", value: 19, isUnsigned: true)
!232 = !DIEnumerator(name: "muslf32", value: 20, isUnsigned: true)
!233 = !DIEnumerator(name: "muslsf", value: 21, isUnsigned: true)
!234 = !DIEnumerator(name: "muslx32", value: 22, isUnsigned: true)
!235 = !DIEnumerator(name: "msvc", value: 23, isUnsigned: true)
!236 = !DIEnumerator(name: "itanium", value: 24, isUnsigned: true)
!237 = !DIEnumerator(name: "cygnus", value: 25, isUnsigned: true)
!238 = !DIEnumerator(name: "simulator", value: 26, isUnsigned: true)
!239 = !DIEnumerator(name: "macabi", value: 27, isUnsigned: true)
!240 = !DIEnumerator(name: "ohos", value: 28, isUnsigned: true)
!241 = !DIEnumerator(name: "ohoseabi", value: 29, isUnsigned: true)
!242 = !DICompositeType(tag: DW_TAG_enumeration_type, name: "Target.ObjectFormat", scope: !32, file: !32, line: 1007, baseType: !243, size: 8, align: 8, elements: !244)
!243 = !DIBasicType(name: "u4", size: 8, encoding: DW_ATE_unsigned)
!244 = !{!245, !246, !247, !248, !249, !250, !251, !252, !253, !254, !255}
!245 = !DIEnumerator(name: "c", value: 0, isUnsigned: true)
!246 = !DIEnumerator(name: "coff", value: 1, isUnsigned: true)
!247 = !DIEnumerator(name: "elf", value: 2, isUnsigned: true)
!248 = !DIEnumerator(name: "goff", value: 3, isUnsigned: true)
!249 = !DIEnumerator(name: "hex", value: 4, isUnsigned: true)
!250 = !DIEnumerator(name: "macho", value: 5, isUnsigned: true)
!251 = !DIEnumerator(name: "plan9", value: 6, isUnsigned: true)
!252 = !DIEnumerator(name: "raw", value: 7, isUnsigned: true)
!253 = !DIEnumerator(name: "spirv", value: 8, isUnsigned: true)
!254 = !DIEnumerator(name: "wasm", value: 9, isUnsigned: true)
!255 = !DIEnumerator(name: "xcoff", value: 10, isUnsigned: true)
!256 = !DICompositeType(tag: DW_TAG_enumeration_type, name: "builtin.CallingConvention.ArmInterruptOptions.InterruptType", scope: !257, file: !4, line: 382, baseType: !265, size: 8, align: 8, elements: !266)
!257 = !DICompositeType(tag: DW_TAG_structure_type, name: "builtin.CallingConvention.ArmInterruptOptions", scope: !0, size: 192, align: 64, elements: !258)
!258 = !{!259, !264}
!259 = !DIDerivedType(tag: DW_TAG_member, name: "incoming_stack_alignment", scope: !257, baseType: !260, size: 128, align: 64)
!260 = !DICompositeType(tag: DW_TAG_structure_type, name: "?u64", scope: !0, size: 128, align: 64, elements: !261)
!261 = !{!262, !263}
!262 = !DIDerivedType(tag: DW_TAG_member, name: "data", scope: !260, baseType: !5, size: 64, align: 64)
!263 = !DIDerivedType(tag: DW_TAG_member, name: "some", scope: !260, baseType: !44, size: 8, align: 8, offset: 64)
!264 = !DIDerivedType(tag: DW_TAG_member, name: "type", scope: !257, baseType: !256, size: 8, align: 8, offset: 128)
!265 = !DIBasicType(name: "u3", size: 8, encoding: DW_ATE_unsigned)
!266 = !{!267, !268, !269, !270, !271, !272}
!267 = !DIEnumerator(name: "generic", value: 0, isUnsigned: true)
!268 = !DIEnumerator(name: "irq", value: 1, isUnsigned: true)
!269 = !DIEnumerator(name: "fiq", value: 2, isUnsigned: true)
!270 = !DIEnumerator(name: "swi", value: 3, isUnsigned: true)
!271 = !DIEnumerator(name: "abort", value: 4, isUnsigned: true)
!272 = !DIEnumerator(name: "undef", value: 5, isUnsigned: true)
!273 = !DICompositeType(tag: DW_TAG_enumeration_type, name: "builtin.CallingConvention.MipsInterruptOptions.InterruptMode", scope: !274, file: !4, line: 400, baseType: !243, size: 8, align: 8, elements: !278)
!274 = !DICompositeType(tag: DW_TAG_structure_type, name: "builtin.CallingConvention.MipsInterruptOptions", scope: !0, size: 192, align: 64, elements: !275)
!275 = !{!276, !277}
!276 = !DIDerivedType(tag: DW_TAG_member, name: "incoming_stack_alignment", scope: !274, baseType: !260, size: 128, align: 64)
!277 = !DIDerivedType(tag: DW_TAG_member, name: "mode", scope: !274, baseType: !273, size: 8, align: 8, offset: 128)
!278 = !{!279, !280, !281, !282, !283, !284, !285, !286, !287}
!279 = !DIEnumerator(name: "eic", value: 0, isUnsigned: true)
!280 = !DIEnumerator(name: "sw0", value: 1, isUnsigned: true)
!281 = !DIEnumerator(name: "sw1", value: 2, isUnsigned: true)
!282 = !DIEnumerator(name: "hw0", value: 3, isUnsigned: true)
!283 = !DIEnumerator(name: "hw1", value: 4, isUnsigned: true)
!284 = !DIEnumerator(name: "hw2", value: 5, isUnsigned: true)
!285 = !DIEnumerator(name: "hw3", value: 6, isUnsigned: true)
!286 = !DIEnumerator(name: "hw4", value: 7, isUnsigned: true)
!287 = !DIEnumerator(name: "hw5", value: 8, isUnsigned: true)
!288 = !DICompositeType(tag: DW_TAG_enumeration_type, name: "builtin.CallingConvention.RiscvInterruptOptions.PrivilegeMode", scope: !289, file: !4, line: 421, baseType: !21, size: 8, align: 8, elements: !293)
!289 = !DICompositeType(tag: DW_TAG_structure_type, name: "builtin.CallingConvention.RiscvInterruptOptions", scope: !0, size: 192, align: 64, elements: !290)
!290 = !{!291, !292}
!291 = !DIDerivedType(tag: DW_TAG_member, name: "incoming_stack_alignment", scope: !289, baseType: !260, size: 128, align: 64)
!292 = !DIDerivedType(tag: DW_TAG_member, name: "mode", scope: !289, baseType: !288, size: 8, align: 8, offset: 128)
!293 = !{!294, !295}
!294 = !DIEnumerator(name: "supervisor", value: 0, isUnsigned: true)
!295 = !DIEnumerator(name: "machine", value: 1, isUnsigned: true)
!296 = !DICompositeType(tag: DW_TAG_enumeration_type, name: "@typeInfo(builtin.CallingConvention).@\22union\22.tag_type.?", scope: !297, file: !4, line: 442, baseType: !44, size: 8, align: 8, elements: !380)
!297 = !DICompositeType(tag: DW_TAG_structure_type, name: "builtin.CallingConvention", scope: !0, size: 256, align: 64, elements: !298)
!298 = !{!299, !379}
!299 = !DIDerivedType(tag: DW_TAG_member, name: "payload", scope: !297, baseType: !300, size: 192, align: 64)
!300 = !DICompositeType(tag: DW_TAG_union_type, name: "builtin.CallingConvention:Payload", scope: !0, size: 192, align: 64, elements: !301)
!301 = !{!302, !306, !307, !308, !309, !310, !311, !316, !317, !318, !319, !320, !321, !322, !323, !324, !325, !326, !327, !328, !329, !330, !331, !332, !333, !334, !335, !336, !337, !338, !339, !340, !341, !342, !343, !344, !345, !346, !347, !348, !349, !350, !351, !352, !353, !354, !355, !356, !357, !358, !359, !360, !361, !362, !363, !364, !365, !366, !367, !368, !369, !370, !371, !372, !373, !374, !375, !376, !377, !378}
!302 = !DIDerivedType(tag: DW_TAG_member, name: "x86_64_sysv", scope: !300, baseType: !303, size: 128, align: 64)
!303 = !DICompositeType(tag: DW_TAG_structure_type, name: "builtin.CallingConvention.CommonOptions", scope: !0, size: 128, align: 64, elements: !304)
!304 = !{!305}
!305 = !DIDerivedType(tag: DW_TAG_member, name: "incoming_stack_alignment", scope: !303, baseType: !260, size: 128, align: 64)
!306 = !DIDerivedType(tag: DW_TAG_member, name: "x86_64_win", scope: !300, baseType: !303, size: 128, align: 64)
!307 = !DIDerivedType(tag: DW_TAG_member, name: "x86_64_regcall_v3_sysv", scope: !300, baseType: !303, size: 128, align: 64)
!308 = !DIDerivedType(tag: DW_TAG_member, name: "x86_64_regcall_v4_win", scope: !300, baseType: !303, size: 128, align: 64)
!309 = !DIDerivedType(tag: DW_TAG_member, name: "x86_64_vectorcall", scope: !300, baseType: !303, size: 128, align: 64)
!310 = !DIDerivedType(tag: DW_TAG_member, name: "x86_64_interrupt", scope: !300, baseType: !303, size: 128, align: 64)
!311 = !DIDerivedType(tag: DW_TAG_member, name: "x86_sysv", scope: !300, baseType: !312, size: 192, align: 64)
!312 = !DICompositeType(tag: DW_TAG_structure_type, name: "builtin.CallingConvention.X86RegparmOptions", scope: !0, size: 192, align: 64, elements: !313)
!313 = !{!314, !315}
!314 = !DIDerivedType(tag: DW_TAG_member, name: "incoming_stack_alignment", scope: !312, baseType: !260, size: 128, align: 64)
!315 = !DIDerivedType(tag: DW_TAG_member, name: "register_params", scope: !312, baseType: !21, size: 8, align: 8, offset: 128)
!316 = !DIDerivedType(tag: DW_TAG_member, name: "x86_win", scope: !300, baseType: !312, size: 192, align: 64)
!317 = !DIDerivedType(tag: DW_TAG_member, name: "x86_stdcall", scope: !300, baseType: !312, size: 192, align: 64)
!318 = !DIDerivedType(tag: DW_TAG_member, name: "x86_fastcall", scope: !300, baseType: !303, size: 128, align: 64)
!319 = !DIDerivedType(tag: DW_TAG_member, name: "x86_thiscall", scope: !300, baseType: !303, size: 128, align: 64)
!320 = !DIDerivedType(tag: DW_TAG_member, name: "x86_thiscall_mingw", scope: !300, baseType: !303, size: 128, align: 64)
!321 = !DIDerivedType(tag: DW_TAG_member, name: "x86_regcall_v3", scope: !300, baseType: !303, size: 128, align: 64)
!322 = !DIDerivedType(tag: DW_TAG_member, name: "x86_regcall_v4_win", scope: !300, baseType: !303, size: 128, align: 64)
!323 = !DIDerivedType(tag: DW_TAG_member, name: "x86_vectorcall", scope: !300, baseType: !303, size: 128, align: 64)
!324 = !DIDerivedType(tag: DW_TAG_member, name: "x86_interrupt", scope: !300, baseType: !303, size: 128, align: 64)
!325 = !DIDerivedType(tag: DW_TAG_member, name: "aarch64_aapcs", scope: !300, baseType: !303, size: 128, align: 64)
!326 = !DIDerivedType(tag: DW_TAG_member, name: "aarch64_aapcs_darwin", scope: !300, baseType: !303, size: 128, align: 64)
!327 = !DIDerivedType(tag: DW_TAG_member, name: "aarch64_aapcs_win", scope: !300, baseType: !303, size: 128, align: 64)
!328 = !DIDerivedType(tag: DW_TAG_member, name: "aarch64_vfabi", scope: !300, baseType: !303, size: 128, align: 64)
!329 = !DIDerivedType(tag: DW_TAG_member, name: "aarch64_vfabi_sve", scope: !300, baseType: !303, size: 128, align: 64)
!330 = !DIDerivedType(tag: DW_TAG_member, name: "arm_aapcs", scope: !300, baseType: !303, size: 128, align: 64)
!331 = !DIDerivedType(tag: DW_TAG_member, name: "arm_aapcs_vfp", scope: !300, baseType: !303, size: 128, align: 64)
!332 = !DIDerivedType(tag: DW_TAG_member, name: "arm_interrupt", scope: !300, baseType: !257, size: 192, align: 64)
!333 = !DIDerivedType(tag: DW_TAG_member, name: "mips64_n64", scope: !300, baseType: !303, size: 128, align: 64)
!334 = !DIDerivedType(tag: DW_TAG_member, name: "mips64_n32", scope: !300, baseType: !303, size: 128, align: 64)
!335 = !DIDerivedType(tag: DW_TAG_member, name: "mips64_interrupt", scope: !300, baseType: !274, size: 192, align: 64)
!336 = !DIDerivedType(tag: DW_TAG_member, name: "mips_o32", scope: !300, baseType: !303, size: 128, align: 64)
!337 = !DIDerivedType(tag: DW_TAG_member, name: "mips_interrupt", scope: !300, baseType: !274, size: 192, align: 64)
!338 = !DIDerivedType(tag: DW_TAG_member, name: "riscv64_lp64", scope: !300, baseType: !303, size: 128, align: 64)
!339 = !DIDerivedType(tag: DW_TAG_member, name: "riscv64_lp64_v", scope: !300, baseType: !303, size: 128, align: 64)
!340 = !DIDerivedType(tag: DW_TAG_member, name: "riscv64_interrupt", scope: !300, baseType: !289, size: 192, align: 64)
!341 = !DIDerivedType(tag: DW_TAG_member, name: "riscv32_ilp32", scope: !300, baseType: !303, size: 128, align: 64)
!342 = !DIDerivedType(tag: DW_TAG_member, name: "riscv32_ilp32_v", scope: !300, baseType: !303, size: 128, align: 64)
!343 = !DIDerivedType(tag: DW_TAG_member, name: "riscv32_interrupt", scope: !300, baseType: !289, size: 192, align: 64)
!344 = !DIDerivedType(tag: DW_TAG_member, name: "sparc64_sysv", scope: !300, baseType: !303, size: 128, align: 64)
!345 = !DIDerivedType(tag: DW_TAG_member, name: "sparc_sysv", scope: !300, baseType: !303, size: 128, align: 64)
!346 = !DIDerivedType(tag: DW_TAG_member, name: "powerpc64_elf", scope: !300, baseType: !303, size: 128, align: 64)
!347 = !DIDerivedType(tag: DW_TAG_member, name: "powerpc64_elf_altivec", scope: !300, baseType: !303, size: 128, align: 64)
!348 = !DIDerivedType(tag: DW_TAG_member, name: "powerpc64_elf_v2", scope: !300, baseType: !303, size: 128, align: 64)
!349 = !DIDerivedType(tag: DW_TAG_member, name: "powerpc_sysv", scope: !300, baseType: !303, size: 128, align: 64)
!350 = !DIDerivedType(tag: DW_TAG_member, name: "powerpc_sysv_altivec", scope: !300, baseType: !303, size: 128, align: 64)
!351 = !DIDerivedType(tag: DW_TAG_member, name: "powerpc_aix", scope: !300, baseType: !303, size: 128, align: 64)
!352 = !DIDerivedType(tag: DW_TAG_member, name: "powerpc_aix_altivec", scope: !300, baseType: !303, size: 128, align: 64)
!353 = !DIDerivedType(tag: DW_TAG_member, name: "wasm_mvp", scope: !300, baseType: !303, size: 128, align: 64)
!354 = !DIDerivedType(tag: DW_TAG_member, name: "arc_sysv", scope: !300, baseType: !303, size: 128, align: 64)
!355 = !DIDerivedType(tag: DW_TAG_member, name: "bpf_std", scope: !300, baseType: !303, size: 128, align: 64)
!356 = !DIDerivedType(tag: DW_TAG_member, name: "csky_sysv", scope: !300, baseType: !303, size: 128, align: 64)
!357 = !DIDerivedType(tag: DW_TAG_member, name: "csky_interrupt", scope: !300, baseType: !303, size: 128, align: 64)
!358 = !DIDerivedType(tag: DW_TAG_member, name: "hexagon_sysv", scope: !300, baseType: !303, size: 128, align: 64)
!359 = !DIDerivedType(tag: DW_TAG_member, name: "hexagon_sysv_hvx", scope: !300, baseType: !303, size: 128, align: 64)
!360 = !DIDerivedType(tag: DW_TAG_member, name: "lanai_sysv", scope: !300, baseType: !303, size: 128, align: 64)
!361 = !DIDerivedType(tag: DW_TAG_member, name: "loongarch64_lp64", scope: !300, baseType: !303, size: 128, align: 64)
!362 = !DIDerivedType(tag: DW_TAG_member, name: "loongarch32_ilp32", scope: !300, baseType: !303, size: 128, align: 64)
!363 = !DIDerivedType(tag: DW_TAG_member, name: "m68k_sysv", scope: !300, baseType: !303, size: 128, align: 64)
!364 = !DIDerivedType(tag: DW_TAG_member, name: "m68k_gnu", scope: !300, baseType: !303, size: 128, align: 64)
!365 = !DIDerivedType(tag: DW_TAG_member, name: "m68k_rtd", scope: !300, baseType: !303, size: 128, align: 64)
!366 = !DIDerivedType(tag: DW_TAG_member, name: "m68k_interrupt", scope: !300, baseType: !303, size: 128, align: 64)
!367 = !DIDerivedType(tag: DW_TAG_member, name: "msp430_eabi", scope: !300, baseType: !303, size: 128, align: 64)
!368 = !DIDerivedType(tag: DW_TAG_member, name: "or1k_sysv", scope: !300, baseType: !303, size: 128, align: 64)
!369 = !DIDerivedType(tag: DW_TAG_member, name: "propeller_sysv", scope: !300, baseType: !303, size: 128, align: 64)
!370 = !DIDerivedType(tag: DW_TAG_member, name: "s390x_sysv", scope: !300, baseType: !303, size: 128, align: 64)
!371 = !DIDerivedType(tag: DW_TAG_member, name: "s390x_sysv_vx", scope: !300, baseType: !303, size: 128, align: 64)
!372 = !DIDerivedType(tag: DW_TAG_member, name: "ve_sysv", scope: !300, baseType: !303, size: 128, align: 64)
!373 = !DIDerivedType(tag: DW_TAG_member, name: "xcore_xs1", scope: !300, baseType: !303, size: 128, align: 64)
!374 = !DIDerivedType(tag: DW_TAG_member, name: "xcore_xs2", scope: !300, baseType: !303, size: 128, align: 64)
!375 = !DIDerivedType(tag: DW_TAG_member, name: "xtensa_call0", scope: !300, baseType: !303, size: 128, align: 64)
!376 = !DIDerivedType(tag: DW_TAG_member, name: "xtensa_windowed", scope: !300, baseType: !303, size: 128, align: 64)
!377 = !DIDerivedType(tag: DW_TAG_member, name: "amdgcn_device", scope: !300, baseType: !303, size: 128, align: 64)
!378 = !DIDerivedType(tag: DW_TAG_member, name: "amdgcn_cs", scope: !300, baseType: !303, size: 128, align: 64)
!379 = !DIDerivedType(tag: DW_TAG_member, name: "tag", scope: !297, baseType: !296, size: 8, align: 8, offset: 192)
!380 = !{!381, !382, !383, !384, !385, !386, !387, !388, !389, !390, !391, !392, !393, !394, !395, !396, !397, !398, !399, !400, !401, !402, !403, !404, !405, !406, !407, !408, !409, !410, !411, !412, !413, !414, !415, !416, !417, !418, !419, !420, !421, !422, !423, !424, !425, !426, !427, !428, !429, !430, !431, !432, !433, !434, !435, !436, !437, !438, !439, !440, !441, !442, !443, !444, !445, !446, !447, !448, !449, !450, !451, !452, !453, !454, !455, !456, !457, !458, !459, !460, !461, !462, !463, !464, !465}
!381 = !DIEnumerator(name: "auto", value: 0, isUnsigned: true)
!382 = !DIEnumerator(name: "async", value: 1, isUnsigned: true)
!383 = !DIEnumerator(name: "naked", value: 2, isUnsigned: true)
!384 = !DIEnumerator(name: "inline", value: 3, isUnsigned: true)
!385 = !DIEnumerator(name: "x86_64_sysv", value: 4, isUnsigned: true)
!386 = !DIEnumerator(name: "x86_64_win", value: 5, isUnsigned: true)
!387 = !DIEnumerator(name: "x86_64_regcall_v3_sysv", value: 6, isUnsigned: true)
!388 = !DIEnumerator(name: "x86_64_regcall_v4_win", value: 7, isUnsigned: true)
!389 = !DIEnumerator(name: "x86_64_vectorcall", value: 8, isUnsigned: true)
!390 = !DIEnumerator(name: "x86_64_interrupt", value: 9, isUnsigned: true)
!391 = !DIEnumerator(name: "x86_sysv", value: 10, isUnsigned: true)
!392 = !DIEnumerator(name: "x86_win", value: 11, isUnsigned: true)
!393 = !DIEnumerator(name: "x86_stdcall", value: 12, isUnsigned: true)
!394 = !DIEnumerator(name: "x86_fastcall", value: 13, isUnsigned: true)
!395 = !DIEnumerator(name: "x86_thiscall", value: 14, isUnsigned: true)
!396 = !DIEnumerator(name: "x86_thiscall_mingw", value: 15, isUnsigned: true)
!397 = !DIEnumerator(name: "x86_regcall_v3", value: 16, isUnsigned: true)
!398 = !DIEnumerator(name: "x86_regcall_v4_win", value: 17, isUnsigned: true)
!399 = !DIEnumerator(name: "x86_vectorcall", value: 18, isUnsigned: true)
!400 = !DIEnumerator(name: "x86_interrupt", value: 19, isUnsigned: true)
!401 = !DIEnumerator(name: "aarch64_aapcs", value: 20, isUnsigned: true)
!402 = !DIEnumerator(name: "aarch64_aapcs_darwin", value: 21, isUnsigned: true)
!403 = !DIEnumerator(name: "aarch64_aapcs_win", value: 22, isUnsigned: true)
!404 = !DIEnumerator(name: "aarch64_vfabi", value: 23, isUnsigned: true)
!405 = !DIEnumerator(name: "aarch64_vfabi_sve", value: 24, isUnsigned: true)
!406 = !DIEnumerator(name: "arm_aapcs", value: 25, isUnsigned: true)
!407 = !DIEnumerator(name: "arm_aapcs_vfp", value: 26, isUnsigned: true)
!408 = !DIEnumerator(name: "arm_interrupt", value: 27, isUnsigned: true)
!409 = !DIEnumerator(name: "mips64_n64", value: 28, isUnsigned: true)
!410 = !DIEnumerator(name: "mips64_n32", value: 29, isUnsigned: true)
!411 = !DIEnumerator(name: "mips64_interrupt", value: 30, isUnsigned: true)
!412 = !DIEnumerator(name: "mips_o32", value: 31, isUnsigned: true)
!413 = !DIEnumerator(name: "mips_interrupt", value: 32, isUnsigned: true)
!414 = !DIEnumerator(name: "riscv64_lp64", value: 33, isUnsigned: true)
!415 = !DIEnumerator(name: "riscv64_lp64_v", value: 34, isUnsigned: true)
!416 = !DIEnumerator(name: "riscv64_interrupt", value: 35, isUnsigned: true)
!417 = !DIEnumerator(name: "riscv32_ilp32", value: 36, isUnsigned: true)
!418 = !DIEnumerator(name: "riscv32_ilp32_v", value: 37, isUnsigned: true)
!419 = !DIEnumerator(name: "riscv32_interrupt", value: 38, isUnsigned: true)
!420 = !DIEnumerator(name: "sparc64_sysv", value: 39, isUnsigned: true)
!421 = !DIEnumerator(name: "sparc_sysv", value: 40, isUnsigned: true)
!422 = !DIEnumerator(name: "powerpc64_elf", value: 41, isUnsigned: true)
!423 = !DIEnumerator(name: "powerpc64_elf_altivec", value: 42, isUnsigned: true)
!424 = !DIEnumerator(name: "powerpc64_elf_v2", value: 43, isUnsigned: true)
!425 = !DIEnumerator(name: "powerpc_sysv", value: 44, isUnsigned: true)
!426 = !DIEnumerator(name: "powerpc_sysv_altivec", value: 45, isUnsigned: true)
!427 = !DIEnumerator(name: "powerpc_aix", value: 46, isUnsigned: true)
!428 = !DIEnumerator(name: "powerpc_aix_altivec", value: 47, isUnsigned: true)
!429 = !DIEnumerator(name: "wasm_mvp", value: 48, isUnsigned: true)
!430 = !DIEnumerator(name: "arc_sysv", value: 49, isUnsigned: true)
!431 = !DIEnumerator(name: "avr_gnu", value: 50, isUnsigned: true)
!432 = !DIEnumerator(name: "avr_builtin", value: 51, isUnsigned: true)
!433 = !DIEnumerator(name: "avr_signal", value: 52, isUnsigned: true)
!434 = !DIEnumerator(name: "avr_interrupt", value: 53, isUnsigned: true)
!435 = !DIEnumerator(name: "bpf_std", value: 54, isUnsigned: true)
!436 = !DIEnumerator(name: "csky_sysv", value: 55, isUnsigned: true)
!437 = !DIEnumerator(name: "csky_interrupt", value: 56, isUnsigned: true)
!438 = !DIEnumerator(name: "hexagon_sysv", value: 57, isUnsigned: true)
!439 = !DIEnumerator(name: "hexagon_sysv_hvx", value: 58, isUnsigned: true)
!440 = !DIEnumerator(name: "lanai_sysv", value: 59, isUnsigned: true)
!441 = !DIEnumerator(name: "loongarch64_lp64", value: 60, isUnsigned: true)
!442 = !DIEnumerator(name: "loongarch32_ilp32", value: 61, isUnsigned: true)
!443 = !DIEnumerator(name: "m68k_sysv", value: 62, isUnsigned: true)
!444 = !DIEnumerator(name: "m68k_gnu", value: 63, isUnsigned: true)
!445 = !DIEnumerator(name: "m68k_rtd", value: 64, isUnsigned: true)
!446 = !DIEnumerator(name: "m68k_interrupt", value: 65, isUnsigned: true)
!447 = !DIEnumerator(name: "msp430_eabi", value: 66, isUnsigned: true)
!448 = !DIEnumerator(name: "or1k_sysv", value: 67, isUnsigned: true)
!449 = !DIEnumerator(name: "propeller_sysv", value: 68, isUnsigned: true)
!450 = !DIEnumerator(name: "s390x_sysv", value: 69, isUnsigned: true)
!451 = !DIEnumerator(name: "s390x_sysv_vx", value: 70, isUnsigned: true)
!452 = !DIEnumerator(name: "ve_sysv", value: 71, isUnsigned: true)
!453 = !DIEnumerator(name: "xcore_xs1", value: 72, isUnsigned: true)
!454 = !DIEnumerator(name: "xcore_xs2", value: 73, isUnsigned: true)
!455 = !DIEnumerator(name: "xtensa_call0", value: 74, isUnsigned: true)
!456 = !DIEnumerator(name: "xtensa_windowed", value: 75, isUnsigned: true)
!457 = !DIEnumerator(name: "amdgcn_device", value: 76, isUnsigned: true)
!458 = !DIEnumerator(name: "amdgcn_kernel", value: 77, isUnsigned: true)
!459 = !DIEnumerator(name: "amdgcn_cs", value: 78, isUnsigned: true)
!460 = !DIEnumerator(name: "nvptx_device", value: 79, isUnsigned: true)
!461 = !DIEnumerator(name: "nvptx_kernel", value: 80, isUnsigned: true)
!462 = !DIEnumerator(name: "spirv_device", value: 81, isUnsigned: true)
!463 = !DIEnumerator(name: "spirv_kernel", value: 82, isUnsigned: true)
!464 = !DIEnumerator(name: "spirv_fragment", value: 83, isUnsigned: true)
!465 = !DIEnumerator(name: "spirv_vertex", value: 84, isUnsigned: true)
!466 = !DICompositeType(tag: DW_TAG_enumeration_type, name: "builtin.OptimizeMode", scope: !4, file: !4, line: 154, baseType: !21, size: 8, align: 8, elements: !467)
!467 = !{!468, !469, !470, !471}
!468 = !DIEnumerator(name: "Debug", value: 0, isUnsigned: true)
!469 = !DIEnumerator(name: "ReleaseSafe", value: 1, isUnsigned: true)
!470 = !DIEnumerator(name: "ReleaseFast", value: 2, isUnsigned: true)
!471 = !DIEnumerator(name: "ReleaseSmall", value: 3, isUnsigned: true)
!472 = !DICompositeType(tag: DW_TAG_enumeration_type, name: "log.Level", scope: !473, file: !473, line: 98, baseType: !21, size: 8, align: 8, elements: !474)
!473 = !DIFile(filename: "log.zig", directory: "/home/alex/.config/Code/User/globalStorage/ziglang.vscode-zig/zig/x86_64-linux-0.15.2/lib/std")
!474 = !{!475, !476, !477, !478}
!475 = !DIEnumerator(name: "err", value: 0, isUnsigned: true)
!476 = !DIEnumerator(name: "warn", value: 1, isUnsigned: true)
!477 = !DIEnumerator(name: "info", value: 2, isUnsigned: true)
!478 = !DIEnumerator(name: "debug", value: 3, isUnsigned: true)
!479 = !DICompositeType(tag: DW_TAG_enumeration_type, name: "crypto.SideChannelsMitigations", scope: !480, file: !480, line: 225, baseType: !21, size: 8, align: 8, elements: !481)
!480 = !DIFile(filename: "crypto.zig", directory: "/home/alex/.config/Code/User/globalStorage/ziglang.vscode-zig/zig/x86_64-linux-0.15.2/lib/std")
!481 = !{!482, !483, !484, !485}
!482 = !DIEnumerator(name: "none", value: 0, isUnsigned: true)
!483 = !DIEnumerator(name: "basic", value: 1, isUnsigned: true)
!484 = !DIEnumerator(name: "medium", value: 2, isUnsigned: true)
!485 = !DIEnumerator(name: "full", value: 3, isUnsigned: true)
!486 = !{!487, !490, !494, !496, !498, !500, !502, !504, !506, !508, !517, !526, !528, !532, !535, !537, !539, !541, !543, !546, !548, !550, !570, !573, !575}
!487 = !DIGlobalVariableExpression(var: !488, expr: !DIExpression())
!488 = distinct !DIGlobalVariable(name: "zig_backend", linkageName: "builtin.zig_backend", scope: !489, file: !489, line: 6, type: !3, isLocal: true, isDefinition: true)
!489 = !DIFile(filename: "builtin.zig", directory: "/home/alex/.cache/zig/b/31705daedb809e57d9900155bdb4d8c3")
!490 = !DIGlobalVariableExpression(var: !491, expr: !DIExpression())
!491 = distinct !DIGlobalVariable(name: "simplified_logic", linkageName: "start.simplified_logic", scope: !492, file: !492, line: 17, type: !493, isLocal: true, isDefinition: true)
!492 = !DIFile(filename: "start.zig", directory: "/home/alex/.config/Code/User/globalStorage/ziglang.vscode-zig/zig/x86_64-linux-0.15.2/lib/std")
!493 = !DIBasicType(name: "bool", size: 8, encoding: DW_ATE_boolean)
!494 = !DIGlobalVariableExpression(var: !495, expr: !DIExpression())
!495 = distinct !DIGlobalVariable(name: "output_mode", linkageName: "builtin.output_mode", scope: !489, file: !489, line: 8, type: !20, isLocal: true, isDefinition: true)
!496 = !DIGlobalVariableExpression(var: !497, expr: !DIExpression())
!497 = distinct !DIGlobalVariable(name: "link_mode", linkageName: "builtin.link_mode", scope: !489, file: !489, line: 9, type: !26, isLocal: true, isDefinition: true)
!498 = !DIGlobalVariableExpression(var: !499, expr: !DIExpression())
!499 = distinct !DIGlobalVariable(name: "empty", linkageName: "Target.Cpu.Feature.Set.empty", scope: !32, file: !32, line: 1153, type: !49, isLocal: true, isDefinition: true)
!500 = !DIGlobalVariableExpression(var: !501, expr: !DIExpression())
!501 = distinct !DIGlobalVariable(name: "cpu", linkageName: "builtin.cpu", scope: !489, file: !489, line: 14, type: !33, isLocal: true, isDefinition: true)
!502 = !DIGlobalVariableExpression(var: !503, expr: !DIExpression())
!503 = distinct !DIGlobalVariable(name: "os", linkageName: "builtin.os", scope: !489, file: !489, line: 104, type: !105, isLocal: true, isDefinition: true)
!504 = !DIGlobalVariableExpression(var: !505, expr: !DIExpression())
!505 = distinct !DIGlobalVariable(name: "abi", linkageName: "builtin.abi", scope: !489, file: !489, line: 13, type: !209, isLocal: true, isDefinition: true)
!506 = !DIGlobalVariableExpression(var: !507, expr: !DIExpression())
!507 = distinct !DIGlobalVariable(name: "object_format", linkageName: "builtin.object_format", scope: !489, file: !489, line: 134, type: !242, isLocal: true, isDefinition: true)
!508 = !DIGlobalVariableExpression(var: !509, expr: !DIExpression())
!509 = distinct !DIGlobalVariable(name: "none", linkageName: "Target.DynamicLinker.none", scope: !32, file: !32, line: 2072, type: !510, isLocal: true, isDefinition: true)
!510 = !DICompositeType(tag: DW_TAG_structure_type, name: "Target.DynamicLinker", scope: !0, size: 2048, align: 8, elements: !511)
!511 = !{!512, !516}
!512 = !DIDerivedType(tag: DW_TAG_member, name: "buffer", scope: !510, baseType: !513, size: 2040, align: 8)
!513 = !DICompositeType(tag: DW_TAG_array_type, baseType: !44, size: 2040, align: 8, elements: !514)
!514 = !{!515}
!515 = !DISubrange(count: 255, lowerBound: 0)
!516 = !DIDerivedType(tag: DW_TAG_member, name: "len", scope: !510, baseType: !44, size: 8, align: 8, offset: 2040)
!517 = !DIGlobalVariableExpression(var: !518, expr: !DIExpression())
!518 = distinct !DIGlobalVariable(name: "target", linkageName: "builtin.target", scope: !489, file: !489, line: 127, type: !519, isLocal: true, isDefinition: true)
!519 = !DICompositeType(tag: DW_TAG_structure_type, name: "Target", scope: !0, size: 4032, align: 64, elements: !520)
!520 = !{!521, !522, !523, !524, !525}
!521 = !DIDerivedType(tag: DW_TAG_member, name: "cpu", scope: !519, baseType: !33, size: 448, align: 64)
!522 = !DIDerivedType(tag: DW_TAG_member, name: "os", scope: !519, baseType: !105, size: 1472, align: 64, offset: 448)
!523 = !DIDerivedType(tag: DW_TAG_member, name: "abi", scope: !519, baseType: !209, size: 8, align: 8, offset: 1920)
!524 = !DIDerivedType(tag: DW_TAG_member, name: "ofmt", scope: !519, baseType: !242, size: 8, align: 8, offset: 1928)
!525 = !DIDerivedType(tag: DW_TAG_member, name: "dynamic_linker", scope: !519, baseType: !510, size: 2048, align: 8, offset: 1936)
!526 = !DIGlobalVariableExpression(var: !527, expr: !DIExpression())
!527 = distinct !DIGlobalVariable(name: "c", linkageName: "builtin.CallingConvention.c", scope: !4, file: !4, line: 172, type: !297, isLocal: true, isDefinition: true)
!528 = !DIGlobalVariableExpression(var: !529, expr: !DIExpression())
!529 = distinct !DIGlobalVariable(name: "espeakCHARS_UTF8", linkageName: "cimport.espeakCHARS_UTF8", scope: !530, file: !530, line: 1415, type: !531, isLocal: true, isDefinition: true)
!530 = !DIFile(filename: "cimport.zig", directory: "/home/alex/repos/tts/.zig-cache/o/01775cd9b83f23a19a7aaabc27efba4c")
!531 = !DIBasicType(name: "c_int", size: 32, encoding: DW_ATE_signed)
!532 = !DIGlobalVariableExpression(var: !533, expr: !DIExpression())
!533 = distinct !DIGlobalVariable(name: "use_vectors", linkageName: "mem.use_vectors", scope: !534, file: !534, line: 677, type: !493, isLocal: true, isDefinition: true)
!534 = !DIFile(filename: "mem.zig", directory: "/home/alex/.config/Code/User/globalStorage/ziglang.vscode-zig/zig/x86_64-linux-0.15.2/lib/std")
!535 = !DIGlobalVariableExpression(var: !536, expr: !DIExpression())
!536 = distinct !DIGlobalVariable(name: "fuzz", linkageName: "builtin.fuzz", scope: !489, file: !489, line: 141, type: !493, isLocal: true, isDefinition: true)
!537 = !DIGlobalVariableExpression(var: !538, expr: !DIExpression())
!538 = distinct !DIGlobalVariable(name: "use_vectors_for_comparison", linkageName: "mem.use_vectors_for_comparison", scope: !534, file: !534, line: 689, type: !493, isLocal: true, isDefinition: true)
!539 = !DIGlobalVariableExpression(var: !540, expr: !DIExpression())
!540 = distinct !DIGlobalVariable(name: "valgrind_support", linkageName: "builtin.valgrind_support", scope: !489, file: !489, line: 139, type: !493, isLocal: true, isDefinition: true)
!541 = !DIGlobalVariableExpression(var: !542, expr: !DIExpression())
!542 = distinct !DIGlobalVariable(name: "mode", linkageName: "builtin.mode", scope: !489, file: !489, line: 135, type: !466, isLocal: true, isDefinition: true)
!543 = !DIGlobalVariableExpression(var: !544, expr: !DIExpression())
!544 = distinct !DIGlobalVariable(name: "runtime_safety", linkageName: "debug.runtime_safety", scope: !545, file: !545, line: 166, type: !493, isLocal: true, isDefinition: true)
!545 = !DIFile(filename: "debug.zig", directory: "/home/alex/.config/Code/User/globalStorage/ziglang.vscode-zig/zig/x86_64-linux-0.15.2/lib/std")
!546 = !DIGlobalVariableExpression(var: !547, expr: !DIExpression())
!547 = distinct !DIGlobalVariable(name: "default_enable_segfault_handler", linkageName: "debug.default_enable_segfault_handler", scope: !545, file: !545, line: 1392, type: !493, isLocal: true, isDefinition: true)
!548 = !DIGlobalVariableExpression(var: !549, expr: !DIExpression())
!549 = distinct !DIGlobalVariable(name: "default_level", linkageName: "log.default_level", scope: !473, file: !473, line: 102, type: !472, isLocal: true, isDefinition: true)
!550 = !DIGlobalVariableExpression(var: !551, expr: !DIExpression())
!551 = distinct !DIGlobalVariable(name: "options", linkageName: "std.options", scope: !552, file: !552, line: 115, type: !553, isLocal: true, isDefinition: true)
!552 = !DIFile(filename: "std.zig", directory: "/home/alex/.config/Code/User/globalStorage/ziglang.vscode-zig/zig/x86_64-linux-0.15.2/lib/std")
!553 = !DICompositeType(tag: DW_TAG_structure_type, name: "std.Options", scope: !0, size: 384, align: 64, elements: !554)
!554 = !{!555, !560, !561, !562, !563, !564, !565, !566, !567, !568, !569}
!555 = !DIDerivedType(tag: DW_TAG_member, name: "page_size_min", scope: !553, baseType: !556, size: 128, align: 64)
!556 = !DICompositeType(tag: DW_TAG_structure_type, name: "?usize", scope: !0, size: 128, align: 64, elements: !557)
!557 = !{!558, !559}
!558 = !DIDerivedType(tag: DW_TAG_member, name: "data", scope: !556, baseType: !46, size: 64, align: 64)
!559 = !DIDerivedType(tag: DW_TAG_member, name: "some", scope: !556, baseType: !44, size: 8, align: 8, offset: 64)
!560 = !DIDerivedType(tag: DW_TAG_member, name: "page_size_max", scope: !553, baseType: !556, size: 128, align: 64, offset: 128)
!561 = !DIDerivedType(tag: DW_TAG_member, name: "fmt_max_depth", scope: !553, baseType: !46, size: 64, align: 64, offset: 256)
!562 = !DIDerivedType(tag: DW_TAG_member, name: "enable_segfault_handler", scope: !553, baseType: !493, size: 8, align: 8, offset: 320)
!563 = !DIDerivedType(tag: DW_TAG_member, name: "log_level", scope: !553, baseType: !472, size: 8, align: 8, offset: 328)
!564 = !DIDerivedType(tag: DW_TAG_member, name: "crypto_always_getrandom", scope: !553, baseType: !493, size: 8, align: 8, offset: 336)
!565 = !DIDerivedType(tag: DW_TAG_member, name: "crypto_fork_safety", scope: !553, baseType: !493, size: 8, align: 8, offset: 344)
!566 = !DIDerivedType(tag: DW_TAG_member, name: "keep_sigpipe", scope: !553, baseType: !493, size: 8, align: 8, offset: 352)
!567 = !DIDerivedType(tag: DW_TAG_member, name: "http_disable_tls", scope: !553, baseType: !493, size: 8, align: 8, offset: 360)
!568 = !DIDerivedType(tag: DW_TAG_member, name: "http_enable_ssl_key_log_file", scope: !553, baseType: !493, size: 8, align: 8, offset: 368)
!569 = !DIDerivedType(tag: DW_TAG_member, name: "side_channels_mitigations", scope: !553, baseType: !479, size: 8, align: 8, offset: 376)
!570 = !DIGlobalVariableExpression(var: !571, expr: !DIExpression())
!571 = distinct !DIGlobalVariable(name: "page_size_min_default", linkageName: "heap.page_size_min_default", scope: !572, file: !572, line: 696, type: !556, isLocal: true, isDefinition: true)
!572 = !DIFile(filename: "heap.zig", directory: "/home/alex/.config/Code/User/globalStorage/ziglang.vscode-zig/zig/x86_64-linux-0.15.2/lib/std")
!573 = !DIGlobalVariableExpression(var: !574, expr: !DIExpression())
!574 = distinct !DIGlobalVariable(name: "page_size_min", linkageName: "heap.page_size_min", scope: !572, file: !572, line: 46, type: !46, isLocal: true, isDefinition: true)
!575 = !DIGlobalVariableExpression(var: !576, expr: !DIExpression())
!576 = distinct !DIGlobalVariable(name: "znver4", linkageName: "Target.x86.cpu.znver4", scope: !577, file: !577, line: 4924, type: !37, isLocal: true, isDefinition: true)
!577 = !DIFile(filename: "x86.zig", directory: "/home/alex/.config/Code/User/globalStorage/ziglang.vscode-zig/zig/x86_64-linux-0.15.2/lib/std/Target")
!578 = !{i32 2, !"Debug Info Version", i32 3}
!579 = !{i32 7, !"Dwarf Version", i32 4}
!580 = distinct !DISubprogram(name: "say", linkageName: "test-espeak.say", scope: !581, file: !581, line: 19, type: !582, scopeLine: 19, flags: DIFlagStaticMember, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !0)
!581 = !DIFile(filename: "test-espeak.zig", directory: "/home/alex/repos/tts")
!582 = !DISubroutineType(types: !583)
!583 = !{!584, !43}
!584 = !DIBasicType(name: "void", encoding: DW_ATE_signed)
!585 = !DILocalVariable(name: "text", arg: 1, scope: !580, file: !581, line: 19, type: !43)
!586 = !DILocation(line: 19, column: 41, scope: !580)
!587 = !DILocalVariable(name: "value", arg: 1, scope: !588, file: !534, line: 1066, type: !43)
!588 = distinct !DISubprogram(name: "len__anon_1750", linkageName: "mem.len__anon_1750", scope: !534, file: !534, line: 1066, type: !589, scopeLine: 1066, flags: DIFlagStaticMember, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !0)
!589 = !DISubroutineType(types: !590)
!590 = !{!46, !43}
!591 = !DILocation(line: 1066, column: 34, scope: !588, inlinedAt: !592)
!592 = distinct !DILocation(line: 20, column: 41, scope: !580)
!593 = !DILocalVariable(name: "sentinel", scope: !588, file: !534, line: 579, type: !44)
!594 = !DILocation(line: 1070, column: 47, scope: !588, inlinedAt: !592)
!595 = !DILocation(line: 1114, column: 36, scope: !596, inlinedAt: !599)
!596 = !DILexicalBlock(scope: !597, file: !534, line: 1098, column: 83)
!597 = !DILexicalBlock(scope: !598, file: !534, line: 1095, column: 9)
!598 = distinct !DISubprogram(name: "indexOfSentinel__anon_1787", linkageName: "mem.indexOfSentinel__anon_1787", scope: !534, file: !534, line: 1092, type: !589, scopeLine: 1092, flags: DIFlagStaticMember, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !0)
!599 = distinct !DILocation(line: 1072, column: 39, scope: !588, inlinedAt: !592)
!600 = !DILocalVariable(name: "p", arg: 1, scope: !598, file: !534, line: 1092, type: !43)
!601 = !DILocation(line: 1092, column: 94, scope: !598, inlinedAt: !599)
!602 = !DILocalVariable(name: "i", scope: !598, file: !534, line: 1093, type: !46)
!603 = !DILocation(line: 0, scope: !598, inlinedAt: !599)
!604 = !DILocalVariable(name: "page_size", scope: !596, file: !534, line: 1105, type: !46)
!605 = !DILocation(line: 1105, column: 43, scope: !596, inlinedAt: !599)
!606 = !DILocalVariable(name: "mask", scope: !596, file: !534, line: 1108, type: !607)
!607 = !DICompositeType(tag: DW_TAG_array_type, baseType: !608, size: 512, align: 512, flags: DIFlagVector, elements: !609)
!608 = !DIBasicType(name: "@Vector(64, u8)", size: 8, encoding: DW_ATE_unsigned)
!609 = !{!610}
!610 = !DISubrange(count: 64, lowerBound: 0)
!611 = !DILocation(line: 1108, column: 17, scope: !596, inlinedAt: !599)
!612 = !DILocalVariable(name: "ok", arg: 1, scope: !613, file: !545, line: 558, type: !493)
!613 = distinct !DISubprogram(name: "assert", linkageName: "debug.assert", scope: !545, file: !545, line: 558, type: !614, scopeLine: 558, flags: DIFlagStaticMember, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !0)
!614 = !DISubroutineType(types: !615)
!615 = !{!584, !493}
!616 = !DILocation(line: 558, column: 30, scope: !613, inlinedAt: !617)
!617 = distinct !DILocation(line: 1111, column: 23, scope: !596, inlinedAt: !599)
!618 = !DILocalVariable(name: "start_addr", scope: !596, file: !534, line: 1114, type: !46)
!619 = !DILocation(line: 1115, column: 64, scope: !596, inlinedAt: !599)
!620 = !DILocalVariable(name: "offset_in_page", scope: !596, file: !534, line: 1115, type: !46)
!621 = !DILocation(line: 1116, column: 49, scope: !622, inlinedAt: !599)
!622 = !DILexicalBlock(scope: !596, file: !534, line: 1116, column: 21)
!623 = !{!"branch_weights", i32 2000, i32 1}
!624 = !DILocation(line: 1132, column: 62, scope: !625, inlinedAt: !599)
!625 = !DILexicalBlockFile(scope: !626, file: !534, discriminator: 2)
!626 = !DILexicalBlock(scope: !627, file: !534, line: 1126, column: 21)
!627 = !DILexicalBlock(scope: !628, file: !534, line: 1126, column: 21)
!628 = !DILexicalBlock(scope: !629, file: !534, line: 1126, column: 21)
!629 = !DILexicalBlock(scope: !622, file: !534, line: 1124, column: 23)
!630 = !DILocation(line: 1133, column: 30, scope: !631, inlinedAt: !599)
!631 = !DILexicalBlock(scope: !632, file: !534, line: 1133, column: 29)
!632 = !DILexicalBlock(scope: !626, file: !534, line: 1132, column: 62)
!633 = !DILocation(line: 1137, column: 56, scope: !596, inlinedAt: !599)
!634 = !DILocation(line: 1137, column: 42, scope: !596, inlinedAt: !599)
!635 = !DILocalVariable(name: "addr", arg: 1, scope: !636, file: !534, line: 4609, type: !46)
!636 = distinct !DISubprogram(name: "isAligned", linkageName: "mem.isAligned", scope: !534, file: !534, line: 4609, type: !637, scopeLine: 4609, flags: DIFlagStaticMember, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !0)
!637 = !DISubroutineType(types: !638)
!638 = !{!493, !46, !46}
!639 = !DILocation(line: 4609, column: 54, scope: !636, inlinedAt: !640)
!640 = distinct !DILocation(line: 1137, column: 41, scope: !596, inlinedAt: !599)
!641 = !DILocalVariable(name: "alignment", arg: 2, scope: !636, file: !534, line: 4609, type: !46)
!642 = !DILocalVariable(name: "addr", arg: 1, scope: !643, file: !534, line: 4613, type: !5)
!643 = distinct !DISubprogram(name: "isAlignedGeneric__anon_2243", linkageName: "mem.isAlignedGeneric__anon_2243", scope: !534, file: !534, line: 4613, type: !644, scopeLine: 4613, flags: DIFlagStaticMember, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !0)
!644 = !DISubroutineType(types: !645)
!645 = !{!493, !5, !5}
!646 = !DILocation(line: 4613, column: 71, scope: !643, inlinedAt: !647)
!647 = distinct !DILocation(line: 4610, column: 28, scope: !636, inlinedAt: !640)
!648 = !DILocalVariable(name: "alignment", arg: 2, scope: !643, file: !534, line: 4613, type: !5)
!649 = !DILocation(line: 4614, column: 25, scope: !643, inlinedAt: !647)
!650 = !DILocation(line: 558, column: 30, scope: !613, inlinedAt: !651)
!651 = distinct !DILocation(line: 1137, column: 23, scope: !652, inlinedAt: !599)
!652 = !DILexicalBlockFile(scope: !596, file: !534, discriminator: 2)
!653 = !DILocation(line: 559, column: 9, scope: !654, inlinedAt: !651)
!654 = !DILexicalBlock(scope: !613, file: !545, line: 559, column: 9)
!655 = !DILocation(line: 1137, column: 23, scope: !596, inlinedAt: !599)
!656 = !DILocation(line: 1118, column: 48, scope: !657, inlinedAt: !599)
!657 = !DILexicalBlock(scope: !622, file: !534, line: 1116, column: 49)
!658 = !DILocalVariable(name: "block", scope: !657, file: !534, line: 1118, type: !607)
!659 = !DILocation(line: 1119, column: 21, scope: !657, inlinedAt: !599)
!660 = !DILocalVariable(name: "matches", scope: !657, file: !534, line: 1119, type: !661)
!661 = !DICompositeType(tag: DW_TAG_array_type, baseType: !662, size: 64, align: 64, flags: DIFlagVector, elements: !609)
!662 = !DIBasicType(name: "bool", size: 1, encoding: DW_ATE_boolean)
!663 = !DILocation(line: 1120, column: 25, scope: !664, inlinedAt: !599)
!664 = !DILexicalBlock(scope: !657, file: !534, line: 1120, column: 25)
!665 = !DILocalVariable(name: "vec", arg: 1, scope: !666, file: !667, line: 2485, type: !661)
!666 = distinct !DISubprogram(name: "firstTrue__anon_2131", linkageName: "simd.firstTrue__anon_2131", scope: !667, file: !667, line: 305, type: !668, scopeLine: 2485, flags: DIFlagStaticMember, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !0)
!667 = !DIFile(filename: "simd.zig", directory: "/home/alex/.config/Code/User/globalStorage/ziglang.vscode-zig/zig/x86_64-linux-0.15.2/lib/std")
!668 = !DISubroutineType(types: !669)
!669 = !{!584, !670, !661}
!670 = !DIDerivedType(tag: DW_TAG_pointer_type, name: "*?u6", baseType: !671, size: 64, align: 8)
!671 = !DICompositeType(tag: DW_TAG_structure_type, name: "?u6", scope: !0, size: 16, align: 8, elements: !672)
!672 = !{!673, !674}
!673 = !DIDerivedType(tag: DW_TAG_member, name: "data", scope: !671, baseType: !57, size: 8, align: 8)
!674 = !DIDerivedType(tag: DW_TAG_member, name: "some", scope: !671, baseType: !44, size: 8, align: 8, offset: 8)
!675 = !DILocation(line: 2485, column: 2183, scope: !666, inlinedAt: !676)
!676 = distinct !DILocation(line: 1121, column: 54, scope: !677, inlinedAt: !599)
!677 = !DILexicalBlock(scope: !664, file: !534, line: 1120, column: 25)
!678 = !DILocalVariable(name: "all_max", scope: !666, file: !667, line: 312, type: !679)
!679 = !DICompositeType(tag: DW_TAG_array_type, baseType: !680, size: 512, align: 512, flags: DIFlagVector, elements: !609)
!680 = !DIBasicType(name: "@Vector(64, u6)", size: 6, encoding: DW_ATE_unsigned)
!681 = !DILocation(line: 312, column: 5, scope: !666, inlinedAt: !676)
!682 = !DILocation(line: 313, column: 48, scope: !666, inlinedAt: !676)
!683 = !DILocalVariable(name: "indices", scope: !666, file: !667, line: 313, type: !679)
!684 = !DILocation(line: 314, column: 5, scope: !666, inlinedAt: !676)
!685 = !{!686}
!686 = distinct !{!686, !687, !"simd.firstTrue__anon_2131: argument 0"}
!687 = distinct !{!687, !"simd.firstTrue__anon_2131"}
!688 = !DILocation(line: 1121, column: 63, scope: !677, inlinedAt: !599)
!689 = !DILocation(line: 1121, column: 34, scope: !677, inlinedAt: !599)
!690 = !DILocation(line: 1121, column: 25, scope: !677, inlinedAt: !599)
!691 = !DILocalVariable(name: "addr", arg: 1, scope: !692, file: !534, line: 35252, type: !46)
!692 = distinct !DISubprogram(name: "alignForward__anon_2137", linkageName: "mem.alignForward__anon_2137", scope: !534, file: !534, line: 4451, type: !693, scopeLine: 35252, flags: DIFlagStaticMember, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !0)
!693 = !DISubroutineType(types: !694)
!694 = !{!46, !46, !46}
!695 = !DILocation(line: 35252, column: 4, scope: !692, inlinedAt: !696)
!696 = distinct !DILocation(line: 1124, column: 56, scope: !657, inlinedAt: !599)
!697 = !DILocalVariable(name: "alignment", arg: 2, scope: !692, file: !534, line: 35252, type: !46)
!698 = !DILocation(line: 4453, column: 34, scope: !692, inlinedAt: !696)
!699 = !DILocalVariable(name: "addr", arg: 1, scope: !700, file: !534, line: 36159, type: !46)
!700 = distinct !DISubprogram(name: "alignBackward__anon_2237", linkageName: "mem.alignBackward__anon_2237", scope: !534, file: !534, line: 4576, type: !693, scopeLine: 36159, flags: DIFlagStaticMember, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !0)
!701 = !DILocation(line: 36159, column: 7, scope: !700, inlinedAt: !702)
!702 = distinct !DILocation(line: 4453, column: 25, scope: !692, inlinedAt: !696)
!703 = !DILocalVariable(name: "alignment", arg: 2, scope: !700, file: !534, line: 36159, type: !46)
!704 = !DILocation(line: 4581, column: 31, scope: !700, inlinedAt: !702)
!705 = !DILocation(line: 1124, column: 88, scope: !657, inlinedAt: !599)
!706 = !DILocation(line: 1124, column: 23, scope: !657, inlinedAt: !599)
!707 = !DILocation(line: 1132, column: 79, scope: !708, inlinedAt: !599)
!708 = !DILexicalBlockFile(scope: !632, file: !534, discriminator: 8)
!709 = !DILocation(line: 0, scope: !596, inlinedAt: !599)
!710 = !DILocation(line: 1139, column: 75, scope: !711, inlinedAt: !599)
!711 = !DILexicalBlock(scope: !712, file: !534, line: 1138, column: 24)
!712 = !DILexicalBlock(scope: !596, file: !534, line: 1137, column: 23)
!713 = !DILocalVariable(name: "block", scope: !711, file: !534, line: 1139, type: !714)
!714 = !DIDerivedType(tag: DW_TAG_pointer_type, name: "*@Vector(64, u8)", baseType: !607, size: 64, align: 512)
!715 = !DILocation(line: 1139, column: 49, scope: !711, inlinedAt: !599)
!716 = !DILocation(line: 1140, column: 21, scope: !711, inlinedAt: !599)
!717 = !DILocalVariable(name: "matches", scope: !711, file: !534, line: 1140, type: !661)
!718 = !DILocation(line: 1141, column: 25, scope: !719, inlinedAt: !599)
!719 = !DILexicalBlock(scope: !711, file: !534, line: 1141, column: 25)
!720 = !DILocation(line: 1144, column: 23, scope: !711, inlinedAt: !599)
!721 = !DILocation(line: 2485, column: 2183, scope: !666, inlinedAt: !722)
!722 = distinct !DILocation(line: 1142, column: 54, scope: !723, inlinedAt: !599)
!723 = !DILexicalBlock(scope: !719, file: !534, line: 1141, column: 25)
!724 = !DILocation(line: 312, column: 5, scope: !666, inlinedAt: !722)
!725 = !DILocation(line: 313, column: 48, scope: !666, inlinedAt: !722)
!726 = !DILocation(line: 314, column: 5, scope: !666, inlinedAt: !722)
!727 = !{!728}
!728 = distinct !{!728, !729, !"simd.firstTrue__anon_2131: argument 0"}
!729 = distinct !{!729, !"simd.firstTrue__anon_2131"}
!730 = !DILocation(line: 1142, column: 63, scope: !723, inlinedAt: !599)
!731 = !DILocation(line: 1142, column: 34, scope: !723, inlinedAt: !599)
!732 = !DILocation(line: 1142, column: 25, scope: !723, inlinedAt: !599)
!733 = !DILocation(line: 20, column: 23, scope: !734)
!734 = !DILexicalBlockFile(scope: !580, file: !581, discriminator: 2)
!735 = !DILocation(line: 20, column: 23, scope: !580)
