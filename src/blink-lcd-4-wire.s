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

; zero page variables
ticks = $00     ; 4 bytes
toggle_time = $04
lcd_time = $05

; ram variables
value = $0200   ; 2 bytes
mod10 = $0202   ; 2 bytes
number = $0204
message = $0206 ; 6 bytes

  .org $8000
  
reset:
  ldx #$ff          ; set stack pointer
  txs
  
  ; LCD setup
  lda #%11111111 ; Set all pins on port A to output
  sta DDRA
  lda #%11111111 ; Set all pins on port B to output
  sta DDRB

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
  
  ; set variables to zero
  lda #0
  sta PORTA
  sta toggle_time
  sta lcd_time

  
loop:
  jsr update_led
  jsr update_lcd
  ; other stuff
  jmp loop


update_led:
  sec       ; set carry bit
  lda ticks
  sbc toggle_time
  cmp #25   ; have 250ms elapsed
  bcc exit_update_led  ; branch if carry clear
  lda #$01
  eor PORTA
  sta PORTA ; toggle LED
  lda ticks
  sta toggle_time
exit_update_led:
  rts

update_lcd:
  sec
  lda ticks
  sbc lcd_time
  cmp #100      ; has 1s elapsed
  bcc skip_lcd
  sei           ; set interupt inhibit
  lda ticks
  sta number
  lda ticks + 1
  sta number + 1
  cli               ; clear interupt inhibit
  lda #%00000001    ; clear display
  jsr lcd_instruction
  jsr lcd_print_num
  lda ticks
  sta lcd_time
skip_lcd:
  rts


;------------------------------------------------------------
; start of 4 wire LCD subroutines
; use print routine above to print the
; message string to the LCD
; PB6 to E
; PB5 to RW
; PB4 to RS
; PB0 to PB3 on the VIA to D4 ot D7  on the LCD
;------------------------------------------------------------

lcd_wait:
  pha
  lda #%11110000  ; LCD data is input
  sta DDRB
lcd_busy:
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
  bne lcd_busy

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

lcd_print_char:
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
  

; -----------------------------------------------------------------
; convert a binary number to decimal and print it to the lcd
; -----------------------------------------------------------------

lcd_print_num:  
  lda #0
  sta message
  
  ; Initialize value to be the number to convert
  lda number
  sta value
  lda number + 1
  sta value + 1

lcd_divide:  
  ; Initialize the remainder to zero
  lda #0
  sta mod10
  sta mod10 + 1
  clc
  
  ldx #16
lcd_divloop:
  ; Rotate quotent and remainder
  rol value
  rol value + 1
  rol mod10
  rol mod10 + 1
  
  ; a,y = dividend - divisor
  sec
  lda mod10
  sbc #10
  tay   ; save low byte in Y
  lda mod10 + 1
  sbc #0
  bcc lcd_ignore_result ; branch if dividend < devisor
  sty mod10
  sta mod10 + 1
  
lcd_ignore_result:
  dex
  bne lcd_divloop
  rol value ; shift in the last bit of the quotient
  rol value + 1
  
  lda mod10
  clc
  adc #"0"
  jsr lcd_push_char
  
  ; if value != 0, then continue dividing
  lda value
  ora value + 1
  bne lcd_divide    ; branch if value no zero
  
  ldx #0
lcd_print_message:
  lda message,x
  beq lcd_print_finished
  jsr lcd_print_char
  inx
  jmp lcd_print_message

lcd_print_finished:
  rts
  
; --------------------------------------------------------------------
; Add the character in the A register to the beginning of the 
; null-terminated string 'message'
;---------------------------------------------------------------------

lcd_push_char:
  pha   ; Push new first char onto stack
  ldy #0
  
lcd_message_loop:  
  lda message,y ; Get char on string and put into X
  tax
  pla
  sta message,y ; Pull char off stack and add it to the string
  iny
  txa
  pha           ; Push char from string onto stack
  bne lcd_message_loop
  
  pla
  sta message,y ; Pull the null of the stack and add to end of string
  
  rts
  
;------------------------------------------------------------------
  
init_timer:
  lda #0
  sta ticks
  sta ticks + 1
  sta ticks + 2
  sta ticks + 3
  lda #%01000000
  sta ACR
  ; lda #$0e          ; 1Mhz 10ms
  ; lda #$3e
  lda #$1c
  sta T1CL
  ; lda #$27          ; 1Mhz 10ms
  ; lda #$9c
  lda #$4e
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
