#!/bin/sh
# /data/fun/Atari/7800basic.0.1/contrib/lib/linux
# rebuild zlib static library for linux x86 64-bit

TARGETDIR="$PWD/../Linux.x64"

rm -fr "$TARGETDIR"
mkdir "$TARGETDIR" 2>/dev/null

#zlib.....................
rm -fr zlib-1.2.8
tar -xvzf zlib-1.2.8.tar.gz
cd zlib-1.2.8
export CFLAGS="-m64" 
./configure --static --prefix="$TARGETDIR"
make
make install
cd ..
rm -fr zlib-1.2.8


