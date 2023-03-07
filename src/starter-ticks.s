PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003
T1CL = $6004
T1CH = $6005
ACR = $600B
IFR = $600D
IER = $600E

ticks = $00     ; 4 bytes

  .org $8000
  
reset:
  ldx #$ff          ; set stack pointer
  txs
  
  jsr init_timer 
  
loop:
  nop
  nop
  nop
  nop
  nop
  jmp loop
  
init_timer:
  lda #0
  sta ticks
  sta ticks + 1
  sta ticks + 2
  sta ticks + 3
  lda #%01000000
  sta ACR
  lda #$0e          ; 1Mhz 10ms
  ; lda #$3e        ; 4Mhz 10ms
  sta T1CL
  lda #$27          ; 1Mhz 10ms
  ; lda #$9c        ; 4Mhz 10ms
  sta T1CH
  lda #%11000000
  sta IER
  cli               ; clear interupt inhibit
  rts
  
irq:
  bit T1CL          ; reset interupt
  inc ticks         ; set z to zero if ticks is zero else set z to 1
  bne end_irq       ; branch if z!=0
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
