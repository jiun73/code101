	.text
	.file	"test"
	.globl	main                            # -- Begin function main
	.p2align	4, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# %bb.0:                                # %entry
	pushq	%rax
	.cfi_def_cfa_offset 16
	movl	$.Lfmt_s, %edi
	movl	$.Lmessage, %esi
	xorl	%eax, %eax
	callq	printf@PLT
	movl	$.Lfmt_s, %edi
	movl	$.Lmessage.1, %esi
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
	.type	.Lfmt_d,@object                 # @fmt_d
	.section	.rodata.str1.1,"aMS",@progbits,1
.Lfmt_d:
	.asciz	"%d\n"
	.size	.Lfmt_d, 4

	.type	.Lfmt_s,@object                 # @fmt_s
.Lfmt_s:
	.asciz	"%s\n"
	.size	.Lfmt_s, 4

	.type	.Lmessage,@object               # @message
.Lmessage:
	.asciz	"\"bonjour monde\""
	.size	.Lmessage, 16

	.type	.Lmessage.1,@object             # @message.1
.Lmessage.1:
	.asciz	"\"bonjour monde2\""
	.size	.Lmessage.1, 17

	.section	".note.GNU-stack","",@progbits
