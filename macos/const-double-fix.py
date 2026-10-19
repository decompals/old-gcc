#!/usr/bin/env python3
"""Usage: const-double-fix.py <the compiler's source folder, the one with real.h>

real.h says "use &CONST_DOUBLE_LOW(r) as the address of an array of ints", and the sources bcopy/bcmp a whole double
to and from there. On a 64-bit host each slot of an rtx is 8 bytes, so the two 32-bit halves of a CONST_DOUBLE (slots 2
and 3) are not contiguous: the copy took padding for the high half, and a double constant came out with garbage in
one .word (on one run in a few). The generic code (gen_rtx, copy_rtx, read_rtx) fills slots 2 and 3 by format, so
the slots stay as they are and the copies are rewritten to move the halves one by one.

The same real.h has a second problem: its host-format REAL_VALUE_TO_TARGET_SINGLE and _DOUBLE read the float or the
two halves of the double through a `long *`, which is 8 bytes on this host: `float k = 3.0f;` came out as
`.word 0x4bd60c040400000` and a double repeated its eight bytes in both words (2.6.x use these macros; later versions
convert with their own emulator). They read `unsigned int` now (unsigned, so a negative float is not sign-extended
into the `long` that is printed with %08lx).

Assumes sizeof (REAL_VALUE_TYPE) == 2 * sizeof (HOST_WIDE_INT): a host double and a 32-bit HOST_WIDE_INT."""
import pathlib, re, sys

root = pathlib.Path(sys.argv[1])


def write(f, text, **kw):  # the tarballs' files are read-only
    f.chmod(f.stat().st_mode | 0o200)
    f.write_text(text, **kw)


MACROS = '''
/* arm64 port: the halves of a CONST_DOUBLE live in separate rtunion slots, copy them one by one (const-double-fix.py) */
#define CONST_DOUBLE_TO_BYTES(r, p) \\
  do { ((HOST_WIDE_INT *) (p))[0] = CONST_DOUBLE_LOW (r); ((HOST_WIDE_INT *) (p))[1] = CONST_DOUBLE_HIGH (r); } while (0)
#define CONST_DOUBLE_FROM_BYTES(r, p) \\
  do { CONST_DOUBLE_LOW (r) = ((HOST_WIDE_INT *) (p))[0]; CONST_DOUBLE_HIGH (r) = ((HOST_WIDE_INT *) (p))[1]; } while (0)
#define CONST_DOUBLE_BYTES_EQ(r, p) \\
  (((HOST_WIDE_INT *) (p))[0] == CONST_DOUBLE_LOW (r) && ((HOST_WIDE_INT *) (p))[1] == CONST_DOUBLE_HIGH (r))
'''
real = root / 'real.h'
s = real.read_text()
if 'CONST_DOUBLE_TO_BYTES' not in s:
    s, n = re.subn(r'(#define CONST_DOUBLE_HIGH\(r\) XWINT \(r, 3\)\n)', lambda m: m.group(1) + MACROS, s, count=1)
    assert n == 1, 'CONST_DOUBLE_HIGH not found in real.h'
    write(real, s)

old = real.read_text()
new = re.sub(r'(#define REAL_VALUE_TO_TARGET_(?:SINGLE|DOUBLE)\(IN, OUT\)(?:[^\n]*\\\n)+[^\n]*)',
             lambda m: m.group(1).replace('*(long *) &f', '*(unsigned int *) &f').replace('((long *) &in)', '((unsigned int *) &in)'), old)
if new != old:
    write(real, new)
    print('real.h: host-format REAL_VALUE_TO_TARGET_* read unsigned int')

EXPR = r'((?:[^()]|\((?:[^()]|\([^()]*\))*\))*)'          # an expression with up to two levels of parentheses
TO = re.compile(r'bcopy\s*\(\(char \*\) &CONST_DOUBLE_LOW \(' + EXPR + r'\),\s*(\(char \*\) &[\w.>\-\[\]]+),\s*sizeof [\w.>\-\[\]]+\)')
FROM = re.compile(r'bcopy\s*\((\(char \*\) &[\w.>\-\[\]]+),\s*\(char \*\) &CONST_DOUBLE_LOW \(' + EXPR + r'\),\s*sizeof [\w.>\-\[\]]+\)')
EQ = re.compile(r'! bcmp \(\(char \*\) &CONST_DOUBLE_LOW \(' + EXPR + r'\),\s*(\(char \*\) &[\w.>\-\[\]]+),\s*sizeof [\w.>\-\[\]]+\)')
total = 0
for f in list(root.glob('*.c')) + list(root.glob('*.h')) + list(root.glob('config/mips/*.md')) + list(root.glob('config/mips/*.c')):
    t = f.read_text(errors='surrogateescape')
    u, n1 = TO.subn(r'CONST_DOUBLE_TO_BYTES (\1, \2)', t)
    u, n2 = FROM.subn(r'CONST_DOUBLE_FROM_BYTES (\2, \1)', u)
    u, n3 = EQ.subn(r'CONST_DOUBLE_BYTES_EQ (\1, \2)', u)
    if n1 + n2 + n3:
        write(f, u, errors='surrogateescape')
        print(f'{f.relative_to(root)}: {n1} to, {n2} from, {n3} compares')
        total += n1 + n2 + n3
built = list(root.glob('*.c')) + list(root.glob('*.h')) + list(root.glob('config/mips/*'))   # the MIPS target is all that is built
left = [str(f) for f in built if f.is_file()
        and re.search(r'(?<!&)&\s*CONST_DOUBLE_LOW', f.read_text(errors='ignore').replace('So use &CONST_DOUBLE_LOW(r)', ''))]
if left:
    print('still taking the address of CONST_DOUBLE_LOW in:', *left)
    sys.exit(1)
print(f'{total} copies rewritten')
