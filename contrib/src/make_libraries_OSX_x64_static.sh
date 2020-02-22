#!/bin/sh
# rebuild zlib static library for OS X x64 64-bit

TARGETDIR="$PWD/../Darwin.x64"

rm -fr "$TARGETDIR"
mkdir "$TARGETDIR" 2>/dev/null

export CC=i686-apple-darwin10-gcc
export PATH=/usr/i686-apple-darwin10/bin:$PATH

#zlib.....................
rm -fr zlib-1.2.8
tar -xvzf zlib-1.2.8.tar.gz
cd zlib-1.2.8
export CFLAGS="-m64 -arch i386" 
./configure --static --prefix="$TARGETDIR"
make
make install
cd ..
rm -fr zlib-1.2.8


