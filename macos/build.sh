#!/bin/bash
# Build an old PSY-Q GCC (2.6.0, 2.6.3 or 2.8.0; 2.91.66 and 2.95.2 are in build-egcs.sh) natively on macOS, from decompals/old-gcc's patches.
# Usage: gcc-<2.6.0|2.6.3|2.8.0|2.91.66|2.95.2>-psx-macos.sh (a wrapper in the repository root)
# For an Intel build: BUILD_ARCH=x86_64 bash build.sh ...
# Output: ./build-gcc-<version>-psx-macos-<arch>/{gcc,cc1,cpp}
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"

case "$1" in 2.91.66|2.95.2) exec bash "$HERE/build-egcs.sh" "$@" ;; esac

VERSION="$1"
OLDGCC="$(cd "$(dirname "$0")/.." && pwd)"
PATCHES="$OLDGCC/patches"
ARCH="${BUILD_ARCH:-$(uname -m)}"
OUTDIR="$OLDGCC/build-gcc-$VERSION-psx"
[ "$ARCH" = "$(uname -m)" ] || OUTDIR="$OUTDIR-$ARCH"
WORKDIR="${WORKDIR:-$(mktemp -d)}"
[ -n "$KEEP" ] || trap 'rm -rf "$WORKDIR"' EXIT

case "$VERSION" in
    2.6.3) URL="https://mirrors.slackware.com/slackware/slackware-2.2.0/source/d/gcc/gcc-2.6.3.tar.gz" ;;
    2.6.0) URL="http://www.nic.funet.fi/index/gnu/funet/historical-funet-gnu-area-from-early-1990s/gcc-$VERSION.tar.gz" ;;
    2.8.0) URL="https://mirrors.kernel.org/gnu/gcc/gcc-2.8.0.tar.gz" ;;
    # 2.5.7 isn't here: it is written in K&R varargs (va_alist, va_dcl) throughout, which Apple's arm64 calling
    # convention can't run; try it as an Intel build (BUILD_ARCH=x86_64) with its patches from gcc-2.5.7-psx.Dockerfile
    *) echo "unsupported version $VERSION"; exit 1 ;;
esac

export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
unset CC CXX
# BUILD_ARCH=x86_64 makes an Intel build from an arm64 shell (the Command Line Tools' xcrun is arm64 only, so
# "arch -x86_64 bash ..." can't find a compiler); the Intel tools it builds run through Rosetta
if [ "$ARCH" != "$(uname -m)" ]; then export CC="cc -arch $ARCH" CFLAGS_ARCH="-arch $ARCH"; fi

cd "$WORKDIR"
curl -fL "$URL" | tar xz
cd gcc-$VERSION
chmod -R u+w .

sed -i '' 's/include <varargs\.h>/include <stdarg\.h>/g' *.c

# the patches the Dockerfiles apply, per version (not the g++ ones: only cc1, cpp and the gcc driver are built)
case "$VERSION" in
    2.6.3)
        patch -u -p1 obstack.h -i "$PATCHES/obstack-2.7.2.h.patch"
 ;;
    2.6.0)
        patch -u -p1 obstack.h -i "$PATCHES/obstack-2.7.2.h.patch"
        patch -u -p1 collect2.c -i "$PATCHES/collect2-2.6.0.c.patch"
        patch -u -p1 cccp.c -i "$PATCHES/cccp-2.6.0.c.patch"
        patch -u -p1 gcc.c -i "$PATCHES/gcc-2.6.0.c.patch"
        patch -u -p1 config/mips/mips.h -i "$PATCHES/mipsel-2.6.patch" ;;
    2.8.0)
        patch -u -p1 obstack.h -i "$PATCHES/obstack-2.8.0.h.patch"
        patch -u -p1 config/mips/mips.h -i "$PATCHES/mips.patch" ;;
esac
# sdbout-2.6.x.c.patch, as sed: Apple's patch rejects its odd hunk header
sed -i '' -e 's/ && !defined(WINNT)$//' -e 's/^#if defined(USG) && !defined(MIPS) && !defined (hpux).*$/& \&\& !defined(_WIN32) \&\& !defined(__linux__)/' sdbout.c
case "$VERSION" in
    2.8.*) patch -su -p1 < "$PATCHES/psx.patch" ;;
    *) patch -su -p1 < "$PATCHES/psx-2.5.7.patch" ;;
esac
if [ "$VERSION" = 2.6.3 ]; then touch -c cp/parse.y cp/parse.h cp/parse.c; fi
touch insn-config.h

# (after the patches, whose context has the originals) macOS declares sys_nerr as const int and sys_errlist as const char *const []
sed -i '' -e 's/^extern int sys_nerr;/extern const int sys_nerr;/' \
    -e 's/^extern char \*sys_errlist\[\];/extern const char *const sys_errlist[];/' gcc.c

# modern config.guess/config.sub (Apple Silicon), psx* added to the OS list; same as gcc-2.7.2-psx-macos.sh
chmod +w config.guess config.sub
curl -fsL "https://raw.githubusercontent.com/gcc-mirror/gcc/74af13c174714dd3b9f1ded4b39955f003c16361/config.guess" -o config.guess
curl -fsL "https://raw.githubusercontent.com/gcc-mirror/gcc/6fad101f3063d722e3348d07dc93cf737f8709e4/config.sub"   -o config.sub
chmod +x config.guess config.sub
sed -i '' 's/| hiux\* | abug | nacl\*/| psx* \\\
'"$(printf '\t')"'     | hiux* | abug | nacl*/' config.sub

cp "$PATCHES/xm-darwin.h" config/
# A double constant came out with garbage in one .word: the sources copy a CONST_DOUBLE's two 32-bit halves as one
# block, which the 8-byte slots of this LP64 host break (see const-double-fix.py). The 32-bit HOST_WIDE_INT of
# xm-darwin.h stays: the old sources assume it (a 64-bit one changes the code, e.g. li $18,-65536 becomes
# li $18,4294901760), as the official i386 builds have it.
python3 "$HERE/const-double-fix.py" .
chmod +w configure
awk '/^\t\*\)$/ { buf=$0; next }
     buf != "" { if (!done && /echo.*Configuration.*not supported/) {
       print "\t*-apple-darwin*)"; print "\t\txm_file=xm-darwin.h"
       print "\t\tfixincludes=Makefile.in"; print "\t\t;;"; done=1 }
       print buf; buf="" } { print }' configure > configure.tmp
mv configure.tmp configure
chmod +x configure

# configure's own compiler test (main(){return(0);}) needs these under modern clang
export CFLAGS="-std=gnu89 -w -Wno-int-conversion -Wno-implicit-function-declaration -Wno-return-mismatch ${CFLAGS_ARCH:-}"
./configure \
    --target=mips-sony-psx \
    --prefix=/opt/cross \
    --with-endian-little \
    --with-gnu-as \
    --host="$(./config.guess | sed "s/^[a-z0-9_]*-/$ARCH-/")" \
    --build="$(./config.guess | sed "s/^[a-z0-9_]*-/$ARCH-/")"

# 2.5.7 and 2.6.0's configure take the host for a MIPS box and add its cc flags (-Olimit 3000), which clang rejects
sed -i '' -e 's/-Wf,-XNg1500,-XNh2000//' -e 's/-Olimit 3000//' Makefile

nice -n 10 make --jobs "$(sysctl -n hw.ncpu)" cpp cc1 xgcc CC="${CC:-cc}" \
    CFLAGS="-std=gnu89 -w -Wno-int-conversion -Wno-implicit-function-declaration -Wno-return-mismatch -DHAVE_STRERROR ${CFLAGS_ARCH:-}"

./cc1 -quiet -O2 "$OLDGCC/tests/little_endian.c" -o little_endian.s
grep -E 'lbu\s\$2,0\(\$4\)' little_endian.s
./cc1 -version </dev/null 2>&1 | grep -- -msoft-float

mkdir -p "$OUTDIR"
cp cpp cc1 xgcc "$OUTDIR/"
mv "$OUTDIR/xgcc" "$OUTDIR/gcc"
echo "Done: $OUTDIR/ ($(file "$OUTDIR/cc1" | cut -d: -f2 | xargs))"
