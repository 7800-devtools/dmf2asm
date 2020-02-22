#!/bin/sh
# rebuild zlib static library for Win32 x64

TARGETDIR="$PWD/../Win32.x64"

rm -fr "$TARGETDIR"
mkdir "$TARGETDIR" 2>/dev/null

export PATH=/usr/x86_64-w64-mingw32/bin:$PATH
export CC=x86_64-w64-mingw32-gcc-win32

#zlib.....................
rm -fr zlib-1.2.8
tar -xvzf zlib-1.2.8.tar.gz
cd zlib-1.2.8
export CFLAGS="-O2 -m64"
./configure --static --prefix="$TARGETDIR"
make
make install
cd ..
rm -fr zlib-1.2.8


