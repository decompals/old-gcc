FROM ubuntu:focal
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get install -y build-essential gcc gcc-multilib wget

WORKDIR /work
RUN wget http://ftp.fibranet.cat/Linux/historic/slackware-3.0/source/d/gcc/gcc-2.7.0.tar.gz
RUN tar xzf gcc-2.7.0.tar.gz

WORKDIR /work/gcc-2.7.0
COPY patches /work/patches
RUN sed -i -- 's/include <varargs.h>/include <stdarg.h>/g' *.c
RUN patch -u -p1 obstack.h -i ../patches/obstack-2.7.2.h.patch
RUN patch -u -p1 configure -i ../patches/configure.patch
RUN patch -u -p1 config.sub -i ../patches/config.sub.patch
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

RUN make -j cpp cc1 xgcc cc1plus g++ CFLAGS="-std=gnu89 -m32 -static"
RUN test -f cc1

COPY entrypoint.sh /work/
RUN chmod +x /work/entrypoint.sh
CMD [ "/work/entrypoint.sh" ]
