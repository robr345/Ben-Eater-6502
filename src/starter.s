; starter assembler file for the 6502

; 6522 addresses
PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003


  .org $8000

reset:
  ; reset stack
  ldx #$ff
  txs

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
