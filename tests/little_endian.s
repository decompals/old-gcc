	.file	1 "tests/little_endian.c"

 # GNU C 2.7.2.1 [AL 1.1, MM 40] BSD Mips compiled by GNU C

 # Cc1 defaults:

 # Cc1 arguments (-G value = 8, Cpu = 3000, ISA = 1):
 # -quiet -O2

gcc2_compiled.:
__gnu_compiled_c:
	.text
	.align	2
	.globl	bar

	.text
	.text
	.ent	bar
bar:
	.frame	$sp,0,$31		# vars= 0, regs= 0/0, args= 0, extra= 0
	.mask	0x00000000,0
	.fmask	0x00000000,0
	lbu	$2,3($4)
	j	$31
	.end	bar
