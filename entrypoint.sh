#!/bin/sh

if [ ! -e "/build" ]; then
    echo "Mount /build when starting container!"
    echo "  e.g. docker run --rm -v \$(pwd):/build old-gcc"
    exit 0
fi

cd /work/gcc*
mv xgcc gcc
cp cpp cc1 gcc cc1plus g++ /build/

# # The following lines are useful for debugging purposes
# mkdir /build/work
# cp -r . /build/work/
