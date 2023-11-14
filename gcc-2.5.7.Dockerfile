FROM ubuntu:focal as build
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get install -y build-essential gcc gcc-multilib wget

WORKDIR /work
RUN wget http://www.nic.funet.fi/index/gnu/funet/historical-funet-gnu-area-from-early-1990s/gcc-2.5.7.tar.gz
RUN tar xzf gcc-2.5.7.tar.gz

WORKDIR /work/gcc-2.5.7
COPY patches /work/patches
RUN sed -i -- 's/include <varargs.h>/include <stdarg.h>/g' *.c

RUN patch -u -p1 gvarargs.h -i ../patches/gvarargs-2.5.7.h.patch
RUN patch -u -p1 sdbout.c -i ../patches/sdbout-2.6.0.c.patch
RUN patch -u -p1 obstack.h -i ../patches/obstack-2.5.7.h.patch
RUN patch -u -p1 collect2.c -i ../patches/collect2-2.6.0.c.patch
RUN patch -u -p1 cccp.c -i ../patches/cccp-2.5.7.c.patch
RUN patch -u -p1 gcc.c -i ../patches/gcc-2.5.7.c.patch
RUN patch -u -p1 g++.c -i ../patches/g++-2.5.7.c.patch
RUN patch -u -p1 config/mips/mips.h -i ../patches/mipsel-2.5.patch

RUN ./configure \
    --target=mips-linux-gnu \
    --prefix=/opt/cross \
    --with-endian-little \
    --with-gnu-as \
    --host=i386-pc-linux \
    --build=i386-pc-linux

RUN make cpp cc1 xgcc cc1plus g++ CFLAGS="-std=gnu89 -m32 -static -Dbsd4_4 -Dmips -DHAVE_STRERROR"

COPY tests /work/tests
RUN ./cc1 -quiet -O2 /work/tests/little_endian.c && grep -E 'lbu\s\$2,0\(\$4\)' /work/tests/little_endian.s

RUN mv xgcc gcc
RUN mkdir /build && cp cpp cc1 gcc cc1plus g++ /build/

FROM scratch AS export
COPY --from=build /build/* .
