export PROJECT=xmymplay

main: 	${PROJECT}.a78

${PROJECT}.a78: ${PROJECT}.asm
	/bin/rm -f ${PROJECT}.bin 
	dasm ${PROJECT}.asm -f3 -I. -I../includes -o${PROJECT}.bin -l${PROJECT}.list.txt
	7800header.Linux.x86 -f a78info.cfg ${PROJECT}.bin
	7800sign.Linux.x86 -w ${PROJECT}.a78
	7800sign.Linux.x86 -w ${PROJECT}.bin
	
clean:
	/bin/rm -f ${PROJECT}.bin a.out ${PROJECT}.a78 ${PROJECT}.list.txt
	/bin/rm -fr cfg nvram

run:	
	a7800 a7800 -cart1 xm -cart2 ${PROJECT}.a78

