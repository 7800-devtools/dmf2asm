;-----------------------------------------------------------------------------
; xmym.asm
;
; These are subroutines for controlling xmym. You shouldn't need to call any
; of these directly. Instead you should be including xmym.h into your assembly
; code and using the macros provided there.
;

; HARWARE REGISTERS...

xmym_driver_start

YM2151BASE = $460
XCNTRL1    = $470

; HEADER CONSTANTS...

; offset to values from start of song data
FRAMESPERTICK       = 0
PATTERNHEIGHT       = 2
PATTERNMATRIXHEIGHT = 3
PATTERNMATRIX       = 4
PATTERNMATRIXEND    = 6
INSTRUMENTDUMP      = 8


WriteToYM_X
  ; utility function: writes A to the YM, at register location X
  ; on entry: X=YM Register, A=Value to write
WaitForYMXReady1
  bit YM2151BASE+1
  bmi WaitForYMXReady1
  stx YM2151BASE 
WaitForYMXReady2
  bit YM2151BASE+1
  bmi WaitForYMXReady2
  sta YM2151BASE+1
  rts

WriteToYM_Y
  ; utility function: writes A to the YM, at register location Y
  ; on entry: Y=YM Register, A=Value to write
WaitForYMYReady1
  bit YM2151BASE+1
  bmi WaitForYMYReady1
  sty YM2151BASE 
WaitForYMYReady2
  bit YM2151BASE+1
  bmi WaitForYMYReady2
  sta YM2151BASE+1
  rts

xmym_init_jsr
  ; minimal XM init...
  ; on entry: no input
  ; modifies: a,x,flags

  ; enable the YM2151 and the cart ROM. Really this should be left to
  ; the parent program, but for now we'll do it. If anybody wants more
  ; XM gear enabled, they'll need to do so after the xmym_init.
  lda #$84 
  sta XCNTRL1

  ; disable the service routine, just in case someone runs xymy_init
  ; after playing a song...
  lda #0
  sta xmym_playsremaining
  sta xmym_songpointerlo
  sta xmym_songpointerhi
  sta xmym_pmpointerlo
  sta xmym_pmpointerhi

  ldx #$1B
  ;lda #$00 ; A is already 0
  jsr WriteToYM_X

  rts

xmym_play_jsr
  ; on entry: (xmym_songpointerlo) pointing at start of song data, but the
  ; service routine is disabled by xmym_playsremaining=0. It will be enabled
  ; with the proper value after this routine returns.

  ; first bulk load the instrument register data into the YM...
  ldy #INSTRUMENTDUMP ; we're now looking at the start of the instrument regs
  ldx #$20
xmym_instrument_load_loop
  lda (xmym_songpointerlo),y 
  jsr WriteToYM_X
  iny
  inx
  bne xmym_instrument_load_loop

  ; init song control variables
  lda #0
  sta xmym_tick
  sta xmym_patternindex
  sta xmym_pausestate
  sta xmym_pmpointerlo
  sta xmym_pmpointerhi
  rts
 
xmym_stop_jsr
  ; it's critical for NMI support that xmym_playsremaining=0 happens first, 
  ; as this protects us if the NMI happens during this routine...
  lda #0
  sta xmym_playsremaining

  sta xmym_tick

  ; Do note-offs for all channels...
  ldx #8
  ldy #7
xmym_stop_loopnoteoff
  tya 
  jsr WriteToYM_X
  dey
  bpl xmym_stop_loopnoteoff

  ; reset the pattern matrix pointer, so the next xmym_play command
  ; doesn't use the old location...
  lda #0
  sta xmym_pmpointerlo
  sta xmym_pmpointerhi
  rts

xmym_service_jsr
  ; called every frame, to update counters and play the music
  lda xmym_pausestate 
  beq xmym_service_notpaused 
xmym_service_return1
  rts
xmym_service_notpaused
  lda xmym_playsremaining
  beq xmym_service_return1 ; the song has finished playing. we should leave.
  lda xmym_songpointerlo ; check if the song pointer is non-null...
  ora xmym_songpointerhi
  beq xmym_service_return1 ; ...nope. we should leave.
  lda xmym_tick
  beq xmym_service_ready2play
    dec xmym_tick ; there are still ticks left. decrease and leave.
    rts
xmym_service_ready2play
  ; if we're here, the tick counter is zero, and we're ready to play a new row
  lda xmym_pmpointerlo
  ora xmym_pmpointerhi ; check if we have a non-null pattern matrix pointer
  bne xmym_service_skippatternmatrixsetup
     ; setup the pattern matrix pointer
     ldy #PATTERNMATRIX
     lda (xmym_songpointerlo),y
     sta xmym_pmpointerlo
     iny ; PATTERNMATRIX+1
     lda (xmym_songpointerlo),y 
     sta xmym_pmpointerhi
xmym_service_skippatternmatrixsetup

     ldy #0 
     ; y is our current pattern matrix row index. The pattern matrix data
     ; is a LUT of low+high pointers to pattern data. We're going to progress
     ; y through 16 positions, to get pattern pointers for the 8 channels...
     ldx #$28 ; the note-on register start
xmym_service_patternmatrix_loop

     sty xmym_tick ; borrowing tick as a handy temp
     lda (xmym_pmpointerlo),y
     iny
     sta  xmym_ppointerlo
     lda (xmym_pmpointerlo),y
     sta  xmym_ppointerhi
     iny
     tya ; save y, because we're about to trash it.
     pha

     ; find the note for the current pattern row... 
     ldy xmym_patternindex 
     lda (xmym_ppointerlo),y
     bmi xmym_service_skipnote ; high-bit means it's a rest
     jsr WriteToYM_X 

     ; Silence any previous note-on played on this channel. This saves us
     ; from needing an explicit note-off timer.
     lda xmym_tick   ; borrowing tick as a temp
     lsr             ; /2 because we want the channel index
     and #%00000111 
     ldy #$08        ; select the note-on register
     jsr WriteToYM_Y

     ; Now turn our note-off into a note-on, and send. We use all 4 
     ; oscillators, always.
     ora #%01111000 ; all oscillators
     ldy #$08
     jsr WriteToYM_Y

   ifconst xmym_bar1
    ; optional code - if the program wants to implement some kind of
    ; note-on display, like the VU-level style bars in the 7800basic demo, 
    ; it can define xmym_bar1 through xmym_bar8 as consecutive memory
    ; locations. Each note-on will store "32" in the respective xmym_bar# 
    ; variable.
     and #%00000111
     tay
     lda #32
     sta xmym_bar1,y
   endif

xmym_service_skipnote
     pla ; restore y back to our patternmatrix index...
     tay 
     cpy #16
     beq xmym_service_advancepatternrow ; if we're done, leave
     inx  ; otherwise move to the next channel register
     bne xmym_service_patternmatrix_loop ; (unconditional branch)

xmym_service_advancepatternrow
     ; advance song structures by 1 row, starting with pattern row...
     inc xmym_patternindex
     ; then check if we're at the end of the pattern...
     lda xmym_patternindex
     ; The stored pattern height info is #PATTERNHEIGHT distance from the 
     ; start of the header
     ldy #PATTERNHEIGHT
     cmp (xmym_songpointerlo),y 
     bne xmym_service_doneadvancepatternrow 
       ; we're at the end of the pattern. reset it, and then advance the
       ; current pattern matrix row.
       lda #0
       sta xmym_patternindex
       ; we advance the matrix row 16-bit pointer
       clc
       lda xmym_pmpointerlo
       adc #16
       sta xmym_pmpointerlo
       lda xmym_pmpointerhi
       adc #0
       sta xmym_pmpointerhi

       ; 16-bit compare to the matrix end location, to see if we've completed
       ; the current play-through of the matrix...
       ldy #PATTERNMATRIXEND 
       lda (xmym_songpointerlo),y
       cmp xmym_pmpointerlo
       bne xmym_service_doneadvancepatternrow ; ...nope, it's still in progress
       iny
       lda (xmym_songpointerlo),y
       cmp xmym_pmpointerhi
       bne xmym_service_doneadvancepatternrow ; ...nope, it's still in progress

       ; if we're here, we're at the end of the matrix...
       ; if there's song loops left, initialize for another play loop.
       lda xmym_playsremaining
       bmi xmym_service_skipsongloopdecrement ; negative means infinite loops
       dec xmym_playsremaining
       bne xmym_service_skipsongloopdecrement
         jmp xmym_stop_jsr ; note the JMP
xmym_service_skipsongloopdecrement
     ; if we're here, we have loops left. clear the matrix pointer, so it
     ; gets initialized the next time through, just like it did the first
     ; time around
     lda #0
     sta xmym_pmpointerlo
     sta xmym_pmpointerhi
xmym_service_doneadvancepatternrow
     ; setup the ticks for next time
     ; TODO: support for different tick sizes on even and off frames
     ldy #FRAMESPERTICK
     lda (xmym_songpointerlo),y
     sta xmym_tick
     rts

xmym_driver_end

