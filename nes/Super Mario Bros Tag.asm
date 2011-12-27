    .export RESET, NMI, IRQ
    .segment "ZEROPAGE": zeropage
PointerLo:
    .res $01

PointerHi:
    .res $01

    .segment "CODE"
Move:
    BCC Decrease
    INC SpriteLocation, x    ; Increment coordinate
    JMP Increase

Decrease:
    DEC SpriteLocation, x    ; Decrement coordinate

Increase:
    INX
    INX
    INX
    INX         ; Go to next sprite
    DEY         ; Decrement sprite counter
    BNE Move    ; Do for all sprites
    RTS

ReadControllers:
    LDX #$01
    STX Buttons
    STX Buttons + 1
    STX $4016
    DEX
    STX $4016    ; tell both the controllers to latch Buttons
    INX

ReadControllersLoop:
    LDA $4016, x
    LSR A                         ; bit0 -> Carry
    ROL Buttons, x                ; bit0 <- Carry
    BCC ReadControllersLoop
    DEX
    BEQ ReadControllersLoop
    RTS

vblankwait:    ; First wait for vblank to make sure PPU is ready
    BIT $2002
    BPL vblankwait
    RTS

RESET:
    SEI               ; disable IRQs
    CLD               ; disable decimal mode
    LDX #$40
    STX $4017        ; disable APU frame IRQ
    LDX #$FF
    TXS               ; Set up STAck
    INX               ; now X = 0
    STX $2000         ; disable NMI
    STX $2001         ; disable rendering
    STX $4010         ; disable DMC IRQs
    JSR vblankwait

clrmem:
    LDA #$00
    STA $0000, x
    STA $0100, x
    STA $0300, x
    STA $0400, x
    STA $0500, x
    STA $0600, x
    STA $0700, x
    LDA #$FE
    STA SpriteLocation, x    ; move all sprites off screen
    INX
    BNE clrmem
    JSR vblankwait

LoadPalettes:
    LDA $2002    ; read PPU STAtus to reset the high/low latch to high
    LDA #$3F
    STA $2006    ; write the high byte of $3F00 address
    LDX #$00
    STX $2006    ; write the low byte of $3F00 address

LoadPalettesLoop:
    LDA Palettes, x         ; load data from address (Palettes + the value in x)
    STA $2007               ; write to PPU
    INX                     ; X = X + 1
    CPX PaletteTotal        ; Compare with number of items
    BNE LoadPalettesLoop    ; Branch to LoadPalettesLoop if compare was Not Equal to zero

LoadBackground:
    LDA $2002    ; read PPU STAtus to reset the high/low latch
    LDA #$20
    STA $2006    ; write the high byte of $2000 address
    LDX #$00
    STX $2006    ; write the low byte of $2000 address
    LDA #$00
    STA PointerLo              ; put the low byte of the address of background into pointer
    LDA #.hibyte(Background)
    STA PointerHi              ; put the high byte of the address into pointer
    LDX #$00                   ; start at pointer + 0
    LDY #$00

LoadBackgroundLoop:
    LDA (PointerLo), y        ; copy one background byte from address in pointer plus Y
    STA $2007                 ; this runs 256 * 4 times
    INY                       ; inside loop counter
    CPY #$00
    BNE LoadBackgroundLoop    ; run the inside loop 256 times before continuing down
    INC PointerHi             ; low byte went 0 to 256, so high byte needs to be changed now
    INX
    CPX #$04
    BNE LoadBackgroundLoop    ; run the outside loop 256 times before continuing down

LoadAttribute:
    LDA $2002                ; read PPU STAtus to reset the high/low latch
    LDA #$23
    STA $2006                ; write the high byte of $23C0 address
    LDA #$C0
    STA $2006                ; write the low byte of $23C0 address
    LDX #$00                 ; Start out at 0
    LoadAttributeLoop:
    LDA Attribute, x         ; load data from address (attribute + the value in x)
    STA $2007                ; write to PPU
    INX                      ; X = X + 1
    CPX AttributeTotal       ; Compare X to hex $08, decimal 8 - copying 8 bytes
    BNE LoadAttributeLoop

LoadSprites:
    LDX #$00    ; Start at 0

LoadSpritesLoop:
    LDA Sprites, x         ; load data from address (sprites + x)
    STA SpriteLocation, x         ; store into RAM address ($0200 + x)
    INX                    ; X = X + 1
    CPX SpriteTotal        ; Compare with number of items
    BNE LoadSpritesLoop    ; Branch to LoadSpritesLoop if compare was Not Equal to zero

Setup:
    LDA #%10010000    ; enable NMI, sprites from Pattern Table 0, background from Pattern 1
    STA $2000
    LDA #%00011110    ; enable sprites, enable background, no clipping on left side
    STA $2001

Forever:
    JMP Forever    ;jump back to Forever, infinite loop

NMI:
    LDA #$00
    STA $2003    ; set the low byte (00) of the RAM address
    LDA #$02
    STA $4014    ; set the high byte (02) of the RAM address, Start the transfer

Controller:
    JSR ReadControllers
    LDA Buttons
    AND #%00001000
    BEQ ReadDown
    LDX #$0
    LDY #4
    CLC
    JSR Move

ReadDown:
    LDA Buttons
    AND #%00000100
    BEQ ReadLeft
    LDX #$0
    LDY #4
    SEC
    JSR Move

ReadLeft:
    LDA Buttons
    AND #%00000010
    BEQ ReadRight
    LDX #$3
    LDY #4
    CLC
    JSR Move

ReadRight:
    LDA Buttons
    AND #%00000001
    BEQ Controller2
    LDX #$3
    LDY #4
    SEC
    JSR Move

Controller2:
    LDA Buttons2
    AND #%00001000
    BEQ ReadDown2
    LDX #$10
    LDY #4
    CLC
    JSR Move

ReadDown2:
    LDA Buttons2
    AND #%00000100
    BEQ ReadLeft2
    LDX #$10
    LDY #4
    SEC
    JSR Move

ReadLeft2:
    LDA Buttons2
    AND #%00000010
    BEQ ReadRight2
    LDX #$13
    LDY #4
    CLC
    JSR Move

ReadRight2:
    LDA Buttons2
    AND #%00000001
    BEQ Read
    LDX #$13
    LDY #4
    SEC
    JSR Move

Read:
    LDA #$00
    STA $2005
    STA $2005
    RTI

IRQ:

Attribute:
    .byte %00000000, %00010000, %01010000, %00010000
    .byte %00000000, %00000000, %00000000, %00110000
    .byte %00000000, %00010000, %01010000, %00010000
    .byte %00000000, %00000000, %00000000, %00110000
    .byte %00000000, %00010000, %01010000, %00010000
    .byte %00000000, %00000000, %00000000, %00110000
    .byte %00000000, %00010000, %01010000, %00010000
    .byte %00000000, %00000000, %00000000, %00110000
    .byte %00000000, %00010000, %01010000, %00010000
    .byte %00000000, %00000000, %00000000, %00110000
    .byte %00000000, %00010000, %01010000, %00010000
    .byte %00000000, %00000000, %00000000, %00110000
    .byte %00000000, %00010000, %01010000, %00010000
    .byte %00000000, %00000000, %00000000, %00110000
    .byte %00000000, %00010000, %01010000, %00010000
    .byte %00000000, %00000000, %00000000, %00110000

AttributeTotal:
    .byte $40

    .align $0100
Background:
    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24    ; row 1
    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24    ; all sky ($24 = sky)

    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24    ; row 2
    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24    ; all sky

    .byte $24, $24, $24, $24, $45, $45, $24, $24, $45, $45, $45, $45, $45, $45, $24, $24    ; row 3
    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $53, $54, $24, $24    ; some brick tops

    .byte $24, $24, $24, $24, $47, $47, $24, $24, $47, $47, $47, $47, $47, $47, $24, $24    ; row 4
    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $55, $56, $24, $24    ; brick bottoms

    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24    ; row 2
    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24    ; all sky

    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24    ; row 2
    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24    ; all sky

    .byte $24, $24, $24, $24, $45, $45, $24, $24, $45, $45, $45, $45, $45, $45, $24, $24    ; row 3
    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $53, $54, $24, $24    ; some brick tops

    .byte $24, $24, $24, $24, $47, $47, $24, $24, $47, $47, $47, $47, $47, $47, $24, $24    ; row 4
    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $55, $56, $24, $24    ; brick bottoms

    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24    ; row 1
    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24    ; all sky ($24 = sky)

    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24    ; row 2
    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24    ; all sky

    .byte $24, $24, $24, $24, $45, $45, $24, $24, $45, $45, $45, $45, $45, $45, $24, $24    ; row 3
    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $53, $54, $24, $24    ; some brick tops

    .byte $24, $24, $24, $24, $47, $47, $24, $24, $47, $47, $47, $47, $47, $47, $24, $24    ; row 4
    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $55, $56, $24, $24    ; brick bottoms

    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24    ; row 2
    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24    ; all sky

    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24    ; row 2
    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24    ; all sky

    .byte $24, $24, $24, $24, $45, $45, $24, $24, $45, $45, $45, $45, $45, $45, $24, $24    ; row 3
    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $53, $54, $24, $24    ; some brick tops

    .byte $24, $24, $24, $24, $47, $47, $24, $24, $47, $47, $47, $47, $47, $47, $24, $24    ; row 4
    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $55, $56, $24, $24    ; brick bottoms

    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24    ; row 1
    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24    ; all sky ($24 = sky)

    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24    ; row 2
    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24    ; all sky

    .byte $24, $24, $24, $24, $45, $45, $24, $24, $45, $45, $45, $45, $45, $45, $24, $24    ; row 3
    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $53, $54, $24, $24    ; some brick tops

    .byte $24, $24, $24, $24, $47, $47, $24, $24, $47, $47, $47, $47, $47, $47, $24, $24    ; row 4
    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $55, $56, $24, $24    ; brick bottoms

    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24    ; row 2
    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24    ; all sky

    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24    ; row 2
    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24    ; all sky

    .byte $24, $24, $24, $24, $45, $45, $24, $24, $45, $45, $45, $45, $45, $45, $24, $24    ; row 3
    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $53, $54, $24, $24    ; some brick tops

    .byte $24, $24, $24, $24, $47, $47, $24, $24, $47, $47, $47, $47, $47, $47, $24, $24    ; row 4
    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $55, $56, $24, $24    ; brick bottoms

    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24    ; row 1
    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24    ; all sky ($24 = sky)

    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24    ; row 2
    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24    ; all sky

    .byte $24, $24, $24, $24, $45, $45, $24, $24, $45, $45, $45, $45, $45, $45, $24, $24    ; row 3
    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $53, $54, $24, $24    ; some brick tops

    .byte $24, $24, $24, $24, $47, $47, $24, $24, $47, $47, $47, $47, $47, $47, $24, $24    ; row 4
    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $55, $56, $24, $24    ; brick bottoms

    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24    ; row 2
    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24    ; all sky

    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24    ; row 2
    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24    ; all sky

    .byte $24, $24, $24, $24, $45, $45, $24, $24, $45, $45, $45, $45, $45, $45, $24, $24    ; row 3
    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $53, $54, $24, $24    ; some brick tops

    .byte $24, $24, $24, $24, $47, $47, $24, $24, $47, $47, $47, $47, $47, $47, $24, $24    ; row 4
    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $55, $56, $24, $24    ; brick bottoms

Palettes:
    .byte $22, $29, $1A, $0F, $22, $36, $17, $0F, $22, $30, $21, $0F, $22, $27, $17, $0F    ; background palette
    .byte $22, $1C, $15, $14, $22, $02, $38, $3C, $22, $1C, $15, $14, $22, $02, $38, $3C    ; sprite palette

PaletteTotal:
    .byte $20

Sprites:
    ; vert, tile, attr, horiz
    .byte $70, $32, %00000000, $20
    .byte $70, $41, %00000000, $28
    .byte $78, $42, %00000000, $20
    .byte $78, $43, %00000000, $28
    .byte $70, $32, %01000000, $C8
    .byte $70, $41, %01000000, $C0
    .byte $78, $42, %01000000, $C8
    .byte $78, $43, %01000000, $C0

SpriteTotal:
    .byte $20

    .segment "BSS"
SpriteLocation:
    .res $0100

Buttons:
    .byte %00000000

Buttons2:
    .byte %00000000

    .segment "CHR"
    .incbin "mario.chr"