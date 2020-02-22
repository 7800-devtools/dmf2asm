dmf2asm v0.1 readme

dmf2asm utility to convert YM2151-based DefleMask tracker files to 6502 
DASM assembly data, suitable for playback with the Atari 7800 XM module.

Also included is the companion 6502-based xmym tracker, which will play
the assembly songs output from dmf2asm.


Legal Stuff
-----------
 drm2asm is created by Mike Saarna, copyright 2020. It's provided here under
 the GPL v2 license. See the included LICENSE.txt file for details.

 The 6502-based xmym tracker software was also created by Mike Saarna, 
 copyright 2020. It's provide here under the CC0 license. The CC0 license is
 a public domain license, so you may do with it as you wish. See the included
 LICENSE.txt file for details.


What Is It?
-----------
 dmf2asm allows you to use DefleMask tracker to author your YM2151 music, and 
 convert the DefleMask DMF file into assembly data, which can be played with
 the included xmym tracker.

 dmf2asm and xmym tracker were written for use with the Atari 7800 XM module.

 DefleMask tracker is available at no cost for most PC platforms, and can be 
 downloaded from: http://www.deflemask.com/


Dfm2asm and Xmym Tracker Features 
---------------------------------

 dmf2asm actively tries to reduce the data output size using a couple of
 different strategies.

 First, dmf2asm does pattern deduplication, by only storing patterns that
 ar unique. 

 Second, dmf2asm will check if all of the pattern data only has rests on the 
 odd-numbered beats. If this is true, all patterns will be squeezed by 
 dropping those odd beat resets and adjusting the tick rate appropriately. 
 This squeezing is repeated until the DMF data can be squeezed no more.

 Each song can be run with a different priority value, which will determine
 if a new song may interrupt a playing one. This can be useful if you don't
 want some small sound-effect ditty interrupting a grand end-of-level opus.

 The service routine of the xmym tracker is safe to run from NMI, or you
 can run it manually each frame. 

 xmym tracker also has macros to pause/resume or stop any running music.


Getting Started Converting Files
--------------------------------
 dmf2asm is a command-line program. To convert a DMF file to DASM format 
 assembly data (printing it to the screen) just run the dfm2asm command with 
 the -i argument to specify the input file:

   dmf2asm -i INPUTFILE.DMF

 If you want to create an assembly output file, run the above command with the 
 -o argument:

   dmf2asm -i INPUTFILE.DMF -o OUTFILE.ASM

 When in doubt, run dmf2asm without any arguments to get a summary of it's 
 usage.


Restrictions When Authoring DMF Files
-------------------------------------
 DefleMask tracker is a full featured program, and to you need to follow  
 certain restrictions for best results. In brief:

 - You should use the YM2151 target system, within DefleMask. dmf2asm can't 
   import data from other systems.

 - You should only use the F1-F8 voices in your composition. dmf2asm doesn't 
   support export of the S1-S5 PCM sample voices.

 - You should limite yourself to 8 instruments in DiflMask. dmf2asm will only 
   export and use the first 8 instruments. This was done to avoid costly 
   instrument reloads mid-song, to avoid bogging down the 6502.

 - You should stick to NTSC or PAL based clock in DefleMask. Custom clocks 
   aren't supported by dmf2asm.

 - DefleMask doesn't save the enabled/disabled state of operators in any of
   the instruments in the DMF file. If you want an operator muted, handle 
   that via the ADSR envelope controls.

 You should also be advised that dmf2asm assumes that you've used all eight
 instruments. You're not required to use all eight, but all of the instrument
 related structures will be padded out to a width of eight instruments. This
 is for easier and quick parsing of structure sizes based on powers-of-two
 on the 6502. 


Using the Atari 7800 XMYM tracker
---------------------------------
 The main steps to incorporate 7800 XMYM tracker in your own program is:

  1) include the xmym.h macro definition file near the top of your code

  2) include the xmym.asm and any converted song assembly elsewhere in 
     your code, out of the way of the program flow.

  3) define these zero-page RAM locations:

       xmym_songpointerlo
       xmym_songpointerhi
       xmym_pmpointerlo
       xmym_pmpointerhi
       xmym_ppointerlo
       xmym_ppointerhi
  
  4) define these other RAM locations:

       xmym_songpriority
       xmym_playsremaining
       xmym_pausestate
       xmym_patternindex
       xmym_tick

  5) use the "xmym_init" macro prior to playing any music.

  6) use the "xmym_play" macro to play music... 

       e.g. xmym_play zanac,3,7

     ...where "zanac" is the name used with the -n switch when you ran the
     the dmf2asm utility, where 3 is the priority setting for this song,
     and where 7 is the number of times you wish the song to play. Numbers
     larger than 127 indicated infinite repeat. 

  7) (optional) You may use the xmym_stop macro to stop a playing song, or
     the xmym_pause or xmym_resume macros to temporarily halt the music.

 There are 7800basic and Assembly language examples of how to use the XMYM
 tracker in the samples directory.
