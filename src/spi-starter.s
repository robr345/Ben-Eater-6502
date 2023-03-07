; 6522 addresses
PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003

SCK  = %00000001
MOSI = %00000010
CS   = %00000100
MISO = %01000000


  .org $8000

reset:
  ; reset stack
  ldx #$ff
  txs
  
  ; Initialize SPI
  lda #CS
  sta PORTA
  lda #%00000111
  sta DDRA
  
  ; Bit bank $d0 %11010000
  lda #MOSI
  sta PORTA
  lda #(SCK | MOSI)
  sta PORTA
  
  lda #MOSI
  sta PORTA
  lda #(SCK | MOSI)
  sta PORTA
  
  lda #0
  sta PORTA
  lda #SCK
  sta PORTA
  
  lda #MOSI
  sta PORTA
  lda #(SCK | MOSI)
  sta PORTA
  
  lda #0
  sta PORTA
  lda #SCK
  sta PORTA
  
  lda #0
  sta PORTA
  lda #SCK
  sta PORTA
  
  lda #0
  sta PORTA
  lda #SCK
  sta PORTA
  
  lda #0
  sta PORTA
  lda #SCK
  sta PORTA
  
  ; Bit bang 8 more clocks
  
  lda #0
  sta PORTA
  lda #SCK
  sta PORTA
  
  lda #0
  sta PORTA
  lda #SCK
  sta PORTA
  
  lda #0
  sta PORTA
  lda #SCK
  sta PORTA
  
  lda #0
  sta PORTA
  lda #SCK
  sta PORTA
  
  lda #0
  sta PORTA
  lda #SCK
  sta PORTA
  
  lda #0
  sta PORTA
  lda #SCK
  sta PORTA
  
  lda #0
  sta PORTA
  lda #SCK
  sta PORTA
  
  lda #0
  sta PORTA
  lda #SCK
  sta PORTA
  
  lda #CS
  sta PORTA


loop:
  nop
  nop
  nop
  nop
  nop
  jmp loop


  .org $fffc
  .word reset
  .word $0000
