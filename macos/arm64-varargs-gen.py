#!/usr/bin/env python3
"""Writes arm64-varargs.h (see its comment). TABLE: function name -> number of fixed arguments before the "...".
Add a name when a version has another variadic function whose callers pass ints where it reads pointers
(find them with: grep -n 'VPROTO\|va_dcl\|\.\.\.)' gcc/*.c gcc/*.h). psx-gcc-macos-egcs.sh reads the names from
the header's #define lines to parenthesise them in prototypes and definitions."""
import pathlib
TABLE = {'gen_rtx': 2, 'gen_rtvec': 1, 'gen_rtx_combine': 2, 'build': 2, 'build_nt': 1, 'build_parse_node': 1, 'error': 1, 'warning': 1, 'pedwarn': 1, 'fatal': 1, 'sorry': 1, 'really_sorry': 1, 'notice': 1, 'fatal_perror': 1, 'yyerror': 1, 'fnotice': 2, 'asm_fprintf': 2, 'checkit': 1, 'error_with_file_and_line': 3, 'error_with_decl': 2, 'error_for_asm': 2, 'warning_with_file_and_line': 3, 'warning_with_decl': 2, 'warning_for_asm': 2, 'pedwarn_with_decl': 2, 'error_with_line': 2, 'warning_with_line': 2, 'pedwarn_with_line': 2, 'pedwarn_with_file_and_line': 4, 'emit_library_call': 3, 'emit_library_call_value': 5}
N = 16
out = '/* Widening of variadic arguments, for building the old GCCs (2.91.66, 2.95.2) natively on Apple\'s arm64.\n   Force-included with -include when the compiler itself is built; written by arm64-varargs-gen.py, whose table\n   says how many fixed arguments each variadic function has.\n\n   Apple\'s arm64 ABI gives every variadic argument its own 8-byte stack slot, and an int written there leaves the\n   upper 4 bytes undefined. These sources pass ints (a literal 0, say) through "..." where the callee\'s va_arg\n   reads a pointer or a 64-bit HOST_WIDE_INT, which x86_64 tolerates by accident. Every argument after the fixed\n   ones goes through DW: doubles and floats are left alone (a float is promoted anyway), anything else a long (a pointer\'s bits are unchanged, an int is\n   sign-extended, so 0 read as a pointer is NULL).\n\n   Prototypes and definitions that mention "..." must not be macro-expanded: psx-gcc-macos-egcs.sh writes their\n   names in parentheses, (gen_rtx), first. A call through a parenthesised name isn\'t expanded either. */\n#ifndef ARM64_VARARGS_H\n#define ARM64_VARARGS_H\n#define DW(x) _Generic((x), double: (x), float: (x), default: (long)(x))\n'
for i in range(1, N + 1):
    args = ",".join("x%d" % k for k in range(1, i + 1))
    out += "#define DW_%d(%s) %s\n" % (i, args, ",".join("DW(x%d)" % k for k in range(1, i + 1)))
out += "#define DW_PICK(%s,NAME,...) NAME\n" % ",".join("_%d" % k for k in range(1, N + 1))
out += "#define DWALL(...) DW_PICK(__VA_ARGS__,%s,)(__VA_ARGS__)\n" % ",".join("DW_%d" % k for k in range(N, 0, -1))
for name, k in TABLE.items():
    fixed = ",".join("a%d" % i for i in range(1, k + 1))
    out += "#define %s(%s,...) (%s)(%s __VA_OPT__(,DWALL(__VA_ARGS__)))\n" % (name, fixed, name, fixed)
out += "#endif\n"
pathlib.Path(__file__).with_name("arm64-varargs.h").write_text(out)
