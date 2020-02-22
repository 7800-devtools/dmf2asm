
  ;____________________________ zanac-8-voice.dmf ___________________________

  ; 
  ; song name                  : [NULL]
  ; author name                : [NULL]
  ; dmf file version           : 24
  ; converted by               : dmf2asm 0.1

zanac_Song
   .byte $05 ; Frames Per Tick, even rows.
   .byte $05 ; Frames Per Tick, odd rows.
   .byte $20 ; pattern height, in rows.
   .byte $08 ; pattern matrix height, in rows.
   .byte <zanac_PatternMatrix
   .byte >zanac_PatternMatrix
   .byte <zanac_PatternMatrixEnd
   .byte >zanac_PatternMatrixEnd


zanac_InstrumentRegisters
   .byte $c3,$f5,$f7,$f3,$f2,$f4,$f4,$f5 ;  20-27  %LRFFFCCC = L,R,FL,CON  *
   .byte $00,$00,$00,$00,$00,$00,$00,$00 ;  28-2F  %-OOONNNN = Oct,Note    *
   .byte $00,$00,$00,$00,$00,$00,$00,$00 ;  30-37  %KKKKKK-- = KF          *
   .byte $60,$63,$70,$63,$61,$42,$50,$70 ;  38-3F  %-PPP--AA = PMS,AMS     *

   .byte $00,$01,$0f,$00,$62,$34,$30,$0f ;  40-47  %-TTTMMMM = DT1,MUL    OP1
   .byte $01,$30,$0f,$00,$32,$69,$61,$0f ;  48-4F  %-TTTMMMM = DT1,MUL    OP3
   .byte $00,$61,$0f,$00,$64,$39,$32,$0e ;  50-57  %-TTTMMMM = DT1,MUL    OP2
   .byte $00,$00,$0f,$00,$34,$04,$02,$0d ;  58-5F  %-TTTMMMM = DT1,MUL    OP4

   .byte $0c,$1d,$7f,$00,$17,$23,$22,$00 ;  60-67  %-TTTTTTT = TL         OP1
   .byte $00,$23,$43,$10,$25,$40,$19,$0e ;  68-6F  %-TTTTTTT = TL         OP3
   .byte $00,$0d,$06,$00,$0d,$18,$16,$03 ;  70-77  %-TTTTTTT = TL         OP2
   .byte $00,$0d,$0f,$00,$0d,$0e,$11,$0e ;  78-7F  %-TTTTTTT = TL         OP4

   .byte $1f,$1f,$1f,$1f,$1f,$1f,$1a,$1f ;  80-87  %KK-AAAAA = KS,AR      OP1
   .byte $1f,$5f,$1f,$1f,$1f,$1f,$17,$1f ;  88-8F  %KK-AAAAA = KS,AR      OP3
   .byte $1f,$5f,$1f,$1f,$1f,$1f,$16,$1f ;  90-97  %KK-AAAAA = KS,AR      OP2
   .byte $5f,$5f,$1f,$1f,$1f,$1f,$15,$1f ;  98-9F  %KK-AAAAA = KS,AR      OP4

   .byte $00,$0d,$93,$1f,$0f,$13,$07,$13 ;  A0-A7  %A--DDDDD = AME,D1R    OP1
   .byte $13,$8d,$93,$1f,$8f,$12,$07,$93 ;  A8-AF  %A--DDDDD = AME,D1R    OP3
   .byte $1f,$8a,$93,$1f,$9f,$8f,$9f,$93 ;  B0-B7  %A--DDDDD = AME,D1R    OP2
   .byte $00,$08,$13,$1f,$1f,$14,$1f,$13 ;  B8-BF  %A--DDDDD = AME,D1R    OP4

   .byte $1f,$19,$cb,$00,$00,$97,$00,$92 ;  C0-C7  %TT-DDDDD = DT2,D2R    OP1
   .byte $0e,$00,$df,$0f,$00,$54,$00,$df ;  C8-CF  %TT-DDDDD = DT2,D2R    OP3
   .byte $1f,$0f,$df,$00,$09,$40,$00,$df ;  D0-D7  %TT-DDDDD = DT2,D2R    OP2
   .byte $00,$00,$df,$0f,$09,$8d,$00,$df ;  D8-DF  %TT-DDDDD = DT2,D2R    OP4

   .byte $01,$b8,$05,$01,$21,$d6,$11,$01 ;  E0-E7  %DDDDRRRR = D1L,RR     OP1
   .byte $75,$f8,$9b,$07,$34,$b6,$16,$b5 ;  E8-EF  %DDDDRRRR = D1L,RR     OP3
   .byte $55,$48,$9b,$07,$04,$96,$06,$b4 ;  F0-F7  %DDDDRRRR = D1L,RR     OP2
   .byte $08,$f8,$9b,$08,$05,$76,$06,$b9 ;  F8-FF  %DDDDRRRR = D1L,RR     OP4


zanac_PatternMatrix
  .byte <zanac_000,>zanac_000, <zanac_001,>zanac_001, <zanac_005,>zanac_005, <zanac_006,>zanac_006, <zanac_007,>zanac_007, <zanac_00f,>zanac_00f, <zanac_013,>zanac_013, <zanac_017,>zanac_017
  .byte <zanac_000,>zanac_000, <zanac_002,>zanac_002, <zanac_005,>zanac_005, <zanac_006,>zanac_006, <zanac_008,>zanac_008, <zanac_010,>zanac_010, <zanac_014,>zanac_014, <zanac_017,>zanac_017
  .byte <zanac_000,>zanac_000, <zanac_003,>zanac_003, <zanac_005,>zanac_005, <zanac_006,>zanac_006, <zanac_009,>zanac_009, <zanac_011,>zanac_011, <zanac_015,>zanac_015, <zanac_017,>zanac_017
  .byte <zanac_000,>zanac_000, <zanac_004,>zanac_004, <zanac_005,>zanac_005, <zanac_006,>zanac_006, <zanac_00a,>zanac_00a, <zanac_012,>zanac_012, <zanac_016,>zanac_016, <zanac_017,>zanac_017
  .byte <zanac_000,>zanac_000, <zanac_001,>zanac_001, <zanac_005,>zanac_005, <zanac_006,>zanac_006, <zanac_00b,>zanac_00b, <zanac_00f,>zanac_00f, <zanac_013,>zanac_013, <zanac_017,>zanac_017
  .byte <zanac_000,>zanac_000, <zanac_002,>zanac_002, <zanac_005,>zanac_005, <zanac_006,>zanac_006, <zanac_00c,>zanac_00c, <zanac_010,>zanac_010, <zanac_014,>zanac_014, <zanac_017,>zanac_017
  .byte <zanac_000,>zanac_000, <zanac_003,>zanac_003, <zanac_005,>zanac_005, <zanac_006,>zanac_006, <zanac_00d,>zanac_00d, <zanac_011,>zanac_011, <zanac_015,>zanac_015, <zanac_017,>zanac_017
  .byte <zanac_000,>zanac_000, <zanac_004,>zanac_004, <zanac_005,>zanac_005, <zanac_006,>zanac_006, <zanac_00e,>zanac_00e, <zanac_012,>zanac_012, <zanac_016,>zanac_016, <zanac_017,>zanac_017
zanac_PatternMatrixEnd

zanac_000
     .byte $01,$ff,$ff,$ff,$01,$ff,$ff,$ff,$01,$ff,$ff,$ff,$01,$ff,$ff,$ff
     .byte $01,$ff,$ff,$ff,$01,$ff,$ff,$ff,$01,$ff,$ff,$ff,$01,$ff,$ff,$ff

zanac_001
     .byte $ff,$28,$ff,$28,$ff,$ff,$28,$ff,$ff,$28,$ff,$28,$ff,$ff,$28,$ff
     .byte $ff,$28,$ff,$28,$ff,$ff,$28,$ff,$ff,$28,$ff,$28,$ff,$ff,$28,$ff

zanac_002
     .byte $ff,$2c,$ff,$2c,$ff,$ff,$2c,$ff,$ff,$2c,$ff,$2c,$ff,$ff,$2c,$ff
     .byte $ff,$2c,$ff,$2c,$ff,$ff,$2c,$ff,$ff,$2c,$ff,$2c,$ff,$ff,$2c,$ff

zanac_003
     .byte $ff,$32,$ff,$32,$ff,$ff,$32,$ff,$ff,$32,$ff,$32,$ff,$ff,$32,$ff
     .byte $ff,$32,$ff,$32,$ff,$ff,$32,$ff,$ff,$32,$ff,$32,$ff,$ff,$32,$ff

zanac_004
     .byte $ff,$31,$ff,$31,$ff,$ff,$31,$ff,$ff,$31,$ff,$31,$ff,$ff,$31,$ff
     .byte $ff,$31,$ff,$31,$ff,$ff,$31,$ff,$ff,$31,$ff,$31,$ff,$ff,$31,$ff

zanac_005
     .byte $44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44
     .byte $44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44

zanac_006
     .byte $ff,$ff,$ff,$ff,$48,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$48,$ff,$ff,$ff
     .byte $ff,$ff,$ff,$ff,$48,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$48,$ff,$ff,$ff

zanac_007
     .byte $28,$ff,$2a,$ff,$2c,$ff,$28,$2a,$ff,$2c,$2a,$ff,$28,$ff,$2a,$ff
     .byte $28,$ff,$2a,$ff,$2c,$ff,$28,$2a,$ff,$2c,$2a,$ff,$28,$ff,$2a,$ff

zanac_008
     .byte $2c,$ff,$2e,$ff,$31,$ff,$2c,$2e,$ff,$31,$2e,$ff,$2c,$ff,$2e,$ff
     .byte $2c,$ff,$2e,$ff,$31,$ff,$2c,$2e,$ff,$31,$2e,$ff,$2c,$ff,$2e,$ff

zanac_009
     .byte $32,$ff,$35,$ff,$38,$ff,$32,$35,$ff,$38,$35,$ff,$32,$ff,$35,$ff
     .byte $32,$ff,$35,$ff,$38,$ff,$32,$35,$ff,$38,$35,$ff,$32,$ff,$35,$ff

zanac_00a
     .byte $31,$ff,$34,$ff,$36,$ff,$31,$34,$ff,$36,$34,$ff,$31,$ff,$34,$ff
     .byte $31,$ff,$34,$ff,$36,$ff,$38,$ff,$3a,$ff,$3c,$ff,$3e,$ff,$41,$ff

zanac_00b
     .byte $48,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$45,$ff,$ff,$ff,$ff,$ff,$ff,$ff
     .byte $42,$41,$ff,$3e,$41,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff

zanac_00c
     .byte $45,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$42,$ff,$ff,$ff,$ff,$ff,$ff,$ff
     .byte $41,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$3e,$ff,$ff,$ff,$41,$ff,$ff,$ff

zanac_00d
     .byte $42,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$41,$ff,$ff,$ff,$ff,$ff,$ff,$ff
     .byte $3e,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$3c,$ff,$ff,$ff,$ff,$ff,$ff,$ff

zanac_00e
     .byte $3a,$3c,$3a,$3c,$3a,$3c,$3a,$3c,$3a,$3c,$3a,$3c,$3a,$3c,$3a,$3c
     .byte $3a,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff

zanac_00f
     .byte $0d,$1d,$2d,$3d,$4d,$3d,$2d,$1d,$0d,$1d,$2d,$3d,$4d,$3d,$2d,$1d
     .byte $0d,$1d,$2d,$3d,$4d,$3d,$2d,$1d,$0d,$1d,$2d,$3d,$4d,$3d,$2d,$1d

zanac_010
     .byte $01,$11,$21,$31,$41,$31,$21,$11,$01,$11,$21,$31,$41,$31,$21,$11
     .byte $01,$11,$21,$31,$41,$31,$21,$11,$01,$11,$21,$31,$41,$21,$11,$01

zanac_011
     .byte $08,$18,$28,$38,$48,$38,$28,$18,$08,$18,$28,$38,$48,$38,$28,$18
     .byte $08,$18,$28,$38,$48,$38,$28,$18,$08,$18,$28,$38,$48,$38,$28,$18

zanac_012
     .byte $06,$16,$26,$36,$46,$36,$26,$16,$06,$16,$26,$36,$46,$36,$26,$16
     .byte $06,$16,$26,$36,$46,$36,$26,$16,$06,$16,$26,$36,$46,$36,$26,$16

zanac_013
     .byte $28,$28,$ff,$28,$28,$ff,$28,$28,$ff,$28,$28,$ff,$28,$28,$ff,$28
     .byte $28,$ff,$28,$28,$ff,$28,$28,$ff,$28,$ff,$28,$ff,$28,$ff,$28,$ff

zanac_014
     .byte $2c,$2c,$ff,$2c,$2c,$ff,$2c,$2c,$ff,$2c,$2c,$ff,$2c,$2c,$ff,$2c
     .byte $2c,$ff,$2c,$2c,$ff,$2c,$2c,$ff,$2c,$ff,$2c,$ff,$2c,$ff,$2c,$ff

zanac_015
     .byte $32,$32,$ff,$32,$32,$ff,$32,$32,$ff,$32,$32,$ff,$32,$32,$ff,$32
     .byte $32,$ff,$32,$32,$ff,$32,$32,$ff,$32,$ff,$32,$ff,$32,$ff,$32,$ff

zanac_016
     .byte $31,$31,$ff,$31,$31,$ff,$31,$31,$ff,$31,$31,$ff,$31,$31,$ff,$31
     .byte $31,$ff,$31,$31,$ff,$31,$31,$ff,$31,$ff,$31,$ff,$31,$ff,$31,$ff

zanac_017
     .byte $35,$ff,$35,$35,$35,$ff,$35,$35,$35,$ff,$35,$35,$35,$35,$35,$35
     .byte $35,$ff,$35,$35,$35,$ff,$35,$35,$35,$ff,$35,$35,$35,$35,$35,$35

zanac_SongEnd

  echo "  *** the zanac.asm song data is",[(zanac_SongEnd-zanac_Song)]d,"bytes long."

  echo "  *** the xmfm driver size is",[(xmym_driver_end-xmym_driver_start)]d,"bytes long."

