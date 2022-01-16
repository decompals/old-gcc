#!/bin/sh

cd /work/gcc*
mv xgcc gcc
cp cpp cc1 gcc cc1plus g++ /build/

# # The following lines are useful for debugging purposes
# mkdir /build/work
# cp -r . /build/work/
