#!/bin/sh
# makepackages.sh
#   apply the release.dat contents to the release text in various sources
#   and documents, and then generate the individual release packages.

RELEASE=$(cat release.dat)
ERELEASE=$(cat release.dat | sed 's/ /_/g')
YEAR=$(date +%Y)

dos2unix dmf2asm.c >/dev/null 2>&1
cat dmf2asm.c | sed 's/define PROGNAME .*/define PROGNAME "dmf2asm v'"$RELEASE"'"/g' > dmf2asm.c.new
mv dmf2asm.c.new dmf2asm.c
unix2dos dmf2asm.c >/dev/null 2>&1


# cleanup
find . -name .\*.swp -exec rm '{}' \;
rm -fr packages
mkdir packages
make dist
cd packages

for OSARCH in linux@Linux osx@Darwin win@Windows ; do
        for BITS in x64 x86 ; do
                OS=$(echo $OSARCH | cut -d@ -f1)
                ARCH=$(echo $OSARCH| cut -d@ -f2)
		rm -fr dmf2asm
		mkdir dmf2asm
		cp -R ../samples dmf2asm/
		cp ../*.txt dmf2asm/
		if [ "$OS" = win ] ; then
			cp ../dmf2asm.Win32."$BITS".exe dmf2asm/dmf2asm.exe
			zip -r dmf2asm-$ERELEASE-$OS-$BITS.zip dmf2asm
		else
			cp ../dmf2asm."$ARCH"."$BITS" dmf2asm/dfm2asm
			tar --numeric-owner -cvzf dmf2asm-$ERELEASE-$OS-$BITS.tar.gz dmf2asm
		fi
		rm -fr dmf2asm
	done
done
		
