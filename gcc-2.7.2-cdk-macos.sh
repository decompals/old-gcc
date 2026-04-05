#!/bin/bash
# Build gcc-2.7.2-cdk natively on macOS (x86_64 and aarch64).
# Produces a Mach-O cc1 binary targeting mips-sony-psx.
#
# Requires: byacc  (install via Homebrew: brew install byacc)
set -e

if ! command -v byacc >/dev/null 2>&1; then
    echo "Error: byacc is required. Install it with: brew install byacc" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PATCHES="$SCRIPT_DIR/patches"
OUTDIR="$SCRIPT_DIR/build-gcc-2.7.2-cdk"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

echo "Building gcc-2.7.2-cdk for macOS in $WORKDIR"

cd "$WORKDIR"
curl -fL "https://github.com/decompals/old-gcc/releases/download/0.14/b18.tar.gz" | tar xz
cd cdk-gcc-b18

# Apply the same patches as the Linux Dockerfile
patch -u -p1 Makefile.in        -i "$PATCHES/Makefile-2.7.2-cdk.in.patch"
patch -u -p1 obstack.h          -i "$PATCHES/obstack-2.7.2-cdk.h.patch"
patch -u -p1 config/mips/mips.h -i "$PATCHES/mipsel-2.7-cdk.patch"
patch -su -p1                   <  "$PATCHES/psx-2.7.2-cdk.patch"

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

./configure \
    --target=mips-sony-psx \
    --prefix=/opt/cross \
    --with-endian-little \
    --with-gnu-as \
    --disable-gprof \
    --disable-gdb \
    --disable-werror

# Compile the __eprintf stub — this symbol was removed from macOS SDKs
# after 10.14 but is referenced by the exception-handling code.
cc -std=gnu89 -c "$PATCHES/eprintf-darwin.c" -o eprintf-darwin.o

# Build single-threaded: parallel yacc invocations race on y.tab.h,
# causing bi-parser.h to be generated with the wrong grammar.
make cc1 \
    CFLAGS="-std=gnu89 -w -Wno-int-conversion -Wno-implicit-function-declaration" \
    LDFLAGS="eprintf-darwin.o"

# Run the same tests as the Dockerfile
./cc1 -quiet -O2 "$SCRIPT_DIR/tests/little_endian.c" -o little_endian.s
grep -E 'lbu\s\$2,0\(\$4\)' little_endian.s
./cc1 -quiet -O2 "$SCRIPT_DIR/tests/section_attribute.c" -o /dev/null

mkdir -p "$OUTDIR"
cp cc1 "$OUTDIR/cc1"
echo "Done — $OUTDIR/cc1 ($(file "$OUTDIR/cc1" | cut -d: -f2 | xargs))"
