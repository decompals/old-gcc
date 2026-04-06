#!/bin/bash
# Build gcc-2.7.2-psx natively on macOS (x86_64 and aarch64).
# Produces Mach-O cc1 and companion binaries targeting mips-sony-psx.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PATCHES="$SCRIPT_DIR/patches"
OUTDIR="$SCRIPT_DIR/build-gcc-2.7.2-psx"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

echo "Building gcc-2.7.2-psx for macOS in $WORKDIR"

# Ensure we use the system compiler and tools, not any cross-compiler wrappers
# that may be in PATH (e.g. from a nix shell).
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
unset CC CXX

cd "$WORKDIR"
curl -fL "https://ftp.gnu.org/old-gnu/gcc/gcc-2.7.2.tar.gz" | tar xz
cd gcc-2.7.2

# Apply the same patches as the Linux Dockerfile
# Replace varargs.h with stdarg.h; some files are read-only from the tarball.
grep -rl 'include <varargs\.h>' *.c | xargs chmod u+w
sed -i '' 's/include <varargs\.h>/include <stdarg\.h>/g' *.c
# macOS SDKs declare sys_nerr as 'const int'; fix the conflicting declarations.
for f in gcc.c cp/g++.c; do
    [ -f "$f" ] && sed -i '' 's/^extern int sys_nerr;/extern const int sys_nerr;/' "$f"
done

patch -u -p1 obstack.h      -i "$PATCHES/obstack-2.7.2.h.patch"
patch -u -p1 configure      -i "$PATCHES/configure.patch"
patch -u -p1 config/mips/mips.h -i "$PATCHES/mipsel-2.7.patch"
patch -su -p1               <  "$PATCHES/psx-2.5.7.patch"

# macOS: replace config.guess/config.sub with modern versions that know
# about aarch64-apple-darwin, then add psx* to the OS list.
# Pinned to specific commits for reproducibility.
chmod +w config.guess config.sub
curl -fsL "https://raw.githubusercontent.com/gcc-mirror/gcc/74af13c174714dd3b9f1ded4b39955f003c16361/config.guess" -o config.guess
curl -fsL "https://raw.githubusercontent.com/gcc-mirror/gcc/6fad101f3063d722e3348d07dc93cf737f8709e4/config.sub"   -o config.sub
chmod +x config.guess config.sub
sed -i '' 's/| hiux\* | abug | nacl\*/| psx* \\\
'"$(printf '\t')"'     | hiux* | abug | nacl*/' config.sub

# Add xm-darwin.h and teach configure about *-apple-darwin* hosts.
cp "$PATCHES/xm-darwin.h" config/
chmod +w configure
awk '/^\t\*\)$/ { buf=$0; next }
     buf != "" { if (!done && /echo.*Configuration.*not supported/) {
       print "\t*-apple-darwin*)"; print "\t\txm_file=xm-darwin.h"
       print "\t\tfixincludes=Makefile.in"; print "\t\t;;"; done=1 }
       print buf; buf="" } { print }' configure > configure.tmp
mv configure.tmp configure
chmod +x configure

./configure \
    --target=mips-sony-psx \
    --prefix=/opt/cross \
    --with-endian-little \
    --with-gnu-as \
    --disable-gprof \
    --disable-gdb \
    --disable-werror

make --jobs "$(sysctl -n hw.ncpu)" cpp cc1 xgcc cc1plus g++ \
    CFLAGS="-std=gnu89 -w -Wno-int-conversion -Wno-implicit-function-declaration -Wno-return-mismatch"

# Run the same tests as the Dockerfile
./cc1 -quiet -O2 "$SCRIPT_DIR/tests/little_endian.c" -o little_endian.s
grep -E 'lbu\s\$2,0\(\$4\)' little_endian.s
./cc1 -quiet -O2 "$SCRIPT_DIR/tests/section_attribute.c" -o /dev/null
./cc1 -quiet -help </dev/null 2>&1 | grep -- -msoft-float

mkdir -p "$OUTDIR"
cp cpp cc1 xgcc cc1plus g++ "$OUTDIR/"
mv "$OUTDIR/xgcc" "$OUTDIR/gcc"
echo "Done — $OUTDIR/ ($(file "$OUTDIR/cc1" | cut -d: -f2 | xargs))"
