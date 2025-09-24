.segment "NES2HDR"
  .byte $4E,$45,$53,$1A                           ;  magic signature
  .byte 8                                         ;  PRG ROM size in 16384 byte units
  .byte 0                                         ;  CHR
  .byte $52                                       ;  mirroring type and mapper number lower nibble
  .byte $08                                       ;  mapper number upper nibble
  .byte $00,$00,$90,$07,$00,$00,$00,$00

;-------------------------------------------------------------------------------------
;DEFINES

PPU_CTRL              = $2000
PPU_MASK              = $2001
PPU_STATUS            = $2002
PPU_SCROLL            = $2005
PPU_ADDR              = $2006
PPU_DATA              = $2007

DMC_FREQ              = $4010
APU_STATUS            = $4015
JOY1                  = $4016
JOY2_FRAME            = $4017

FDSBIOS_NMIFlag       = $0100
FDSBIOS_IRQFlag       = $0101
FDSBIOS_ResetFlag1    = $0102
FDSBIOS_ResetFlag2    = $0103

FDS_WRITEDATA         = $4024
FDS_STATUS            = $4030
FDS_READDATA          = $4031
ZP_JOY1               = $F5

.include "mmc5_defines.inc"

;.import SM2SAVE_Header
;.import GamesBeatenCount

.segment "FDSBIOS"
.org $e000

Reset:
    sei                     ;mmc5 init
	lda #$03
    sta MMC5_PRGMODE
    lsr
    sta MMC5_EXRAMPROTECT2
    asl
    sta MMC5_EXRAMPROTECT1
	sta MMC5_EXRAMMODE
    sta MMC5_IRQSTATUS
    lda MMC5_IRQSTATUS
    ldx #$00
	stx MMC5_CHRMODE
    stx MMC5_PRG_6000
    stx MMC5_CHR_1C00
	stx $012F
    inx
    stx MMC5_PRG_8000
    inx
    stx MMC5_PRG_A000
    inx
    stx MMC5_PRG_C000

	lda #$10				;replicate init code present in FDS BIOS
	sta PPU_CTRL
	cld
	lda #$06
	sta PPU_MASK
	ldx #$02
VBlank:
	lda PPU_STATUS
	bpl VBlank
	dex
	bne VBlank
	stx JOY1
	stx DMC_FREQ
	lda #$c0
	sta JOY2_FRAME
	lda #$0f
	sta APU_STATUS
	ldx #$ff
	txs
	lda #$50
	sta MMC5_NAMETABLES
	lda #$c0
	sta FDSBIOS_NMIFlag    ;PC action on NMI
	lda #$80
	sta FDSBIOS_IRQFlag    ;PC action on IRQ
	lda FDSBIOS_ResetFlag1 ;mimic warm boot check in FDS BIOS
	cmp #$35
	bne ColdBoot           ;$0102 must be $35 for a warm boot
	lda FDSBIOS_ResetFlag2
	cmp #$53
	beq WarmBoot           ;$0103 will be $53 if game was soft-reset
	cmp #$ac
	bne ColdBoot           ;$0103 will be $ac if first boot of game
	lda #$53               ;if $0103 is $ac, change to $53 to indicate
	sta FDSBIOS_ResetFlag2 ;that the user did a soft-reset
	bne WarmBoot           ;unconditional branch to run the game

ColdBoot:
    lda #$35               ;cold boot, must init PRG-RAM and CHR-ROM
	sta FDSBIOS_ResetFlag1 ;PC action on reset
	lda #$ac
	sta FDSBIOS_ResetFlag2 ;PC action on reset
    jsr FDSBIOS_LOADFILES
	.word BootFiles	;padding
	.word BootFiles
WarmBoot:	
	lda PPU_STATUS         ;FDS BIOS stuff
	ldx #$00
	stx $FB
	stx $FC
	stx $FD
	stx PPU_SCROLL
	stx PPU_SCROLL
	dex
	stx $F9
	lda #$06
	sta $FE
	lda #$10
	sta $FF
	sta PPU_STATUS
	cli
	jmp ($dffc)            ;run game
BootFiles:
	.byte $01,$02,$06,$ff

.res $e149 - *, $ff
Delay132:
	pha
	lda #$16
	sec
DelayLoop:
	sbc #$01
	bcs DelayLoop
	pla
	rts

.res $e18b - *, $ff
FDSBIOS_NMI:
	bit FDSBIOS_NMIFlag
	bpl NMI_Vector1
	bvc NMI_Vector2
	jmp ($dffa)
NMI_Vector2:
	jmp ($dff8)
NMI_Vector1:
	bvc VINTWait
	jmp ($dff6)
VINTWait:
	lda $ff
	and #$7f
	sta $ff
	sta PPU_CTRL
	lda PPU_STATUS
	pla
	pla
	pla
	pla
	sta FDSBIOS_NMIFlag
	pla
	rts

.res $e1c7 - *, $ff
FDSBIOS_IRQ:
	bit FDSBIOS_IRQFlag
	bmi prg_e1ea
	bvc prg_e1d9
	ldx FDS_READDATA
	ldx FDS_WRITEDATA
	pla
	pla
	pla
	txa
	rts
prg_e1d9:
	pha
	lda FDSBIOS_IRQFlag
	sec
	sbc #$01
	bcc prg_e1e8
	sta FDSBIOS_IRQFlag
	lda FDS_READDATA
prg_e1e8:
	pla
	rti
prg_e1ea:
	bvc prg_e1ef
	jmp ($dffe)
prg_e1ef:
	pha
	lda FDS_STATUS
	jsr Delay132
	pla
	rti

.res $e1f8 - *, $ff
FDSBIOS_LOADFILES:
	pla
	clc
	adc #$03
	sta $08
	pla
	adc #$00
	sta $09
	ldy #$00
	lda ($08),y
	sta $0a
	iny
	lda ($08),y
	sta $0b
	jsr DoFileShit
	inc $08
	bne NoIncReturn
	inc $09
NoIncReturn:
	lda $09
	pha
	lda $08
	pha
	lda #$00
	rts

.res $e239 - *, $ff
FDSBIOS_WRITEFILE:
	ldx #$05
:	lda $6600,x
	sta $5c00,x
	dex
	bpl :-
	pla
	clc
	adc #$04
	sta $08
	pla
	adc #$00
	pha
	lda $08
	pha
	lda #$00
	rts

.res $e97d - *, $ff
Pixel2NamConv:
	lda #$08
	sta $00
	lda $02
	asl a
	rol $00
	asl a
	rol $00
	and #$e0
	sta $01
	lda $03
	lsr a
	lsr a
	lsr a
	ora $01
	sta $01
	rts
	
Nam2PixelConv:
	lda $01
	asl a
	asl a
	asl a
	sta $03
	lda $01
	sta $02
	lda $00
	lsr a
	ror $02
	lsr a
	ror $02
	lda #$f8
	and $02
	sta $02
	rts
	
.res $e9c8 - *, $ff
	lda #$00
	sta $2003
	lda #$02
	sta $4014
	rts

.res $e9eb - *, $ff
ReadPads:
	ldx $fb
	inx
	stx $4016;	[NES] Joypad & I/O port for port #1
	dex
	stx $4016;	[NES] Joypad & I/O port for port #1
	ldx #$08
:	lda $4016;	[NES] Joypad & I/O port for port #1
	lsr a
	rol $f5
	lsr a
	rol $00
	lda $4017;	[NES] Joypad & I/O port for port #2
	lsr a
	rol $f6
	lsr a
	rol $01
	dex
	bne :-
	rts

; Combine the reports from the built-in and expansion gamepads by OR'ing them
; together, storing them in the built-in gamepads' variables ($F5 and $F6)
OrPads:
	lda $00
	ora $f5
	sta $f5
	lda $01
	ora $f6
	sta $f6
	rts
	
.res $ea1f - *, $ff
ReadOrDownPads:
	JSR ReadPads
	JSR OrPads
	; fall through to detection

DetectUpToDownTransitions:
	LDX #1 ; handle pad #2 first
DetectUpToDownOnePad:
	LDA $F5,X ; load current joypad state
	TAY ; preserve the current state in Y
	EOR $F7,X ; exclusive-OR between previous and current state says which buttons have changed
	AND $F5,X ; AND of that with current state says which buttons have changed to down
	STA $F5,X ; save up-down transitions
	STY $F7,X ; overwrite previous state with current state via temporary
	DEX
	BPL DetectUpToDownOnePad ; when X underflows to -127, this branch will not be taken
	RTS

.res $f000 - *, $ff
DoFileShit:
	ldy #$ff
HandleNextFile:
	iny
	cpy #20
	bcs LoadedFiles
	lda ($0a),y
	cmp #$ff
	bne StartFileList
LoadedFiles:
	rts
SaveFileStub:
	jmp SaveFile
StartFileList:
	ldx #EndFileList-FileList-1
CheckFileList:
	cmp FileList,x
	beq LoadCurrentFile
	dex
	bpl	CheckFileList
	bmi HandleNextFile
LoadCurrentFile:
	cmp #$06
	beq SaveFileStub
	lda FileLenLow,x
	sta $04
	lda FileLenHigh,x
	sta $05
	lda FileSrcBank,x
	sta $06
	lda FileSrcLow,x
	sta $00
	lda FileSrcHigh,x
	sta $01
	lda FileDestLow,x
	sta $02
	lda FileDestHigh,x
	cmp #$40
	bcc CHRFile
	pha
	and #%00011111
	ora #%01100000
	sta $03
	pla
	lsr
	lsr
	lsr
	lsr
	lsr
	sec
	sbc #$03
	sta $07
	tya
	pha
	jsr LoadPRG
	pla
	tay
	jmp HandleNextFile
CHRFile:
	sta $03
	tya
	pha
	lda $06				;bank to source CHR from
	sta MMC5_PRG_C000
	ldx #$00      ; clear indices
  	ldy #$00      ; starting index into the first page
  	sty PPU_MASK  ; turn off rendering just in case
	lda PPU_STATUS
	lda $03
  	sta PPU_ADDR  ; load the destination address into the PPU
	lda $02
  	sta PPU_ADDR
loop:
	cpx $05				;high byte of length
	bcc do
	cpy $04				;low byte of length
	bcc do
	lda #$03			;restore correct banks and leave
    sta MMC5_PRG_C000
	jmp done
do:
  	lda ($00),y  ; copy one byte
  	sta PPU_DATA
  	iny
  	bne loop  ; repeat until we finish the page
	inx
  	inc $01
	inc $03
  	bne loop  ; repeat until we've copied enough pages
done:
	pla
	tay
	jmp HandleNextFile
SaveFile:
		ldx #$05
:		lda $5c00,x
		sta $6600,x
		dex
		bpl :-
		jmp HandleNextFile

FileList:
	.byte $01,$02,$06,$10,$11,$12,$13,$20,$21,$22,$23,$24,$30,$31,$32,$33,$34,$35,$36,$37,$40,$a0,$c0,$d0,$d1,$e0
EndFileList:
FileSrcLow:
	.byte $00,$00,$00,$05,$45,$85,$c5,$05,$00,$00,$00,$05,$14,$00,$00,$00,$00,$00,$00,$00,$06,$00,$c0,$00,$00,$06
FileSrcHigh:
	.byte $c0,$c0,$c6,$c6,$c9,$cc,$cf,$d5,$c0,$ca,$d4,$d3,$c8,$c0,$d2,$c4,$d6,$c8,$da,$c0,$c0,$c6,$c0,$c0,$c0,$c6
FileSrcBank:
	.byte $85,$81,$80,$87,$87,$87,$87,$87,$88,$88,$88,$87,$89,$8a,$8a,$8b,$8b,$8c,$8c,$89,$87,$89,$c0,$86,$80,$80
FileDestLow:
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$79,$06,$00,$00,$00
FileDestHigh:
	.byte $00,$60,$66,$00,$00,$00,$00,$0e,$0e,$0e,$0e,$18,$bf,$bf,$bf,$bf,$bf,$bf,$bf,$c1,$60,$d6,$66,$0e,$60,$b8
FileLenLow:
	.byte $f0,$00,$06,$40,$40,$40,$40,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$ff,$14,$06,$00,$00,$00
FileLenHigh:
	.byte $1f,$80,$00,$03,$03,$03,$03,$0a,$0a,$0a,$0a,$02,$12,$12,$12,$12,$12,$12,$12,$06,$05,$02,$00,$0c,$06,$19

LoadPRG:
	ldx #$00			;init indices for PRG loading
	ldy #$00
UpdateBanks:
	lda $06				;bank to source PRG from
	sta MMC5_PRG_C000
	lda $07				;bank to write PRG to
	sta MMC5_PRG_6000
	lda #$00			;flag for updating banks
	sta $0c
PRGLoop:
	lda $01				;has source gone past $C000-$DFFF?
	cmp #$e0
	bcc SrcInRange		;no, branch
	sbc #$20			;otherwise subtract $20 from high byte
	sta $01
	inc $06				;increment for next source bank
	inc $0c				;mark flag to update banks
SrcInRange:
	lda $03				;has destination gone past $8000-$9FFF?
	cmp #$80
	bcc DestInRange		;no, branch
	sbc #$20			;otherwise subtract $20 from high byte
	sta $03
	inc $07				;increment for next destination bank
	inc $0c				;mark flag to update banks
DestInRange:
	cpx $05				;high byte of length
	bcc DoNextByte
	cpy $04				;low byte of length
	bcc DoNextByte
	lda #$03			;restore correct banks and leave
    sta MMC5_PRG_C000
    lda #$00
    sta MMC5_PRG_6000
	rts
DoNextByte:
	lda $0c				;did we need to update the banks?
	bne UpdateBanks		;yes, branch to do so
	lda ($00),y         ;copy byte from ROM
	sta ($02),y         ;store in PRG-RAM
	iny
	bne PRGLoop         ;loop until page is finished
	inx
	inc $01             ;increment for next page
	inc $03
	bne PRGLoop
	
.res $f4cc - *, $ff
WhirlwindManuPatch:
	lda $012f
	cmp #$ab
	beq :+
	jsr ReadPads
	lda $00
	ora $f5
	and #$10
	beq :++
	lda #$ab
	sta $012f
:	clc
	rts
:	sec
	rts
	
.res $fffa - *, $ff
    .word FDSBIOS_NMI
    .word Reset
    .word FDSBIOS_IRQ
