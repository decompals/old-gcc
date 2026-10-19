#!/bin/bash
# The 2.91.66 (egcs 1.1.2) and 2.95.2 half of build.sh: their source has the compiler in gcc/ and libiberty/
# beside it, and a configure per directory. Called by build.sh, same arguments.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"

VERSION="$1"
OLDGCC="$(cd "$(dirname "$0")/.." && pwd)"
PATCHES="$OLDGCC/patches"
ARCH="${BUILD_ARCH:-$(uname -m)}"
OUTDIR="$OLDGCC/build-gcc-$VERSION-psx"
[ "$ARCH" = "$(uname -m)" ] || OUTDIR="$OUTDIR-$ARCH"
WORKDIR="${WORKDIR:-$(mktemp -d)}"
[ -n "$KEEP" ] || trap 'rm -rf "$WORKDIR"' EXIT

export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
unset CC CXX
# BUILD_ARCH=x86_64 makes an Intel build from an arm64 shell (the Command Line Tools' xcrun is arm64 only, so
# "arch -x86_64 bash ..." can't find a compiler); the Intel tools it builds run through Rosetta
if [ "$ARCH" != "$(uname -m)" ]; then export CC="cc -arch $ARCH" CFLAGS_ARCH="-arch $ARCH"; fi

cd "$WORKDIR"
mkdir "gcc-$VERSION"
case "$VERSION" in
    2.91.66)
        curl -fL "https://gcc.gnu.org/pub/gcc/old-releases/egcs/egcs-1.1.2.tar.bz2" | tar xj --strip-components=1 -C "gcc-$VERSION"
        OBSTACK=gcc/obstack.h ;;
    2.95.2)
        curl -fL "https://mirrors.kernel.org/gnu/gcc/gcc-2.95.2.tar.gz" | tar xz --strip-components=1 -C "gcc-$VERSION"
        OBSTACK=include/obstack.h ;;
esac
cd "gcc-$VERSION"
chmod -R u+w .

sed -i '' 's/include <varargs\.h>/include <stdarg\.h>/g' */*.c
patch -u -p1 "$OBSTACK" -i "$PATCHES/obstack-$VERSION.h.patch"
patch -u -p1 gcc/config/mips/mips.h -i "$PATCHES/mips.patch"
patch -su -p1 < "$PATCHES/psx-2.91.patch"
touch gcc/insn-config.h

# Apple's arm64 variadic ABI (see arm64-varargs.h): the header widens the arguments of every variadic call, so the
# names in prototypes and definitions that mention "..." go in parentheses first, to keep the macros off them
if [ "$ARCH" = arm64 ]; then
    names="$(sed -n 's/^#define \([a-z_]*\)(a1.*/\1/p' "$HERE/arm64-varargs.h" | paste -sd'|' -)"
    sed -E -i '' "s/(^|[^A-Za-z0-9_(])($names)([[:space:]]+P?V?PROTO)/\1(\2)\3/" gcc/*.c gcc/*.h
    touch gcc/cstamp-h.in   # depends on acconfig.h, which sed just rewrote: don't let make try to regenerate it
    WIDEN="-include $HERE/arm64-varargs.h"
    # GEN_FCN (icode) (a, b) calls the generated gen_* functions through a pointer typed rtx (*)(rtx, ...). A call
    # through a variadic type puts its arguments on the stack, the gen_* functions read registers: unprototyped
    # pointer types (as genoutput.c already writes the table) call them the ordinary way
    sed -i '' -e 's/PROTO *((rtx, \.\.\.))/()/' -e 's/(rtx (\*) (rtx, \.\.\.)/(rtx (*) ()/' gcc/expr.h gcc/expr.c
fi

# modern config.guess/config.sub (Apple Silicon), psx* added to the OS list; same as build.sh
for d in . gcc libiberty; do
    [ -f "$d/config.guess" ] && [ -f "$d/config.sub" ] || continue
    chmod +w "$d/config.guess" "$d/config.sub"
    curl -fsL "https://raw.githubusercontent.com/gcc-mirror/gcc/74af13c174714dd3b9f1ded4b39955f003c16361/config.guess" -o "$d/config.guess"
    curl -fsL "https://raw.githubusercontent.com/gcc-mirror/gcc/6fad101f3063d722e3348d07dc93cf737f8709e4/config.sub"   -o "$d/config.sub"
    chmod +x "$d/config.guess" "$d/config.sub"
    sed -i '' 's/| hiux\* | abug | nacl\*/| psx* \\\
'"$(printf '\t')"'     | hiux* | abug | nacl*/' "$d/config.sub"
done

cp "$PATCHES/xm-darwin.h" gcc/config/
# A double constant came out with garbage in one .word: the sources copy a CONST_DOUBLE's two 32-bit halves as one
# block, which the 8-byte slots of this LP64 host break (see const-double-fix.py). The 32-bit HOST_WIDE_INT of
# xm-darwin.h stays: the old sources assume it (a 64-bit one changes the code, e.g. li $18,-65536 becomes
# li $18,4294901760), as the official i386 builds have it.
python3 "$HERE/const-double-fix.py" gcc
chmod +w gcc/configure
awk '/^\t\*\)$/ { buf=$0; next }
     buf != "" { if (!done && /echo.*Configuration.*not supported/) {
       print "\t*-apple-darwin*)"; print "\t\txm_file=xm-darwin.h"
       print "\t\tfixincludes=Makefile.in"; print "\t\t;;"; done=1 }
       print buf; buf="" } { print }' gcc/configure > gcc/configure.tmp
mv gcc/configure.tmp gcc/configure
chmod +x gcc/configure

HOST="$(./config.guess | sed "s/^[a-z0-9_]*-/$ARCH-/")"
export CFLAGS="-std=gnu89 -w -Wno-int-conversion -Wno-implicit-function-declaration -Wno-return-mismatch ${CFLAGS_ARCH:-}"
GCC_CFLAGS="$CFLAGS ${WIDEN:-}"
for d in libiberty gcc; do
    (cd $d && ./configure \
        --target=mips-sony-psx \
        --prefix=/opt/cross \
        --with-endian-little \
        --with-gnu-as \
        --host="$HOST" \
        --build="$HOST")
done

# libiberty's own sys_nerr and sys_errlist declarations clash with the SDK's const ones
sed -i '' -e 's/^extern int sys_nerr;/extern const int sys_nerr;/' \
    -e 's/^extern char \*sys_errlist\[\];/extern const char *const sys_errlist[];/' libiberty/strerror.c

nice -n 10 make -C libiberty --jobs "$(sysctl -n hw.ncpu)" CC="${CC:-gcc}" CFLAGS="$CFLAGS"
nice -n 10 make -C gcc --jobs "$(sysctl -n hw.ncpu)" cpp cc1 xgcc CC="${CC:-gcc}" CFLAGS="$GCC_CFLAGS"

cd gcc
./cc1 -version </dev/null 2>&1 | grep -- -msoft-float
./cc1 -version </dev/null 2>&1 | grep -- -msplit-addresses
./cc1 -version </dev/null 2>&1 | grep -- -mgpopt

mkdir -p "$OUTDIR"
cp cpp cc1 xgcc "$OUTDIR/"
mv "$OUTDIR/xgcc" "$OUTDIR/gcc"
echo "Done: $OUTDIR/ ($(file "$OUTDIR/cc1" | cut -d: -f2 | xargs))"
