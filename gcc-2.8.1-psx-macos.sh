#!/bin/bash
# Build gcc-2.8.1-psx natively on macOS (x86_64 and aarch64).
# Produces a Mach-O cc1 binary targeting mips-sony-psx.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PATCHES="$SCRIPT_DIR/patches"
OUTDIR="$SCRIPT_DIR/build-gcc-2.8.1-psx"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

echo "Building gcc-2.8.1-psx for macOS in $WORKDIR"

# Ensure we use the system compiler, not any cross-compiler wrappers that
# may be in PATH (e.g. from a nix shell).
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
unset CC CXX

cd "$WORKDIR"
curl -fL "https://mirrors.kernel.org/gnu/gcc/gcc-2.8.1.tar.gz" | tar xz
cd gcc-2.8.1

# Apply the same patches as the Linux Dockerfile
python3 -c "
import glob, os, stat
for f in glob.glob('*.c'):
    s = open(f).read()
    s2 = s.replace('include <varargs.h>', 'include <stdarg.h>')
    if s2 != s:
        os.chmod(f, stat.S_IRUSR | stat.S_IWUSR | stat.S_IRGRP | stat.S_IROTH)
        open(f, 'w').write(s2)
"
patch -u -p1 obstack.h          -i "$PATCHES/obstack-2.8.1.h.patch"
patch -u -p1 config/mips/mips.h -i "$PATCHES/mips.patch"
patch -su -p1                   <  "$PATCHES/psx.patch"

# macOS: replace config.guess/config.sub with modern versions that know
# about aarch64-apple-darwin, then add psx* to the OS list.
chmod +w config.guess config.sub
curl -fsL "https://raw.githubusercontent.com/gcc-mirror/gcc/master/config.guess" -o config.guess
curl -fsL "https://raw.githubusercontent.com/gcc-mirror/gcc/master/config.sub"   -o config.sub
chmod +x config.guess config.sub
python3 -c "
s = open('config.sub').read()
s = s.replace('| hiux* | abug | nacl*', '| psx* \\\\\n\t     | hiux* | abug | nacl*', 1)
open('config.sub', 'w').write(s)
"

# Add xm-darwin.h and teach configure about *-apple-darwin* hosts.
cp "$PATCHES/xm-darwin.h" config/
chmod +w configure
python3 -c "
s = open('configure').read()
insert = '\t*-apple-darwin*)\n\t\txm_file=xm-darwin.h\n\t\tfixincludes=Makefile.in\n\t\t;;\n'
s = s.replace('\t*)\n\t\techo \"Configuration \$machine not supported\"',
              insert + '\t*)\n\t\techo \"Configuration \$machine not supported\"', 1)
open('configure', 'w').write(s)
"

# Explicitly pass --host/--build so configure uses a single-arg config.sub
# call (which modern config.sub accepts), rather than its multi-arg form.
# Export CFLAGS so configure's compiler test (main(){return(0);}) passes under
# modern clang, which rejects implicit int without -std=gnu89.
DARWIN_HOST="$(uname -m)-apple-darwin"
export CFLAGS="-std=gnu89 -w -Wno-int-conversion -Wno-implicit-function-declaration -Wno-return-mismatch"
./configure \
    --target=mips-sony-psx \
    --host="$DARWIN_HOST" \
    --build="$DARWIN_HOST" \
    --prefix=/opt/cross \
    --with-endian-little \
    --with-gnu-as \
    --disable-gprof \
    --disable-gdb \
    --disable-werror

# insn-config.h is generated during the build but referenced early; touch
# it to prevent spurious missing-file errors on some make versions.
touch insn-config.h

make --jobs "$(sysctl -n hw.ncpu)" cc1 \
    CFLAGS="-std=gnu89 -w -Wno-int-conversion -Wno-implicit-function-declaration -Wno-return-mismatch"

# Run the same tests as the Dockerfile
./cc1 -quiet -O2 "$SCRIPT_DIR/tests/little_endian.c" -o little_endian.s
grep -E 'lbu\s\$2,0\(\$4\)' little_endian.s
./cc1 -quiet -O2 "$SCRIPT_DIR/tests/section_attribute.c" -o /dev/null
./cc1 -version </dev/null 2>&1 | grep -- -msoft-float
./cc1 -version </dev/null 2>&1 | grep -- -msplit-addresses
./cc1 -version </dev/null 2>&1 | grep -- -mgpopt

mkdir -p "$OUTDIR"
cp cc1 "$OUTDIR/cc1"
echo "Done — $OUTDIR/cc1 ($(file "$OUTDIR/cc1" | cut -d: -f2 | xargs))"
