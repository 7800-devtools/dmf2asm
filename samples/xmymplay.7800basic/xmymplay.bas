
 rem ** xmymplay - an example of how to use xmym_tracker in 7800basic

 rem ** xmym.h includes macros are
 include xmym.h

 set screenheight 208

 rem ** these variables are required for xmym tracker, and need to be
 rem ** zero page (i.e. 7800basic a-z variables. You need to keep the
 rem ** lo+hi variables in the same order, and next to each other.
 dim xmym_songpointerlo  = a
 dim xmym_songpointerhi  = b
 dim xmym_pmpointerlo    = c
 dim xmym_pmpointerhi    = d
 dim xmym_ppointerlo     = e
 dim xmym_ppointerhi     = f

 rem ** these variables are also required for the tracker, but can
 rem ** be located anywhere
 dim xmym_songpriority   = var1
 dim xmym_playsremaining = var2
 dim xmym_pausestate     = var3
 dim xmym_patternindex   = var4
 dim xmym_tick           = var5

 rem ** the audio VU-level bar "level" holding variables.
 dim xmym_bar1 = var10
 dim xmym_bar2 = var11
 dim xmym_bar3 = var12
 dim xmym_bar4 = var13
 dim xmym_bar5 = var14
 dim xmym_bar6 = var15
 dim xmym_bar7 = var16
 dim xmym_bar8 = var17

 rem ** the VU-level bar text strings. We create offset-variables that
 rem ** point at the start of the text for the yellow and red portions
 rem ** of the bar text, because those are separate character objects
 rem ** so they can use a different palette.
 dim bartext1 = $2200
   dim baryellow1 = bartext1 + 20
   dim barred1    = bartext1 + 28
 dim bartext2 = $2220
   dim baryellow2 = bartext2 + 20
   dim barred2    = bartext2 + 28
 dim bartext3 = $2240
   dim baryellow3 = bartext3 + 20
   dim barred3    = bartext3 + 28
 dim bartext4 = $2260
   dim baryellow4 = bartext4 + 20
   dim barred4    = bartext4 + 28
 dim bartext5 = $2280
   dim baryellow5 = bartext5 + 20
   dim barred5    = bartext5 + 28
 dim bartext6 = $22A0
   dim baryellow6 = bartext6 + 20
   dim barred6    = bartext6 + 28
 dim bartext7 = $22C0
   dim baryellow7 = bartext7 + 20
   dim barred7    = bartext7 + 28
 dim bartext8 = $22E0
   dim baryellow8 = bartext8 + 20
   dim barred8    = bartext8 + 28

 displaymode 320A

 rem **background color...
 BACKGRND=$0

 rem **set the height of characters and sprites...
 set zoneheight 8
 set screenheight 208

 rem **import the characterset png...
 incgraphic atascii.png 320A 

 rem ** set the 320A text palette colors
 P0C2=$0F ; WHITE
 P1C2=$B6 ; GREEN
 P2C2=$1a ; YELLOW
 P3C2=$48 ; RED

 rem **set the current character set...
 characterset atascii

 rem **set the letters represent each graphic character...
 alphachars ASCII

 gosub vumeter_clear

 clearscreen

 rem        0123456789012345678901234567890123456789
 plotchars 'XMYM Tracker v0.1' 0 42 0
 plotchars 'Tracker software by RevEng' 0 24 4
 plotchars 'Deflemask converter by RevEng' 0 20 5

 rem        0123456789012345678901234567890123456789
 plotchars 'Zanac, arranged by' 0 42 7
 plotchars 'Synthpopalooza' 0 50 8


 rem ** create the character/tile objects for the VU level bars
 plotchars bartext1   1 16  12 20
 plotchars baryellow1 2 96  12  8
 plotchars barred1    3 128 12  4

 plotchars bartext2   1 16  13 20
 plotchars baryellow2 2 96  13  8
 plotchars barred2    3 128 13  4

 plotchars bartext3   1 16  14 20
 plotchars baryellow3 2 96  14  8
 plotchars barred3    3 128 14  4

 plotchars bartext4   1 16  15 20
 plotchars baryellow4 2 96  15  8
 plotchars barred4    3 128 15  4

 plotchars bartext5   1 16  16 20
 plotchars baryellow5 2 96  16  8
 plotchars barred5    3 128 16  4

 plotchars bartext6   1 16  17 20
 plotchars baryellow6 2 96  17  8
 plotchars barred6    3 128 17  4

 plotchars bartext7   1 16  18 20
 plotchars baryellow7 2 96  18  8
 plotchars barred7    3 128 18  4

 plotchars bartext8   1 16  19 20
 plotchars baryellow8 2 96  19  8
 plotchars barred8    3 128 19  4

 plotchars 'loops remaining:' 0 40 22
 plotchars xmym_playsremaining 0 120 22 1 

 savescreen

 drawscreen

 asm
 ; init and play the song
 xmym_init
 xmym_play zanac,0,2
end

main 
 restorescreen

 if switchselect then gosub stopxmym
 if switchreset then gosub replay
 if joy0fire then gosub replay

 gosub vumeter_update

 drawscreen

 goto main 

topscreenroutine
 ; the xmym_service routine needs to be called once per frame, to play
 ; the music. It doesn't actually need to be called from a topscreenroutine
 ; (e.g. it could be called after drawscreen) but this makes sure that your
 ; music never drops a frame, even if your game does.
 asm
 xmym_service
end
 return

stopxmym
 asm 
 xmym_stop
end
 return

replay
 asm
 ;xmym_stop
end
replayloop
 if joy0fire then goto replayloop
 if switchreset then goto replayloop
  asm
  xmym_play zanac,0,2
end
  return
 

vumeter_clear
 for u = 0 to 31
    bartext1[u]=32
    bartext2[u]=32
    bartext3[u]=32
    bartext4[u]=32
    bartext5[u]=32
    bartext6[u]=32
    bartext7[u]=32
    bartext8[u]=32
 next
 return

vumeter_update
 rem ** fill the bar text string with character 36 (a square circle) for 
 rem ** string positions up to the current bar value, and put character
 rem ** 32 (space) in positions greater than the bar value.
 for u = 0 to 31
    if u < xmym_bar1 then bartext1[u]=36 else bartext1[u]=32
    if u < xmym_bar2 then bartext2[u]=36 else bartext2[u]=32
    if u < xmym_bar3 then bartext3[u]=36 else bartext3[u]=32
    if u < xmym_bar4 then bartext4[u]=36 else bartext4[u]=32
    if u < xmym_bar5 then bartext5[u]=36 else bartext5[u]=32
    if u < xmym_bar6 then bartext6[u]=36 else bartext6[u]=32
    if u < xmym_bar7 then bartext7[u]=36 else bartext7[u]=32
    if u < xmym_bar8 then bartext8[u]=36 else bartext8[u]=32
 next

 rem ** decrease the bar values, every other frame
 if framecounter&1 then goto skipbardecrement
 for u = 0 to 7
   temp1 = xmym_bar1[u]
   if temp1> 0 then temp1=temp1-1
    xmym_bar1[u] = temp1
 next
skipbardecrement

 rem ** if you're wondering how the bar values get set, if xmym_bar1 is 
 rem ** defined the xmym tracker includes code that fills the xmym_bar 
 rem ** variables with "32" every time there's a note-on event on that
 rem ** channel.

 return

 rem ** Include the tracker
 include xmym.asm

 rem ** Include a song file. Multiple song files are supported.
 include zanac.asm

