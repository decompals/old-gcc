/* Widening of variadic arguments, for building the old GCCs (2.91.66, 2.95.2) natively on Apple's arm64.
   Force-included with -include when the compiler itself is built; written by arm64-varargs-gen.py, whose table
   says how many fixed arguments each variadic function has.

   Apple's arm64 ABI gives every variadic argument its own 8-byte stack slot, and an int written there leaves the
   upper 4 bytes undefined. These sources pass ints (a literal 0, say) through "..." where the callee's va_arg
   reads a pointer or a 64-bit HOST_WIDE_INT, which x86_64 tolerates by accident. Every argument after the fixed
   ones goes through DW: doubles and floats are left alone (a float is promoted anyway), anything else a long (a pointer's bits are unchanged, an int is
   sign-extended, so 0 read as a pointer is NULL).

   Prototypes and definitions that mention "..." must not be macro-expanded: psx-gcc-macos-egcs.sh writes their
   names in parentheses, (gen_rtx), first. A call through a parenthesised name isn't expanded either. */
#ifndef ARM64_VARARGS_H
#define ARM64_VARARGS_H
#define DW(x) _Generic((x), double: (x), float: (x), default: (long)(x))
#define DW_1(x1) DW(x1)
#define DW_2(x1,x2) DW(x1),DW(x2)
#define DW_3(x1,x2,x3) DW(x1),DW(x2),DW(x3)
#define DW_4(x1,x2,x3,x4) DW(x1),DW(x2),DW(x3),DW(x4)
#define DW_5(x1,x2,x3,x4,x5) DW(x1),DW(x2),DW(x3),DW(x4),DW(x5)
#define DW_6(x1,x2,x3,x4,x5,x6) DW(x1),DW(x2),DW(x3),DW(x4),DW(x5),DW(x6)
#define DW_7(x1,x2,x3,x4,x5,x6,x7) DW(x1),DW(x2),DW(x3),DW(x4),DW(x5),DW(x6),DW(x7)
#define DW_8(x1,x2,x3,x4,x5,x6,x7,x8) DW(x1),DW(x2),DW(x3),DW(x4),DW(x5),DW(x6),DW(x7),DW(x8)
#define DW_9(x1,x2,x3,x4,x5,x6,x7,x8,x9) DW(x1),DW(x2),DW(x3),DW(x4),DW(x5),DW(x6),DW(x7),DW(x8),DW(x9)
#define DW_10(x1,x2,x3,x4,x5,x6,x7,x8,x9,x10) DW(x1),DW(x2),DW(x3),DW(x4),DW(x5),DW(x6),DW(x7),DW(x8),DW(x9),DW(x10)
#define DW_11(x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11) DW(x1),DW(x2),DW(x3),DW(x4),DW(x5),DW(x6),DW(x7),DW(x8),DW(x9),DW(x10),DW(x11)
#define DW_12(x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12) DW(x1),DW(x2),DW(x3),DW(x4),DW(x5),DW(x6),DW(x7),DW(x8),DW(x9),DW(x10),DW(x11),DW(x12)
#define DW_13(x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13) DW(x1),DW(x2),DW(x3),DW(x4),DW(x5),DW(x6),DW(x7),DW(x8),DW(x9),DW(x10),DW(x11),DW(x12),DW(x13)
#define DW_14(x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14) DW(x1),DW(x2),DW(x3),DW(x4),DW(x5),DW(x6),DW(x7),DW(x8),DW(x9),DW(x10),DW(x11),DW(x12),DW(x13),DW(x14)
#define DW_15(x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15) DW(x1),DW(x2),DW(x3),DW(x4),DW(x5),DW(x6),DW(x7),DW(x8),DW(x9),DW(x10),DW(x11),DW(x12),DW(x13),DW(x14),DW(x15)
#define DW_16(x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16) DW(x1),DW(x2),DW(x3),DW(x4),DW(x5),DW(x6),DW(x7),DW(x8),DW(x9),DW(x10),DW(x11),DW(x12),DW(x13),DW(x14),DW(x15),DW(x16)
#define DW_PICK(_1,_2,_3,_4,_5,_6,_7,_8,_9,_10,_11,_12,_13,_14,_15,_16,NAME,...) NAME
#define DWALL(...) DW_PICK(__VA_ARGS__,DW_16,DW_15,DW_14,DW_13,DW_12,DW_11,DW_10,DW_9,DW_8,DW_7,DW_6,DW_5,DW_4,DW_3,DW_2,DW_1,)(__VA_ARGS__)
#define gen_rtx(a1,a2,...) (gen_rtx)(a1,a2 __VA_OPT__(,DWALL(__VA_ARGS__)))
#define gen_rtvec(a1,...) (gen_rtvec)(a1 __VA_OPT__(,DWALL(__VA_ARGS__)))
#define gen_rtx_combine(a1,a2,...) (gen_rtx_combine)(a1,a2 __VA_OPT__(,DWALL(__VA_ARGS__)))
#define build(a1,a2,...) (build)(a1,a2 __VA_OPT__(,DWALL(__VA_ARGS__)))
#define build_nt(a1,...) (build_nt)(a1 __VA_OPT__(,DWALL(__VA_ARGS__)))
#define build_parse_node(a1,...) (build_parse_node)(a1 __VA_OPT__(,DWALL(__VA_ARGS__)))
#define error(a1,...) (error)(a1 __VA_OPT__(,DWALL(__VA_ARGS__)))
#define warning(a1,...) (warning)(a1 __VA_OPT__(,DWALL(__VA_ARGS__)))
#define pedwarn(a1,...) (pedwarn)(a1 __VA_OPT__(,DWALL(__VA_ARGS__)))
#define fatal(a1,...) (fatal)(a1 __VA_OPT__(,DWALL(__VA_ARGS__)))
#define sorry(a1,...) (sorry)(a1 __VA_OPT__(,DWALL(__VA_ARGS__)))
#define really_sorry(a1,...) (really_sorry)(a1 __VA_OPT__(,DWALL(__VA_ARGS__)))
#define notice(a1,...) (notice)(a1 __VA_OPT__(,DWALL(__VA_ARGS__)))
#define fatal_perror(a1,...) (fatal_perror)(a1 __VA_OPT__(,DWALL(__VA_ARGS__)))
#define yyerror(a1,...) (yyerror)(a1 __VA_OPT__(,DWALL(__VA_ARGS__)))
#define fnotice(a1,a2,...) (fnotice)(a1,a2 __VA_OPT__(,DWALL(__VA_ARGS__)))
#define asm_fprintf(a1,a2,...) (asm_fprintf)(a1,a2 __VA_OPT__(,DWALL(__VA_ARGS__)))
#define checkit(a1,...) (checkit)(a1 __VA_OPT__(,DWALL(__VA_ARGS__)))
#define error_with_file_and_line(a1,a2,a3,...) (error_with_file_and_line)(a1,a2,a3 __VA_OPT__(,DWALL(__VA_ARGS__)))
#define error_with_decl(a1,a2,...) (error_with_decl)(a1,a2 __VA_OPT__(,DWALL(__VA_ARGS__)))
#define error_for_asm(a1,a2,...) (error_for_asm)(a1,a2 __VA_OPT__(,DWALL(__VA_ARGS__)))
#define warning_with_file_and_line(a1,a2,a3,...) (warning_with_file_and_line)(a1,a2,a3 __VA_OPT__(,DWALL(__VA_ARGS__)))
#define warning_with_decl(a1,a2,...) (warning_with_decl)(a1,a2 __VA_OPT__(,DWALL(__VA_ARGS__)))
#define warning_for_asm(a1,a2,...) (warning_for_asm)(a1,a2 __VA_OPT__(,DWALL(__VA_ARGS__)))
#define pedwarn_with_decl(a1,a2,...) (pedwarn_with_decl)(a1,a2 __VA_OPT__(,DWALL(__VA_ARGS__)))
#define error_with_line(a1,a2,...) (error_with_line)(a1,a2 __VA_OPT__(,DWALL(__VA_ARGS__)))
#define warning_with_line(a1,a2,...) (warning_with_line)(a1,a2 __VA_OPT__(,DWALL(__VA_ARGS__)))
#define pedwarn_with_line(a1,a2,...) (pedwarn_with_line)(a1,a2 __VA_OPT__(,DWALL(__VA_ARGS__)))
#define pedwarn_with_file_and_line(a1,a2,a3,a4,...) (pedwarn_with_file_and_line)(a1,a2,a3,a4 __VA_OPT__(,DWALL(__VA_ARGS__)))
#define emit_library_call(a1,a2,a3,...) (emit_library_call)(a1,a2,a3 __VA_OPT__(,DWALL(__VA_ARGS__)))
#define emit_library_call_value(a1,a2,a3,a4,a5,...) (emit_library_call_value)(a1,a2,a3,a4,a5 __VA_OPT__(,DWALL(__VA_ARGS__)))
#endif
