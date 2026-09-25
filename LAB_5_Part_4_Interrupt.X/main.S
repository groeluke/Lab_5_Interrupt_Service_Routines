    ; Luke Groesbeck
    ; RCET3373
    ; ISRs
    ; https://github.com/groeluke/Lab_5_Interrupt_Service_Routines/tree/main/LAB_5_Part_4_Interrupt.X
    
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
   W_TEMP_A      EQU 0x70 ; 
   STATUS_TEMP_A EQU 0x71 ;
   W_TEMP_B      EQU 0x72 ;  
   STATUS_TEMP_B EQU 0x73 ;
   FLAGS         EQU 0x74 ;
   OLD_DISPLAY   EQU 0x75 ;
   
   maincount6    EQU 0x20 ;set the main delay for display 6
   outcount6     EQU 0x21 ;set the outter delay for display 6
   incount6      EQU 0x22 ;set the inner delay for display 6
   maincount7    EQU 0x23 ;set the main delay for diplay 7
   outcount7     EQU 0x24 ;set the outter delay for display 7
   incount7      EQU 0x25 ;set the inner delay for display 7

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
    CLRF    TRISC        ;PORTC set as outputs for display
    BSF     TRISB,0      ;set RB0 of PORTB to input
    BSF     TRISB,1      ;set RB1 of PORTB to input
    BSF     IOCB,1       ;enable IOC on RB1
    BCF     OPTION_REG,6 ;RBO/INT falling edge
    
    ;          Bank 3
    BANKSEL ANSEL
    CLRF    ANSEL        ;set PortC as digital I/O
    CLRF    ANSELH       ;set PortB as digital I/O

    ;          Bank 0
    BANKSEL PORTB
    MOVF    PORTB,W      ;initial comparison state
    CLRF FLAGS           ;start with nothing in the flags register
    BCF INTCON,0         ;clear change on PortB interrupt flag
    BCF INTCON,1         ;clear external interupt flag
    BSF INTCON,3         ;enable PortB change interrupt
    BSF INTCON,4         ;enable external interrupt bit
    BSF INTCON,7         ;enable global interrupt bit

Main:
    MOVLW 0x31      ;Select the character set for display 1
    MOVWF PORTC      ;Send W to PortC
    GOTO Main

ISRHandler:
    BTFSC FLAGS,0
    GOTO SaveOuterB
    
    SaveOuterA:
    MOVWF   W_TEMP_A         ;save W (no flags affected)
    SWAPF   STATUS,W         ;STATUS into W with nibbles swapped, no flags change
    MOVWF   STATUS_TEMP_A    ;save swapped STATUS
    GOTO    CheckSource
    
    SaveOuterB:
    MOVWF   W_TEMP_B         ;save W (no flags affected)
    SWAPF   STATUS,W         ;STATUS into W with nibbles swapped, no flags change
    MOVWF   STATUS_TEMP_B    ;save swapped STATUS
    
CheckSource:
    ;                  RB1 IOC = display 7
    BTFSS   INTCON,0         ;check the interrupt on change bit flag
    GOTO    CheckINT         ;if not set, check the other source
    
    ;           display 7
    MOVF    PORTB,W          ;dummy read - this is what actually clears the mismatch
    BCF     INTCON,0         ;clear the IOC flag right now
    MOVF    PORTC,W          ;grab whatever's currently displayed
    MOVWF   OLD_DISPLAY      ;this will be 1 or 6 depending on what 7 interrupted
    MOVLW   0x37
    MOVWF   PORTC            ;put 7 on the display
    BCF     INTCON,7         ;keep interrupts off during the delay
    CALL    LongDelay7       ;2 seconds, uninterruptible
    MOVF    OLD_DISPLAY,W    ;restore whatever was showing before 7 started
    MOVWF   PORTC
    GOTO    ISRExit
    
CheckINT:
    ;                  RBO PORTB change = display 6
    BTFSS   INTCON,1         ;check the external interrupt flag bit for priority
    GOTO    ISRExit          ;if yes make sure that we run the priority
    
;             display 6
    BCF     INTCON,1         ;clear external interrupt flag
    BTFSC   FLAGS,0          ;check if flag RB0 flag was set
    GOTO    ISRExit          ;if not leave
    MOVLW   0x36             ;move hex value for DLG7137 to display 6
    MOVWF   PORTC            ;display value on the DLG7137
    BSF     FLAGS,0          ;set the flag bit for interrupt
    BSF     INTCON,7         ;set global interrupt enable
    CALL    LongDelay6       ;call the delay and run before returning 2 sec
    BCF     FLAGS,0          ;clear flag before leaving
    GOTO    ISRExit
    
    ;         restore whichever slot we saved into
ISRExit:
    BTFSC   FLAGS,0          ; still inside 6's window? then THIS exit is 7's
    GOTO    RestoreInner     ; exit, and it must restore slot B, not slot A

RestoreOuter:
    SWAPF   STATUS_TEMP_A,W  ;restore
    MOVWF   STATUS
    SWAPF   W_TEMP_A,F
    SWAPF   W_TEMP_A,W
    RETFIE

RestoreInner:
    SWAPF   STATUS_TEMP_B,W
    MOVWF   STATUS
    SWAPF   W_TEMP_B,F
    SWAPF   W_TEMP_B,W
    RETFIE              

LongDelay6:
    MOVLW   0x43
    MOVWF   maincount6
MainDelayLoop6:
    MOVLW   0x32
    MOVWF   outcount6
OutDelayLoop6:
    CALL    ShortDelay6
    DECFSZ  outcount6,1
    GOTO    OutDelayLoop6
    DECFSZ  maincount6,1
    GOTO    MainDelayLoop6
    RETURN
ShortDelay6:
    MOVLW   0xC8
    MOVWF   incount6
InDelayLoop6:
    DECFSZ  incount6,1
    GOTO    InDelayLoop6
    RETURN

LongDelay7:
    MOVLW   0x22
    MOVWF   maincount7
MainDelayLoop7:
    MOVLW   0x32
    MOVWF   outcount7
OutDelayLoop7:
    CALL    ShortDelay7
    DECFSZ  outcount7,1
    GOTO    OutDelayLoop7
    DECFSZ  maincount7,1
    GOTO    MainDelayLoop7
    RETURN
ShortDelay7:
    MOVLW   0xC8
    MOVWF   incount7
InDelayLoop7:
    DECFSZ  incount7,1
    GOTO    InDelayLoop7
    RETURN

    End