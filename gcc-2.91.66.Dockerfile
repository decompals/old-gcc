FROM ubuntu:focal as build
RUN apt-get update
RUN apt-get install -y build-essential bison file gperf gcc gcc-multilib git wget

ARG VERSION=2.91.66
ENV VERSION=${VERSION}

WORKDIR /work
RUN wget https://gcc.gnu.org/pub/gcc/old-releases/egcs/egcs-1.1.2.tar.bz2
RUN mkdir -p /work/gcc-${VERSION}/
RUN tar xjf egcs-1.1.2.tar.bz2 --strip-components=1 -C gcc-${VERSION}

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
RUN patch -u -p1 gcc/obstack.h -i ../patches/obstack-${VERSION}.h.patch

RUN make -C libiberty/ CFLAGS="-std=gnu89 -m32 -static"
RUN make -C gcc/ -j cpp cc1 xgcc cc1plus g++ CFLAGS="-std=gnu89 -m32 -static"

RUN test -f gcc/cc1
RUN file gcc/cc1

### STAGE 2

FROM ubuntu:focal as base

ARG VERSION=2.91.66
ENV VERSION=${VERSION}

RUN mkdir -p /work/gcc-${VERSION}/

COPY --from=build /work/gcc-${VERSION}/gcc/cpp /work/gcc-${VERSION}/
COPY --from=build /work/gcc-${VERSION}/gcc/cc1 /work/gcc-${VERSION}/
COPY --from=build /work/gcc-${VERSION}/gcc/xgcc /work/gcc-${VERSION}/
COPY --from=build /work/gcc-${VERSION}/gcc/cc1plus /work/gcc-${VERSION}/
COPY --from=build /work/gcc-${VERSION}/gcc/g++ /work/gcc-${VERSION}/

COPY entrypoint.sh /work/
RUN chmod +x /work/entrypoint.sh
CMD [ "/work/entrypoint.sh" ]
