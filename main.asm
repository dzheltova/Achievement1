; AVR Assembler program for Atmega8 (Arduino) using two parallel timers, sending "ping\r\n" and "pong\r\n" through USART.

; Constants
.equ TIMER1_INTERVAL = 1000  
.equ TIMER2_INTERVAL = 2000  
TIMER1_STR: .db "ping", 13, 10, 0  
TIMER2_STR: .db "pong", 13, 10, 0 

; Initialize
_start:
 cli ; Disable interrupts

; Setup USART
 ldi r16, 207
 out UBRRL, r16
 ldi r16, 0
 out UBRRH, r16
 ldi r16, (1<<TXEN)
 out UCSRB, r16
 ldi r16, ((0<<USBS) | (3<<UCSZ0))
 out UCSRC, r16

; Setup timer1
 ldi r16, 0 ; Clear counter register (TCNT1)
 out TCNT1H, r16
 out TCNT1L, r16

 ldi r16, (TIMER1_INTERVAL & 0xFF)
 out OCR1AL, r16

 ldi r16, (TIMER1_INTERVAL >> 8)
 out OCR1AH, r16

 ldi r16, (1<<WGM12) | (1<<CS11) | (1<<CS10) ; CTC mode and prescaler = 64
 out TCCR1B, r16

 ldi r16, 1<<OCIE1A ; Enable TIMER1_INT
 out TIMSK, r16

; Setup timer2
 ldi r16, 0 ; Clear counter register (TCNT2)
 out TCNT2, r16

 ldi r16, (TIMER2_INTERVAL & 0xFF) ; Set Timer2 value
 out OCR2, r16

 ldi r16, (1<<WGM21) | (1<<CS22) ; CTC mode and prescaler = 64
 out TCCR2, r16

 ldi r16, 1<<OCIE2 ; Enable TIMER2_INT
 out TIMSK, r16

 sei ; Enable interrupts

main_loop:
 rjmp main_loop ; Infinite loop

; Timer1 interrupt service routine
TIMER1_INT: 
 push r16 ; Save r16 

 ldi ZL, low(TIMER1_STR) ; Clear counter register (TCNT1)
 ldi ZH, high(TIMER1_STR)
 
send_timer1:
 lpm r16, Z+
 cpi r16, 0
 breq TIMER1_done
 rcall send_usart
 rjmp send_timer1

TIMER1_done:
 pop r16 ; Restore r16 
 reti ; Return from interrupt

; Timer2 interrupt service routine
TIMER2_INT:
 push r16 ; Save r16 

 ldi ZL, low(TIMER2_STR) ; Clear counter register (TCNT1)
 ldi ZH, high(TIMER2_STR)

send_timer2:
 lpm r16, Z+
 cpi r16, 0
 breq TIMER2_done
 rcall send_usart
 rjmp send_timer2

TIMER2_done:
 pop r16 ; Restore r16 
 reti ; Return from interrupt

; USART send function
send_usart:
 out UDR, r16 ; Transmit byte
 wait_for_transmit:
 in r16, UCSRA ; Check if transmit complete
 sbrs r16, UDRE
 rjmp wait_for_transmit
 ret

; Interrupt vectors
 rjmp TIMER1_INT
 rjmp TIMER2_INT


; End of program

