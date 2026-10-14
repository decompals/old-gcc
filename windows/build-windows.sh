#!/bin/bash
# Builds Windows (i686 MinGW-w64) cc1.exe and cpp.exe in a patched GCC source tree, the current
# directory. Used by the gcc-*-windows.Dockerfiles; the tree is patched exactly as for Linux.
#
#   build-windows.sh cross     GCC 2.8.x knows the i686-pc-mingw32 host: a normal cross-host build
#                              (the generator programs are built for Linux by HOST_CC).
#   build-windows.sh twopass   GCC 2.7.x predates MinGW: build for Linux first (generator programs
#                              and their output), then rebuild only cc1's and cccp's own objects
#                              with MinGW and link them for Windows.
#
# winshim.c supplies the BSD functions old GCC expects (index, bcopy...) and puts stdin/stdout in
# binary mode, so cc1.exe reads and writes Unix line endings exactly like the Linux cc1.
set -euo pipefail
MODE=$1
SHIM=$(dirname "$(readlink -f "$0")")/winshim.c
MINGW=i686-w64-mingw32-gcc

i686-w64-mingw32-gcc -O2 -c "$SHIM" -o winshim.o

# make cc1 and cccp with MinGW, keeping the Linux generator programs (gen*, bi-*) as they are
windows_make() {
    local libs keep=""
    libs=$(sed -n 's/^LIBS *= *//p' Makefile)
    for g in gen* bi-*; do
        if [ -x "$g" ] && [ ! -d "$g" ]; then case $g in *.*) ;; *) keep="$keep -o $g" ;; esac; fi
    done
    make --jobs "$(nproc)" $keep cc1 cccp CC=$MINGW HOST_CC="gcc -m32" CFLAGS="-std=gnu89 -O2" \
        HOST_CFLAGS="-std=gnu89 -m32" LIBS="$libs winshim.o"
}

chmod +x configure config.sub config.guess 2> /dev/null || true

case $MODE in
cross)
    CC="gcc -std=gnu89 -m32" ./configure \
        --target=mips-sony-psx \
        --prefix=/opt/cross \
        --with-endian-little \
        --with-gnu-as \
        --disable-gprof \
        --disable-gdb \
        --disable-werror \
        --host=i686-pc-mingw32 \
        --build=i386-pc-linux
    # configure checked the build machine's (Linux) headers and functions; MinGW lacks these
    for d in HAVE_SYS_RESOURCE_H HAVE_SYS_TIMES_H HAVE_BCMP HAVE_BCOPY HAVE_BZERO HAVE_GETRLIMIT \
             HAVE_SETRLIMIT HAVE_INDEX HAVE_RINDEX HAVE_KILL HAVE_SYSCONF; do
        sed -i "s/^#define $d 1/\/* #undef $d *\//" auto-config.h
    done
    touch insn-config.h
    windows_make
    ;;
twopass)
    CC="gcc -std=gnu89 -m32" ./configure \
        --target=mips-sony-psx \
        --prefix=/opt/cross \
        --with-endian-little \
        --with-gnu-as \
        --disable-gprof \
        --disable-gdb \
        --disable-werror \
        --host=i386-pc-linux \
        --build=i386-pc-linux
    # The parsers first, one at a time: both grammars go through yacc's y.tab.c (sources such as
    # the CDK's ship without them generated), which a parallel build would race on.
    make c-parse.c cexp.c
    make --jobs "$(nproc)" cc1 cccp CC="gcc -std=gnu89 -m32" CFLAGS="-std=gnu89 -m32 -static" | tee linux.log
    # the objects cc1 and cccp are linked from, from their Linux link commands
    rm -f $(grep -E -- "-o (cc1|cccp)( |$)" linux.log | tr ' ' '\n' | grep '\.o$' | sort -u) cc1 cccp
    windows_make
    ;;
*)
    echo "usage: build-windows.sh cross|twopass" >&2
    exit 2
    ;;
esac
mv cccp.exe cpp.exe
