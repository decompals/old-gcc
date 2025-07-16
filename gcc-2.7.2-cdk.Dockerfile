FROM ubuntu:focal AS build
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates build-essential gcc gcc-multilib wget byacc

WORKDIR /work
RUN wget https://github.com/ser-pounce/cdk-gcc/archive/refs/tags/b18.tar.gz
RUN tar xzf b18.tar.gz

WORKDIR /work/cdk-gcc-b18

COPY patches /work/patches
RUN patch -u -p1 Makefile.in -i ../patches/Makefile-2.7.2-cdk.in.patch
RUN patch -u -p1 obstack.h -i ../patches/obstack-2.7.2-cdk.h.patch
RUN patch -u -p1 config/mips/mips.h -i ../patches/mipsel-2.7-cdk.patch

RUN ./configure \
    --target=mips-linux-gnu \
    --prefix=/opt/cross \
    --with-endian-little \
    --with-gnu-as \
    --disable-gprof \
    --disable-gdb \
    --disable-werror \
    --host=i386-pc-linux \
    --build=i386-pc-linux

RUN make --jobs $(nproc) cpp cc1 xgcc cc1plus g++ CFLAGS="-std=gnu89 -m32 -static"

COPY tests /work/tests
RUN ./cc1 -quiet -O2 /work/tests/little_endian.c && grep -E 'lbu\s\$2,0\(\$4\)' /work/tests/little_endian.s
RUN ./cc1 -quiet -O2 /work/tests/section_attribute.c

RUN mv xgcc gcc
RUN mkdir /build && cp cpp cc1 gcc cc1plus g++ /build/

FROM scratch AS export
COPY --from=build /build/* .
