    ; Luke Groesbeck
    ; RCET3373
    ; ISRs
    ; https://github.com/groeluke/Lab_5_Interrupt_Service_Routines/tree/main/LAB_5_Part_3_Interrupt.X
    
; PIC16F883 Configuration Bit Settings

; Assembly source line config statements

; CONFIG1
  CONFIG  FOSC = XT             ; Oscillator Selection bits (XT oscillator: Crystal/resonator on RA6/OSC2/CLKOUT and RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  MCLRE = ON            ; RE3/MCLR pin function select bit (RE3/MCLR pin function is MCLR)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF             ; Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

; config statements should precede project file includes.
#include <xc.inc>
   W_TEMP      EQU 0x70 ;use data memory address 0x70 will hold W during the ISR  
   STATUS_TEMP EQU 0x71 ;use data memory address 0x71 holds swapped STATUS during the ISR
   RB_OLD      EQU 0x72 ;last know PORTB value
   RB_NEW      EQU 0x73 ;PORTB value read this ISR entry
   RB_CHANGED  EQU 0x74 ;XOR result = bits that changed

; Reset Vector at 0000h. Execution starts here after reset.
PSECT resetVect,class=CODE,delta=2
ResetVector: 
    GOTO Setup

; Interrupt Vector at 0004h. Execution starts here after an interrupt.
PSECT isrVect,class=CODE,delta=2
InterruptVector:
    GOTO ISRHandler
   
; Main code section starts at 0008h. User code goes here.
PSECT code,class=CODE,delta=2
 
Setup: 
    ;          Bank 1
    BANKSEL TRISA
    CLRF    TRISA        ;Set RA's as output for monitoring binary count
    CLRF    TRISC        ;PORTC left as before but not used
    MOVLW   0xFF
    MOVWF   TRISB        ;set all of PORTB inputs
    MOVLW   0xFF
    MOVWF   IOCB         ;enable IOC on RB0-RB7
    
    ;          Bank 3
    BANKSEL ANSEL
    CLRF    ANSEL        ;set PortA as digital I/O
    CLRF    ANSELH       ;set PortB as digital I/O

    ;          Bank 0
    BANKSEL PORTA
    CLRF    PORTA        ;monitor pin starts low
    MOVF    PORTB,W      ;initial comparison state
    MOVWF   RB_OLD       ;before enabling the interrupt
    BCF INTCON,0         ;clear change on PortB interrupt flag
    BSF INTCON,3         ;enable PortB change interrupt
    BSF INTCON,7         ;global enable

Main:
    GOTO Main

ISRHandler:
    ;         save
    MOVWF   W_TEMP           ;save W (no flags affected)
    SWAPF   STATUS,W         ;STATUS into W with nibbles swapped, no flags change
    MOVWF   STATUS_TEMP      ;save swapped STATUS
    ;         
    BANKSEL PORTB            ;bank 0 covers PORTB, PORTA, PB_OLD/NEW/CHANGED, INTCON

    BTFSS   INTCON,0         ;RBIF set?
    GOTO    ISRExit          ;no, nothing to do

    ;         read current PORTB and find what changed
    MOVF    PORTB,W          ;W will be the current PORTB
    MOVWF   RB_NEW           ;save it, you'll need it twice
    XORWF   RB_OLD,W         ;W PB_NEW XOR PB_OLD changed bits
    MOVWF   RB_CHANGED

    ;         update the comparison state for next time
    MOVF    RB_NEW,W
    MOVWF   RB_OLD

    ;         determine which bit changed -- lowest pin wins
    BTFSC   RB_CHANGED,0     ;if RB0 is low skip GOTO next test
    GOTO    Pin0             ;if RB0 is high move the binary value to portA
    BTFSC   RB_CHANGED,1     ;if RB1 is low skip GOTO next test
    GOTO    Pin1             ;if RB1 is high move the binary value to portA
    BTFSC   RB_CHANGED,2     ;if RB2 is low skip GOTO next test
    GOTO    Pin2             ;if RB2 is high move the binary value to portA
    BTFSC   RB_CHANGED,3     ;if RB3 is low skip GOTO next test
    GOTO    Pin3             ;if RB3 is high move the binary value to portA
    BTFSC   RB_CHANGED,4     ;if RB4 is low skip GOTO next test
    GOTO    Pin4             ;if RB4 is high move the binary value to portA
    BTFSC   RB_CHANGED,5     ;if RB5 is low skip GOTO next test
    GOTO    Pin5             ;if RB5 is high move the binary value to portA
    BTFSC   RB_CHANGED,6     ;if RB6 is low skip GOTO next test
    GOTO    Pin6             ;if RB6 is high move the binary value to portA
    BTFSC   RB_CHANGED,7     ;if RB7 is low skip GOTO next test
    GOTO    Pin7             ;if RB7 is high move the binary value to portA
    GOTO    IOC_Done         ;RB_CHANGED was 0 to be safe

Pin0:   
    MOVLW   0x00             ;move 000 to PortA
    GOTO    SetPin
Pin1:   
    MOVLW   0x01             ;move 001 to PortA
    GOTO    SetPin
Pin2:
    MOVLW   0x02             ;move 010 to PortA
    GOTO    SetPin
Pin3:
    MOVLW   0x03             ;move 011 to PortA
    GOTO    SetPin
Pin4:
    MOVLW   0x04             ;move 100 to PortA
    GOTO    SetPin
Pin5:
    MOVLW   0x05             ;move 101 to PortA
    GOTO    SetPin
Pin6:
    MOVLW   0x06             ;move 110 to PortA
    GOTO    SetPin
Pin7:
    MOVLW   0x07             ;move 111 to PortA

SetPin:
    MOVWF   PORTA            ;display the value in binary

IOC_Done:
    BCF     INTCON,0         ;clear RBIF PORTB was already re-read
    
ISRExit:
    ;         restore
    SWAPF   STATUS_TEMP,W    ;un-swap STATUS into W
    MOVWF   STATUS           ;restores flags AND bank bits (RP0/RP1)
    SWAPF   W_TEMP,F         ;swap W_TEMP nibbles in place
    SWAPF   W_TEMP,W         ;swap back into W, STATUS untouched
    RETFIE
    
    End
    