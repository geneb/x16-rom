;----------------------------------------------------------------------
; RS232 Serial Port Driver for the 16550 UART
; The structure for this was cribbed from the original CBM C64 v3 KERNAL
; code.
; The X16 Serial/Network card and X16 Dual MIDI/Wavetable card can be 
; configured for the following addresses:
; Network I/O / MIDI 1
; ------------------------------------------------------
; IO3-Low: 0x9F60-0x9F67 IO3-High: 0x9F70-0x9F77
; IO4-Low: 0x9F80-0x9F87 IO4-High: 0x9F90-0x9F97
; IO5-Low: 0x9FA0-0x9FA7 IO5-High: 0x9FB0-0x9FB7
; IO6-Low: 0x9FC0-0x9FC7 IO6-High: 0x9FD0-0x9FD7
; IO7-Low: 0x9FE0-0x9FE7 IO7-High: 0x9FF0-0x9FF7
;
; Serial I/O / MIDI 2
; IO3-Low: 0x9F68-0x9F6F IO3-High: 0x9F78-0x9F7F
; IO4-Low: 0x9F88-0x9F8F IO4-High: 0x9F98-0x9F9F
; IO5-Low: 0x9FA8-0x9FAF IO5-High: 0x9FB8-0x9FBF
; IO6-Low: 0x9FC8-0x9FCF IO6-High: 0x9FD8-0x9FDF
; IO7-Low: 0x9FE8-0x9FEF IO7-High: 0x9FF8-0x9FFF
;
; IO7-Low is the default for the Serial/Network card.
; IO6-Low is the default for the MIDI/Wavetable card.
;----------------------------------------------------------------------


.include "io.inc"

.segment "RS232D"

.import dfltn, dflto
.import t1, status, addr232

.export cls232
.export cko232
.export cki232
.export bso232
.export bsi232

	
;CLOSE
;
cls232:
	clc
	rts
	
;CKOUT
;
cko232:
	sta dflto
	clc
	rts

;CHKIN
;
cki232:
	sta dfltn
	clc
	rts

;BSOUT
; Output a character.
bso232:

; TODO check for cts first.

	lda t1
	sta addr232
	rts

;BASIN
; Input a character.
bsi232:
; 	lda #$01
; 	sta veralo
; 	lda #$80
; 	sta veramid
; 	lda #$0F
; 	sta verahi
; 	lda #1
; 	bit veradat
; 	bne :+
; 	lda #8 ; EMPTY
; 	sta status
; 	lda #0
; 	rts

; :	lda #0 ; OK
; 	sta status
; 	dec veralo
; 	lda veradat
	rts

