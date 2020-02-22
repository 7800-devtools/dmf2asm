#!/bin/sh
# rebuild zlib static library for Win32 x86

TARGETDIR="$PWD/../Win32.x86"

rm -fr "$TARGETDIR"
mkdir "$TARGETDIR" 2>/dev/null

export PATH=/usr/x86_64-w64-mingw32/bin:$PATH
export CC=i686-w64-mingw32-gcc

#zlib.....................
rm -fr zlib-1.2.8
tar -xvzf zlib-1.2.8.tar.gz
cd zlib-1.2.8
export CFLAGS="-O2 -m32"
./configure --static --prefix="$TARGETDIR"
make
make install
cd ..
rm -fr zlib-1.2.8

