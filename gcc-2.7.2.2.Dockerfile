FROM ubuntu:focal
RUN apt-get update
RUN apt-get install -y build-essential bison file gperf gcc gcc-multilib git wget

ENV VERSION=2.7.2.2
ENV GNUPATH=old-gnu

WORKDIR /work
RUN wget https://ftp.gnu.org/${GNUPATH}/gcc/gcc-${VERSION}.tar.gz
RUN tar xzf gcc-${VERSION}.tar.gz

WORKDIR /work/gcc-${VERSION}
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

COPY patches /work/patches
RUN sed -i -- 's/include <varargs.h>/include <stdarg.h>/g' *.c
RUN patch -u -p1 obstack.h -i ../patches/obstack-2.7.2.h.patch
RUN patch -u -p1 configure -i ../patches/configure.patch
RUN patch -u -p1 config.sub -i ../patches/config.sub.patch

RUN make -j cpp cc1 xgcc cc1plus g++ CFLAGS="-std=gnu89 -m32 -static"
RUN test -f cc1
RUN file cc1

COPY entrypoint.sh /work/
RUN chmod +x /work/entrypoint.sh
CMD [ "/work/entrypoint.sh" ]
