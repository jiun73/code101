	.file	"programme"
	.text
	.globl	main                            # -- Begin function main
	.p2align	4
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# %bb.0:                                # %entry
	pushq	%rax
	.cfi_def_cfa_offset 16
	movl	$10, 4(%rsp)
	movl	$fmt_d, %edi
	movl	$50, %esi
	xorl	%eax, %eax
	callq	printf@PLT
	xorl	%eax, %eax
	popq	%rcx
	.cfi_def_cfa_offset 8
	retq
.Lfunc_end0:
	.size	main, .Lfunc_end0-main
	.cfi_endproc
                                        # -- End function
	.type	fmt_d,@object                   # @fmt_d
	.section	.rodata.str1.1,"aMS",@progbits,1
fmt_d:
	.asciz	"%d\n"
	.size	fmt_d, 4

	.type	fmt_s,@object                   # @fmt_s
fmt_s:
	.asciz	"%s\n"
	.size	fmt_s, 4

	.section	".note.GNU-stack","",@progbits
