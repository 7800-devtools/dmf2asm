; xmymplay - An example of how to use xmym tracker in assembly code.
;

	processor 6502

  include 7800.h

  ; load xmym macros...
  include xmym.h

	SEG.U data


; Variable setup...

	ORG $40

; these xmym_tracker variables need to be zero page...
xmym_songpointerlo   ds.b 1
xmym_songpointerhi   ds.b 1
xmym_pmpointerlo     ds.b 1
xmym_pmpointerhi     ds.b 1
xmym_ppointerlo      ds.b 1
xmym_ppointerhi      ds.b 1

; these xmym_tracker variables can located be anywhere...
xmym_songpriority    ds.b 1
xmym_playsremaining  ds.b 1
xmym_pausestate      ds.b 1
xmym_patternindex    ds.b 1
xmym_tick            ds.b 1

; these are entirely unrelated to xmym tracker...
TEMP1LO		ds.b	1
TEMP1HI		ds.b	1
TEMP2LO		ds.b	1
TEMP2HI		ds.b	1
TEMP3LO		ds.b	1
TEMP3HI		ds.b	1
TEMP4		ds.b	1
TEMP5		ds.b	1

cursorx		ds.b	1
cursory		ds.b	1

interruptcount	ds.b	1
maxinterrupt	ds.b	1

paldetected		ds.b    1
screenheight		ds.b	1
frame			ds.b	1


	SEG     ROM
ROMTOP  ORG     $8000       ;Start of code


; some of our own defines and variables...

SCREENWIDTH  = 40
SCREENHEIGHT = 24

DLLRAM        = $2700 
CHRBUFRAM     = $2200 ; to $265F *** our character buffer RAM

DEFAULTCHARSET
	incbin "atascii.bin"


; recommended startup procedure

START
	sei                     ;Disable interrupts
	cld                     ;Clear decimal mode
	
	lda #$07
	sta INPTCTRL        ;Lock into 7800 mode
	lda #$7F
	sta CTRL            ;Disable DMA
	lda #$00            
	sta OFFSET
	sta INPTCTRL
	ldx #$FF            ;Reset stack pointer
	txs


; Clear zero page and page 1

	ldx #$40
	lda #$00
crloop1
	sta $00,x           ;Clear zero page
	sta $100,x          ;Clear page 1
	inx
	bne crloop1

	ldy #$00 ;Clear Ram
	lda #$18 ;Start at $1800
	sta $81
	lda #$00
	sta $80
crloop3
	lda #$00
	sta ($80),y ;Store data
	iny ;Next byte
	bne crloop3 ;Branch if not done page
		inc $81 ;Next page
		lda $81
		cmp #$20 ;End at $1FFF
	bne crloop3 ;Branch if not

	ldy #$00 ;Clear Ram
	lda #$22 ;Start at $2200
	sta $81
	lda #$00
	sta $80
crloop4
	lda #$00
	sta ($80),y ;Store data
	iny ;Next byte
	bne crloop4 ;Branch if not done page
	inc $81 ;Next page
	lda $81
	cmp #$27 ;End at $27FF
	bne crloop4 ;Branch if not

	ldx #$00
	lda #$00
crloop5     ;Clear 2100-213F, 2000-203F
	sta $2000,x
	sta $2100,x
	inx
	cpx #$40
	bne crloop5

	sta $80
	sta $81
	sta $82
	sta $83

; detect console type...

pndetectvblankstart
	bit MSTAT
	bpl pndetectvblankstart ; if we're not in VBLANK, wait for it to start 
pndetectvblankover
	bit MSTAT
	bmi pndetectvblankover ;  then wait for it to be over
	ldy #$ff
	ldx #$00
pndetectvblankhappening
	bit MSTAT
	bmi pndetectinvblank   ;  if VBLANK starts, exit our counting loop 
	sta WSYNC
	sta WSYNC
	inx
	bne pndetectvblankhappening
pndetectinvblank
	cpx #125
	bcc pndetecispal
	ldy #$00
pndetecispal
	sty paldetected

; fix interrupt count according to console

	lda paldetected
	bne ntscdetected
		lda #13
		sta maxinterrupt
		lda #30
		sta screenheight
		bne detectcomplete
ntscdetected
		lda #11
		sta maxinterrupt
		lda #24
		sta screenheight
detectcomplete

; fill character buffer with ascii spaces 

	jsr clearscreen

; copy DisplayListList into RAM
	ldy #127
copydllrom
	lda DLLROM,y
	sta DLLRAM,y
	dey
	bpl copydllrom

; traverse DisplayListList and populate each DL with 2x 20-wide
; entries pointing at a different part of the the character buffer

DLLPOINTLO    = TEMP1LO
DLLPOINTHI    = TEMP1HI
DLPOINTLO     = TEMP2LO
DLPOINTHI     = TEMP2HI
CHRBUFPOINTLO = TEMP3LO
CHRBUFPOINTHI = TEMP3HI
SAVEY = TEMP4

builddls
	lda #<CHRBUFRAM
	sta CHRBUFPOINTLO
	lda #>CHRBUFRAM
	sta CHRBUFPOINTHI
	lda #<DLLRAM
	sta DLLPOINTLO
	lda #>DLLRAM
	sta DLLPOINTHI
	ldy #VISIBLEOFFSET ; skip to the visible part of the DL
builddlsloop
	iny
	lda (DLLPOINTLO),y
	sta DLPOINTHI
	iny
	lda (DLLPOINTLO),y
	sta DLPOINTLO
	iny
	sty SAVEY

	ldy #0
	;*** 5 byte DL entry...
	lda CHRBUFPOINTLO
	sta (DLPOINTLO),y
	iny
	lda #%01100000 ; *** 320A, character mode
	sta (DLPOINTLO),y
	iny
	lda CHRBUFPOINTHI
	sta (DLPOINTLO),y
	iny
	lda #$0C ; *** 20 wide (32-20)
	sta (DLPOINTLO),y
	iny
	lda #0
	sta (DLPOINTLO),y
	iny

	clc
	lda CHRBUFPOINTLO
	adc #20 ; *** move ahead 20 characters
	sta CHRBUFPOINTLO
	lda CHRBUFPOINTHI
	adc #0 ; X offset
	sta CHRBUFPOINTHI

	;*** 5 byte DL entry...
	lda CHRBUFPOINTLO
	sta (DLPOINTLO),y
	iny
	lda #%01100000 ; *** 320A, character mode
	sta (DLPOINTLO),y
	iny
	lda CHRBUFPOINTHI
	sta (DLPOINTLO),y
	iny
	lda #$0C ; *** 20 wide (32-20)
	sta (DLPOINTLO),y
	iny
	lda #80 ; X offset
	sta (DLPOINTLO),y
	;iny

	clc
	lda CHRBUFPOINTLO
	adc #20 ; *** move ahead 20 characters
	sta CHRBUFPOINTLO
	lda CHRBUFPOINTHI
	adc #0
	sta CHRBUFPOINTHI

	ldy SAVEY
	cpy #VISIBLEOFFSETEND+9
	bne builddlsloop


	ldx #0
	ldy #0
	jsr putstring
	dc "XMYM Tracker v0.1 ",0

	ldx #0
	ldy #1
	jsr putstring
	dc "(The assembly code example)",0

	ldx #0
	ldy #3
	jsr putstring
	dc "Tracker software by RevEng",0

	ldx #0
	ldy #4
	jsr putstring
	dc "Deflemask dmf2asm converter by RevEng",0

	ldx #0
	ldy #6
	jsr putstring
	dc "Zanac music, arranged by Synthpopalooza",0

	
; enable display...
	jsr waitforvblank
	lda #>DEFAULTCHARSET
	sta CHARBASE
	lda #>DLLRAM
	sta DPPH
	lda #<DLLRAM
	sta DPPL
	lda #%01000011  ; enable DMA, read-mode=320A/C
	sta CTRL

	lda #$0f
	sta P0C2 ; white characters 

 ; start up xmym_tracker...
  xmym_init
  xmym_play zanac,0,2

MAIN
MAINloop

MAINwaitvblankend ; *** wait for vblank to be over
	BIT MSTAT
	bmi MAINwaitvblankend
	; *** VBLANK is over now


	; *** We're at the top of the visible screen.
	; *** any code that needs to run at the top of the display can go here


MAINwaitvblankstart ; *** wait for vblank to start
	BIT MSTAT
	bpl MAINwaitvblankstart

	; *** VBLANK is active now


	jmp MAINloop

  include xmym.asm
  include zanac.asm


; ************** utility routines ******

; ensure we're at the start of vblank
waitforvblank
waitforvblankend1
	bit MSTAT
	bmi waitforvblankend1 ; wait for vblank to end
waitforvblank1
	bit MSTAT
	bpl waitforvblank1 ; wait for vblank
	rts

; ************** general term utility routines ******

puthexbyte
;		Puts a hex byte value on the screen
	sta TEMP4 ; save A
	lsr
	lsr
	lsr
	lsr
	tay
	lda hexcharlookup,y
	jsr putchar
	lda TEMP4 ; restore A
	and #$0F
	tay
	lda hexcharlookup,y
	jmp putchar
	;rts ; skipped, jmp used above

hexcharlookup ; lookup ascii code for hex digit
 .byte $30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$41,$42,$43,$44,$45,$46
	

; putchar 	Puts a single character on the screen, at the cursor X,Y. 
;		IN:A=character,cursorx,cursory.  OUT=none
;		NOTE: Does no terminal control code interpretation.
;		Will advance the cursor X,Y. Will line-wrap. Will scroll the screen.
putchar	
	tax ; save A
	ldy cursory
	lda ScreenYLookupLo,y
	sta TEMP1LO
	lda ScreenYLookupHi,y
	sta TEMP1HI
	ldy cursorx
	txa ; restore A
	sta (TEMP1LO),y
	; *** The character is on the screen. Now we need to adjust the cursor X,Y
	inc cursorx
	cpy #(SCREENWIDTH-1) ; is cursor x < than SCREENWIDTH?
	bcc putcharreturn ; if so, exit.
	lda #0
	sta cursorx
	inc cursory
	lda cursory
	cmp screenheight ; check if we've moved past the last line
	bcc putcharreturn ; if not, exit
putcharreturn
	rts

; Put the string following in-line until a NULL out to the console
; This is Ross Archer's alternative of the C128 PRIMM Kernal ROM routine.
;
; Usage:    ldx #[X-Coordinate]
;           ldy #[Y-Coordinate]
;           jsr putstring
;           .byte "Hello World!",$00
;           [putstring will return after your string data]

putstring
	stx cursorx
	sty cursory
	pla			; Get the low part of "return" address
                                ; (data start address)
        sta     TEMP3LO
        pla
        sta     TEMP3HI             ; Get the high part of "return" address
                                ; (data start address)

        ; Note: actually we're pointing one short
PSINB   ldy     #1
        lda     (TEMP3LO),y         ; Get the next string character
        inc     TEMP3LO             ; update the pointer
        bne     PSICHO          ; if not, we're pointing to next character
        inc     TEMP3HI             ; account for page crossing
PSICHO  ora     #0              ; Set flags according to contents of
                                ;    Accumulator
        beq     PSIX1           ; don't print the final NULL
        jsr     putchar         ; write it out
        jmp     PSINB           ; back around
PSIX1   inc     TEMP3LO             ;
        bne     PSIX2           ;
        inc     TEMP3HI             ; account for page crossing
PSIX2   jmp     (TEMP3LO)           ; return to byte following final NULL

; clearscreen	Fills the screen with ascii spaces. Sets the cursor X,Y to 0,0.
;		IN:none.  OUT=none
clearscreen
	ldx #$0
	lda #32 ; ascii space character
clearscreenloop
	sta CHRBUFRAM+$000,x
	sta CHRBUFRAM+$100,x
	sta CHRBUFRAM+$200,x
	sta CHRBUFRAM+$300,x
	sta CHRBUFRAM+$400,x
	sta CHRBUFRAM+$500,x
	sta CHRBUFRAM+$600,x
	dex
	bne clearscreenloop
	stx cursorx
	stx cursory
	rts

; screen lookup tables
ScreenYLookupLo
CHRBUFLINE SET (CHRBUFRAM+(0*40))
  REPEAT 30
	.byte <CHRBUFLINE
CHRBUFLINE SET CHRBUFLINE + 40
  REPEND
ScreenYLookupHi
CHRBUFLINE SET (CHRBUFRAM+(0*40))
  REPEAT 30
	.byte >CHRBUFLINE
CHRBUFLINE SET CHRBUFLINE + 40
  REPEND


; FRAME     NTSC    PAL
; VBLANK    20      20
; OVERSCAN  25      25
; VISIBLE  192     242
; OVERSCAN  26      26


; ************** DLL data ******

DLLROM

 ; OVERSCAN LINES... 25
	.byte $00 ; 1 lines
	.byte >BLANKDL
	.byte <BLANKDL

	.byte $8F ; 16 lines, +interrupt after previous DLL entry
	.byte >BLANKDL
	.byte <BLANKDL

	.byte $07 ; 8 lines
	.byte >BLANKDL
	.byte <BLANKDL


VISIBLESTART
VISIBLEOFFSET = (VISIBLESTART-DLLROM)

 ; We create enough visible lines to cover PAL
 ; VISIBLE LINES 240 (30 zones, interrupt every 3 zones)

DLMEMVAL SET $1800
 echo "DLMEMVAL START: ",(DLMEMVAL)
   REPEAT 10
	.byte $87 ; 8 lines
	.byte >DLMEMVAL
	.byte <DLMEMVAL
DLMEMVAL SET DLMEMVAL + 27
	.byte $07 ; 8 lines
	.byte >DLMEMVAL
	.byte <DLMEMVAL
DLMEMVAL SET DLMEMVAL + 27
	.byte $07 ; 8 lines
	.byte >DLMEMVAL
	.byte <DLMEMVAL
DLMEMVAL SET DLMEMVAL + 27
   REPEND
 echo "DLMEMVAL END: ",(DLMEMVAL-1)

VISIBLEEND

VISIBLEOFFSETEND = (VISIBLEEND-VISIBLESTART)

 ; the "empty" DL memory we use for non-visible DLs is at the end of the real DL memory
BLANKDL = DLMEMVAL
 echo "BLANKDL: ",(BLANKDL),",",(BLANKDL+1)

 ; OVERSCAN LINES... 26

	.byte $8F ; 16 lines, +interrupt after previous DLL entry
	.byte >BLANKDL
	.byte <BLANKDL

	.byte $07 ; 8 lines
	.byte >BLANKDL
	.byte <BLANKDL

	.byte $8F ; 16 lines, +interrupt after previous DLL entry
	.byte >BLANKDL
	.byte <BLANKDL

DLLROMEND
	echo "DLL SIZE: ",(DLLROMEND-DLLROM)

NMI
	cld ; typical NMI startup...
	pha
	txa
	pha
	tya
	pha

	lda interruptcount
	bne NMI_carron
	xmym_service
NMI_carron
	inc interruptcount
	lda interruptcount
	cmp maxinterrupt
	bcc EndNMI
		lda #0
		sta interruptcount
EndNMI
	pla ; typical NMI shutdown...
	tay
	pla
	tax
	pla
	rti 

IRQ
	rti ; *** No IRQ at this time

 echo " * * * * * * ",($FF7B-*)d,"bytes left in the ROM. * * * * * *"
 echo ""
 if (*>$FF7A)
        ERR  ; abort the assembly if we've spilled into the signature area
 endif

 ORG $FF7B
RESET
  jmp START

   
;************** Cart reset vector **************************

	 ORG     $FFF8
	.byte   $FF         ;Region verification
	.byte   $F7         ;ROM start $f000
	.word   NMI
	.word   RESET
	.word   IRQ
