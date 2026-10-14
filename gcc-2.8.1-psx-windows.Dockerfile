FROM ubuntu:focal AS build
ENV DEBIAN_FRONTEND=noninteractive
# MinGW-w64 builds the Windows programs; Wine (32-bit) runs the tests on them
RUN dpkg --add-architecture i386 && apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates build-essential gcc gcc-multilib wget byacc gcc-mingw-w64-i686 wine32 wine
ENV WINEDEBUG=-all WINEPREFIX=/tmp/wine

ENV VERSION=2.8.1
ENV GNUPATH=gnu

WORKDIR /work
RUN wget https://ftp.gnu.org/${GNUPATH}/gcc/gcc-${VERSION}.tar.gz
RUN tar xzf gcc-${VERSION}.tar.gz

WORKDIR /work/gcc-${VERSION}
COPY patches /work/patches
RUN sed -i -- 's/include <varargs.h>/include <stdarg.h>/g' *.c
RUN patch -u -p1 obstack.h -i ../patches/obstack-2.8.1.h.patch
RUN patch -u -p1 config/mips/mips.h -i ../patches/mips.patch
RUN patch -su -p1 < ../patches/psx.patch

COPY windows /work/windows
RUN bash /work/windows/build-windows.sh cross

COPY tests /work/tests
# The Linux build's tests, on the Windows programs (reading stdin and writing stdout, as decomp
# builds use cc1)
RUN wine ./cc1.exe -quiet -O2 < /work/tests/little_endian.c > /work/little_endian.s && grep -E 'lbu\s\$2,0\(\$4\)' /work/little_endian.s
RUN wine ./cc1.exe -quiet -O2 < /work/tests/section_attribute.c > /dev/null
RUN wine ./cc1.exe -quiet -O2 < /work/tests/host_wide_int.c > /work/host_wide_int.s && grep -E '# 0x80000000$' /work/host_wide_int.s
RUN ! grep -q "$(printf '\r')" /work/little_endian.s
# (a file argument: under Wine, cpp.exe can't read stdin; on Windows it can)
RUN printf '#define X 1\nint x = X;\n' > /work/macro.c && wine ./cpp.exe /work/macro.c | grep -q 'int x = 1'

RUN mkdir /build && cp cc1.exe cpp.exe /build/

FROM scratch AS export
COPY --from=build /build/* .
