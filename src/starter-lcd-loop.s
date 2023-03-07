PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003
T1CL = $6004
T1CH = $6005
ACR = $600B
IFR = $600D
IER = $600E

; LCD setup
E  = %01000000      ; enable
RW = %00100000      ; read/write
RS = %00010000      ; ready to send

ticks = $00     ; 4 bytes

  .org $8000
  
reset:
  ldx #$ff          ; set stack pointer
  txs
  
  ; LCD setup
  lda #%11111111 ; Set all pins on port B to output
  sta DDRB
  lda #%00000000 ; Set all pins on port A to input
  sta DDRA

  jsr lcd_init
  lda #%00101000 ; Set 4-bit mode; 2-line display; 5x8 font
  jsr lcd_instruction
  lda #%00001110 ; Display on; cursor on; blink off
  jsr lcd_instruction
  lda #%00000110 ; Increment and shift cursor; don't shift display
  jsr lcd_instruction
  lda #%00000001 ; Clear display
  jsr lcd_instruction
  
  
  jsr init_timer    ; start tick timer

  
  ldx #0
print:
  lda message,x     ; set z to zero if message,x is null char else set z to 1
  beq loop          ; branch if z=0
  jsr print_char
  inx
  jmp print

  
loop:
  nop
  nop
  nop
  nop
  nop
  jmp loop
  


;------------------------------------------------------------
; start of 4 wire LCD subroutines
; use print routine above to print the
; message string to the LCD
; PB6 to E
; PB5 to RW
; PB4 to RS
; PB0 to PB3 on the VIA to D4 ot D7  on the LCD
;------------------------------------------------------------

message: .asciiz "Hello, world!"

lcd_wait:
  pha
  lda #%11110000  ; LCD data is input
  sta DDRB
lcdbusy:
  lda #RW
  sta PORTB
  lda #(RW | E)
  sta PORTB
  lda PORTB       ; Read high nibble
  pha             ; and put on stack since it has the busy flag
  lda #RW
  sta PORTB
  lda #(RW | E)
  sta PORTB
  lda PORTB       ; Read low nibble
  pla             ; Get high nibble off stack
  and #%00001000
  bne lcdbusy

  lda #RW
  sta PORTB
  lda #%11111111  ; LCD data is output
  sta DDRB
  pla
  rts

lcd_init:
  lda #%00000010 ; Set 4-bit mode
  sta PORTB
  ora #E
  sta PORTB
  and #%00001111
  sta PORTB
  rts

lcd_instruction:
  jsr lcd_wait
  pha
  lsr
  lsr
  lsr
  lsr            ; Send high 4 bits
  sta PORTB
  ora #E         ; Set E bit to send instruction
  sta PORTB
  eor #E         ; Clear E bit
  sta PORTB
  pla
  and #%00001111 ; Send low 4 bits
  sta PORTB
  ora #E         ; Set E bit to send instruction
  sta PORTB
  eor #E         ; Clear E bit
  sta PORTB
  rts

print_char:
  jsr lcd_wait
  pha
  lsr
  lsr
  lsr
  lsr             ; Send high 4 bits
  ora #RS         ; Set RS
  sta PORTB
  ora #E          ; Set E bit to send instruction
  sta PORTB
  eor #E          ; Clear E bit
  sta PORTB
  pla
  and #%00001111  ; Send low 4 bits
  ora #RS         ; Set RS
  sta PORTB
  ora #E          ; Set E bit to send instruction
  sta PORTB
  eor #E          ; Clear E bit
  sta PORTB
  rts
  
; ---------------------------------------
; end of lcd subroutines
;----------------------------------------
  
init_timer:
  lda #0
  sta ticks
  sta ticks + 1
  sta ticks + 2
  sta ticks + 3
  lda #%01000000
  sta ACR
  lda #$0e          ; 1Mhz 10ms
  ; lda #$3e
  sta T1CL
  lda #$27          ; 1Mhz 10ms
  ; lda #$9c
  sta T1CH
  lda #%11000000
  sta IER
  cli               ; clear interupt inhibit
  rts
  
irq:
  bit T1CL          ; reset interupt
  inc ticks
  bne end_irq
  inc ticks + 1
  bne end_irq
  inc ticks + 2
  bne end_irq
  inc ticks + 3
end_irq:
  rti
 
nmi:
  rti
  
; Reset/IRQ vectors  
  .org $fffa
  .word nmi
  .word reset
  .word irq
