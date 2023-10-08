FROM ubuntu:focal as build
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get install -y build-essential gcc gcc-multilib wget

ARG VERSION=2.95.2
ENV VERSION=${VERSION}
ENV GNUPATH=gnu

WORKDIR /work
RUN wget https://ftp.gnu.org/${GNUPATH}/gcc/gcc-${VERSION}.tar.gz
RUN tar xzf gcc-${VERSION}.tar.gz

WORKDIR /work/gcc-${VERSION}/
RUN for dir in libiberty gcc; do \
    cd /work/gcc-${VERSION}/${dir}; \
    ./configure \
        --target=mips-linux-gnu \
        --prefix=/opt/cross \
        --with-endian-little \
        --with-gnu-as \
        --disable-gprof \
        --disable-gdb \
        --disable-werror \
        --host=i386-pc-linux \
        --build=i386-pc-linux; \
    done

COPY patches /work/patches

RUN sed -i -- 's/include <varargs.h>/include <stdarg.h>/g' **/*.c
RUN patch -u -p1 include/obstack.h -i ../patches/obstack-${VERSION}.h.patch
RUN patch -u -p1 gcc/config/mips/mips.h -i ../patches/mipsel-2.7.patch

RUN make -C libiberty/ CFLAGS="-std=gnu89 -m32 -static"
RUN make -C gcc/ -j cpp cc1 xgcc cc1plus g++ CFLAGS="-std=gnu89 -m32 -static"

COPY tests /work/tests
RUN ./gcc/cc1 -mel -quiet -O2 /work/tests/little_endian.c && grep -E 'lbu\s\$2,0\(\$4\)' /work/tests/little_endian.s

RUN mv ./gcc/xgcc ./gcc/gcc
RUN mkdir /build && cp ./gcc/cpp ./gcc/cc1 ./gcc/gcc ./gcc/cc1plus ./gcc/g++ /build/

FROM scratch AS export
COPY --from=build /build/* .
