; VIA constants
PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003
T1CL = $6004
T1CH = $6005
ACR = $600B
IFR = $600D
IER = $600E

; lcd constants
E  = %10000000
RW = %01000000
RS = %00100000

; ram variables
value = $0200   ; 2 bytes
mod10 = $0202   ; 2 bytes
number = $0204
message = $0206 ; 6 bytes

; zero page variables
ticks = $00
toggle_time = $04
lcd_time = $05

  .org $8000

reset:
  ; reset stack pointer
  ldx #$ff
  txs
  ; set VIA pins
  lda #%11111111    ; Set all pins on port A to output
  sta DDRA
  lda #%11111111 ; Set all pins on port B to output
  sta DDRB
  ; initalize lcd
  lda #%00111000 ; Set 8-bit mode; 2-line display; 5x8 font
  jsr lcd_instruction
  lda #%00001110 ; Display on; cursor on; blink off
  jsr lcd_instruction
  lda #%00000110 ; Increment and shift cursor; don't shift display
  jsr lcd_instruction
  lda #$00000001 ; Clear display
  jsr lcd_instruction
  
  ; set variables to zero
  lda #0
  sta PORTA
  sta toggle_time
  sta lcd_time

  ; start interupt timer
  jsr init_timer


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

; ---------------------------------------------------------------------------------------------
; lcd functions
; ---------------------------------------------------------------------------------------------

lcd_print_char:
  jsr lcd_wait
  sta PORTB
  lda #RS         ; Set RS; Clear RW/E bits
  sta PORTA
  lda #(RS | E)   ; Set E bit to send instruction
  sta PORTA
  lda #RS         ; Clear E bits
  sta PORTA
  rts

lcd_instruction:
  jsr lcd_wait
  sta PORTB
  lda #0         ; Clear RS/RW/E bits
  sta PORTA
  lda #E         ; Set E bit to send instruction
  sta PORTA
  lda #0         ; Clear RS/RW/E bits
  sta PORTA
  rts

lcd_wait:
  pha
  lda #%00000000  ; Port B is input
  sta DDRB
lcd_busy:
  lda #RW
  sta PORTA
  lda #(RW | E)
  sta PORTA
  lda PORTB
  and #%10000000
  bne lcd_busy

  lda #RW
  sta PORTA
  lda #%11111111  ; Port B is output
  sta DDRB
  pla
  rts

; ----------------------------------------------------------------------------------------------
; convert a binary number to decimal and print it to the lcd
; ----------------------------------------------------------------------------------------------

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

; -----------------------------------------------------------------------------------------------
; start the ticks timer
;------------------------------------------------------------------------------------------------

init_timer:
  lda #0
  sta ticks
  sta ticks + 1
  sta ticks + 2
  sta ticks + 3
  lda #%01000000
  sta ACR
  ; lda #$0e        ; 1 Mhz 10ms
  lda #$9c          ; 4 Mhz 10ms
  sta T1CL
  ; lda #$27        ;1 Mhz 10ms
  lda #$9c          ;4 Mhz 10 ms
  sta T1CH
  lda #%11000000
  sta IER
  cli               ; clear interupt inhibit
  rts

; -----------------------------------------------------------------------------------------------
; interupt routine called every 10ms, to add 1 to ticks
;------------------------------------------------------------------------------------------------

irq:
  bit T1CL
  inc ticks
  bne end_irq
  inc ticks + 1
  bne end_irq
  inc ticks + 2
  bne end_irq
  inc ticks + 3
end_irq:
  rti


  .org $fffc
  .word reset
  .word irq
