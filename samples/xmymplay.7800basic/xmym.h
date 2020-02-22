;----------------------------------------------------------------------------
; xmym.h
; 
; included here are macros for easily starting, stoping, or pausing xmym 
; tracker songs. Since this file is just a macro defining header, and doesn't 
; require any rom space, you should include it near the top of your assembly
; file, so the macros are defined before you try to use them.
;
; The macros below will access common routines in xmym.asm; be sure to
; include xmym.asm somewhere in your assembly code, out of the way of your 
; existing program flow.
; 

 MAC xmym_init
 ;
 ; Usage: xmym_init
 ; Maps YM into address space, and does a minimal init

 jsr xmym_init_jsr

 ENDM


 MAC xmym_play
 ;
 ; Usage: xmym_play NAME PRIORITY COUNT
 ;   where NAME is the name you used with the -n switch in dmf2asm
 ;   where COUNT is an immediate value >0. Use a value >127 for infinite loop.
 ;   where PRIORITY is an immediate value >0. This allows the driver to ignore
 ;    a new play attempt, if an in-progress song is higher priority.
 ;    (you wouldn't want a four-note bonus ditty to interrupt an 
 ;     end-of-level opus, would you?)

  lda xmym_playsremaining
  beq .xmym_play_skipprioritycheck
    lda #{2}
    cmp xmym_songpriority
    bcc .xmym_play_end
.xmym_play_skipprioritycheck
    ; To make this NMI safe, we turn off the service routine with 
    ; xmym_playsremaining=0 first, and don't turn it back on again until 
    ; all of the song playing structures are setup
    lda #0
    sta xmym_playsremaining
    lda #<{1}_Song
    sta xmym_songpointerlo
    lda #>{1}_Song
    sta xmym_songpointerhi
    lda #{2}
    sta xmym_songpriority
    jsr xmym_play_jsr 
    lda #{3}
    sta xmym_playsremaining
.xmym_play_end

 ENDM


 MAC xmym_stop
 ;
 ; Usage: xmym_stop
 ; Not much to this one

     jsr xmym_stop_jsr

 ENDM


 MAC xmym_pause
 ;
 ; Usage: xmym_pause

    inc xmym_pausestate
   
 ENDM


 MAC xmym_resume
 ;
 ; Usage: xmym_resume

    lda #0
    sta xmym_pausestate

 ENDM


 MAC xmym_service

    jsr xmym_service_jsr

 ENDM

