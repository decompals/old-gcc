FROM ubuntu:focal
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get install -y build-essential gcc gcc-multilib wget

WORKDIR /work
RUN wget https://mirrors.slackware.com/slackware/slackware-2.2.0/source/d/gcc/gcc-2.6.3.tar.gz
RUN tar xzf gcc-2.6.3.tar.gz
RUN wget https://ftp.gnu.org/old-gnu/gcc/Version2.diffs/gcc-2.6.3-2.7.0.diff.gz
RUN gunzip gcc-2.6.3-2.7.0.diff.gz
RUN mv /work/gcc-2.6.3 /work/gcc-2.7.0

WORKDIR /work/gcc-2.7.0

# Apply 2.7.0
RUN rm config/i386/linuxelf.h && \
    rm config/i386/netbsd-i386.h && \
    rm config/i386/x-linux && \
    rm config/m68k/netbsd-m68k.h && \
    rm config/m88k/mot-sysv4.h && \
    rm config/pa/t-pa-hpux && \
    rm config/pa/x-pa-hiux && \
    rm config/pa/xm-pahiux.h && \
    rm config/sh/ashlsi3.c && \
    rm config/sh/ashrsi3.c && \
    rm config/sh/lshrsi3.c && \
    rm config/t-svr3 && \
    rm cross-test.c && \
    rm fixlimits.h && \
    rm future.options
RUN patch -p1 -i ../gcc-2.6.3-2.7.0.diff

COPY patches /work/patches
RUN sed -i -- 's/include <varargs.h>/include <stdarg.h>/g' *.c
RUN patch -u -p1 obstack.h -i ../patches/obstack-2.7.2.h.patch
RUN ./configure \
    --target=mips-linux-gnu \
    --prefix=/opt/cross \
    --with-endian-little \
    --with-gnu-as \
    --host=i386-pc-linux \
    --build=i386-pc-linux

RUN make -j cpp cc1 xgcc cc1plus g++ CFLAGS="-std=gnu89 -m32 -static -Dbsd4_4 -Dmips" || true

COPY entrypoint.sh /work/
RUN chmod +x /work/entrypoint.sh
CMD [ "/work/entrypoint.sh" ]
