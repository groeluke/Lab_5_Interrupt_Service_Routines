    ; Luke Groesbeck
    ; RCET3373
    ; Funky Muzak
    ; https://github.com/groeluke/Funky-Muzak/tree/main/LAB_4_Part_3_Muzak.X
    
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
   indexcount EQU 0x20 ;use data memory address 0x20 as an 8-bit loop counter  
   outcount EQU 0x21 ;use data memory address 0x21 as an 8-bit loop counter
   incount EQU 0x22 ;use data memory address 0x22 as an 8-bit loop counter
   highcount EQU 0x23 ;for memory address 0x23 to hold values of columns/rows
   lowcount EQU 0x24 ;for memory address 0x24 to hold values of columns/rows

; Reset Vector at 0000h. Execution starts here after reset.
PSECT resetVect,class=CODE,delta=2
ResetVector: 
    goto Setup


; Main code section starts at 0008h. User code goes here.
PSECT code,class=CODE,delta=2
 
Setup:
    ;       Bank 0
    BCF 0x03,6  ;Set Bank 0
    BCF 0x03,5  ;Set Bank 0
    CLRF 0x05   ;Setting PortA on reset low
    CLRF 0x06   ;Setting PortB on reset low known
    CLRF 0x07   ;Set PortC on reset to LOW
    
    ;       Bank 1
    BCF 0x03,6  ;Set Bank 1
    BSF 0x03,5  ;Set Bank 1
    CLRF 0x0B   ;Set INTCON low to remove interrupt flags 
    CLRF 0x87   ;Set PortC as an Output TRISC
    MOVLW 0xF0  ;Make RB0-RB3 outputs for the rows and RB4-RB7 inputs for the colums
    MOVWF 0x86  ;Setting PortB I/O from TRISB
    BCF 0x81,7  ; Make PortB have weak pull-ups OPTION_REG
    MOVLW 0x00
    MOVWF 0x85  ;TRISA set PortA as outputs
    
    ;       Bank 2
    ;BSF 0x03,6  ;Set Bank 2
    ;BCF 0x03,5  ;Set Bank 2
    BSF 0x09,1  ;Setting Bit 1 High for CM2CON1
    
    ;       Bank 3
    BSF 0x03,6  ;Set Bank 3
    BSF 0x03,5  ;Set Bank 3
    CLRF 0x88   ;Setting the I/O to digital ANSEL PortA
    CLRF 0x89   ;Setting the I/O to digital ANSELH PortB
    
    GOTO Main
    
    
    Main:
        ; main code goes here
	CALL SelectButton  ;Determine which switch is active
	
	MOVF indexcount,W  ;Check if no switch is active 
	BTFSC indexcount,7 ;if no keys are selected then goto silent 
	GOTO Silent
	
        CALL LookUp         ;Call to the Look up table and check which index is selected
        MOVWF outcount      ;Move the value to outcount for delay to play note
	
	CALL Delay          ;Call delay and play frequency for note selected
	
	MOVLW 0x01          ;Toggle RA0
	XORWF 0x05,1        ;Toggle TA0 
	
	GOTO Main
	
    Silent:
        BCF 0x05,0          ;Force RA0 low silence
	GOTO Main
	
SelectButton:
    CLRF highcount
    CLRF lowcount
    ;   Scan Row 4 (RB3)
    BCF 0x03,6      ;Set Bank 1
    BSF 0x03,5      ;Set Bank 1
    MOVLW 0xF7      ;RB3 output-low, rest input
    MOVWF 0x86      ;Send W to PortB
    BCF 0x03,6      ;Set Bank 0
    BCF 0x03,5      ;Set Bank 0
	
    BTFSS 0x06,4    ;Check Column 1 for *
    BSF highcount,6      ;Set test * high if selected
    BTFSS 0x06,5    ;Check Column 2 for 0
    BSF lowcount,0      ;Set test 0 high if selected
    BTFSS 0x06,6    ;Check Column 3 for #
    BSF highcount,7      ;Set test # high if selected
    BTFSS 0x06,7    ;Check Column 4 for D
    BSF highcount,5      ;Set test D high if selected
	
    ;   Scan Row 3 (RB2) 
    BCF 0x03,6      ;Set Bank 1
    BSF 0x03,5      ;Set Bank 1
    MOVLW 0xFB      ;RB2 output-low, rest input
    MOVWF 0x86      ;Send W to PortB
    BCF 0x03,6      ;Set Bank 0
    BCF 0x03,5      ;Set Bank 0

    BTFSS 0x06,4    ;Check Column 1 for 7
    BSF lowcount,7      ;Set test 7 high if selected
    BTFSS 0x06,5    ;Check Column 2 for 8
    BSF highcount,0      ;Set test 8 high if selected
    BTFSS 0x06,6    ;Check Column 3 for 9
    BSF highcount,1      ;Set test 9 high if selected
    BTFSS 0x06,7    ;Check Column 4 for C
    BSF highcount,4      ;Set test C high if selected
	
    ;   Scan Row 2 (RB1)
    BCF 0x03,6      ;Set Bank 1
    BSF 0x03,5      ;Set Bank 1
    MOVLW 0xFD      ;RB1 output-low, rest input
    MOVWF 0x86      ;Send W to PortB
    BCF 0x03,6      ;Set Bank 0
    BCF 0x03,5      ;Set Bank 0

    BTFSS 0x06,4    ;Check Column 1 for 4
    BSF lowcount,4      ;Set test 4 high if selected
    BTFSS 0x06,5    ;Check Column 2 for 5
    BSF lowcount,5      ;Set test 5 high if selected
    BTFSS 0x06,6    ;Check Column 3 for 6
    BSF lowcount,6      ;Set test 6 high if selected
    BTFSS 0x06,7    ;Check Column 4 for B
    BSF highcount,3      ;Set test B high if selected
	
    ;    Sacn Row 1 (RB0) 
    BCF 0x03,6   ;Set Bank 1
    BSF 0x03,5   ;Set Bank 1
    MOVLW 0xFE   ;RB0 output is low, RB1-RB7 input
    MOVWF 0x86   ;Send W to PortB
    BCF 0x03,6   ;Set Bank 0
    BCF 0x03,5   ;Set Bank 0

    BTFSS 0x06,4    ;Check Column 1 for 1
    BSF lowcount,1      ;Set test 1 high if selected
    BTFSS 0x06,5    ;Check Column 2 for 2
    BSF lowcount,2      ;Set test 2 high if selected
    BTFSS 0x06,6    ;Check Column 3 for 3
    BSF lowcount,3      ;Set test 3 high if selected
    BTFSS 0x06,7    ;Check Column 4 for A
    BSF highcount,2      ;Set test A high if selected

    GOTO TestD
TestD:
    BTFSS highcount,5    ;Test if D is pressed 
    GOTO TestHash      ;GOTO Test for #
    GOTO DisplayD   ;GOTO the Display for D
TestHash:
    BTFSS highcount,7    ;Test if # is pressed 
    GOTO Test0   ;GOTO Test for *
    GOTO DisplayHash;GOTO the Display for #
Test0:
    BTFSS lowcount,0    ;Test if 0 is pressed 
    GOTO TestStar ;GOTO the Display for *
    GOTO Display0   ;GOTO the Display for 0
TestStar:
    BTFSS highcount,6    ;Test if * is pressed 
    GOTO TestC      ;GOTO Test for C
    GOTO DisplayStar;GOTO the Display for * 
TestC:
    BTFSS highcount,4    ;Test if C is pressed 
    GOTO Test9      ;GOTO Test for 9
    GOTO DisplayC   ;GOTO the Display for C
Test9:
    BTFSS highcount,1    ;Test if 9 is pressed 
    GOTO Test8      ;GOTO Test for 8
    GOTO Display9   ;GOTO the Display for 9
Test8:
    BTFSS highcount,0    ;Test if 8 is pressed 
    GOTO Test7      ;GOTO Test for 7
    GOTO Display8   ;GOTO the Display for 8
Test7:
    BTFSS lowcount,7    ;Test if 7 is pressed 
    GOTO TestB      ;GOTO Test for B
    GOTO Display7   ;GOTO the Display for 7
TestB:
    BTFSS highcount,3    ;Test if B is pressed 
    GOTO Test6      ;GOTO Test for 6
    GOTO DisplayB   ;GOTO the Display for B
Test6:
    BTFSS lowcount,6    ;Test if 6 is pressed 
    GOTO Test5      ;GOTO Test for 5
    GOTO Display6   ;GOTO the Display for 6
Test5:
    BTFSS lowcount,5    ;Test if 5 is pressed 
    GOTO Test4      ;GOTO Test for 4
    GOTO Display5   ;GOTO the Display for 5
Test4:
    BTFSS lowcount,4    ;Test if 4 is pressed 
    GOTO TestA      ;GOTO Test for A
    GOTO Display4   ;GOTO the Display for 4
TestA:
    BTFSS highcount,2    ;Test if A is pressed 
    GOTO Test3      ;GOTO Test for 3
    GOTO DisplayA   ;GOTO the Display for A
Test3:
    BTFSS lowcount,3    ;Test if 3 is pressed 
    GOTO Test2      ;GOTO Test for 2
    GOTO Display3   ;GOTO the Display for 3
Test2:
    BTFSS lowcount,2    ;Test if 2 is pressed 
    GOTO Test1      ;GOTO Test for 1
    GOTO Display2   ;GOTO the Display for 2
Test1:
    BTFSS lowcount,1    ;Test if 1 is pressed 
    GOTO DisplayDal      ;GOTO the Display $
    GOTO Display1   ;GOTO the Display for 1
    
DisplayDal:
    MOVLW 0x80
    MOVWF indexcount
    MOVLW 0x24        ;Select the character set for display $ or whatever
    MOVWF 0x07        ;Send W to PortC
    RETURN
DisplayHash:
    MOVLW 0x0E        ;Move W into indexcount
    MOVWF indexcount  ;Send W to indextcount for index table
    MOVLW 0x23        ;Select the character set for display #
    MOVWF 0x07        ;Send W to PortC
    RETURN
DisplayStar:
    MOVLW 0x0C        ;Move W into indexcount
    MOVWF indexcount  ;Send W to indextcount for index table
    MOVLW 0x2A        ;Select the character set for display *
    MOVWF 0x07        ;Send W to PortC
    RETURN
DisplayD:
    MOVLW 0x0F        ;Move W into indexcount
    MOVWF indexcount  ;Send W to indextcount for index table
    MOVLW 0x44        ;Select the character set for display D
    MOVWF 0x07        ;Send W to PortC
    RETURN
DisplayC:
    MOVLW 0x0B        ;Move W into indexcount
    MOVWF indexcount  ;Send W to indextcount for index table
    MOVLW 0x43        ;Select the character set for display C
    MOVWF 0x07        ;Send W to PortC
    RETURN
DisplayB:
    MOVLW 0x07        ;Move W into indexcount
    MOVWF indexcount  ;Send W to indextcount for index table
    MOVLW 0x42        ;Select the character set for display B
    MOVWF 0x07        ;Send W to PortC
    RETURN
DisplayA:
    MOVLW 0x03        ;Move W into indexcount
    MOVWF indexcount  ;Send W to indextcount for index table
    MOVLW 0x41        ;Select the character set for display A
    MOVWF 0x07        ;Send W to PortC
    RETURN
Display9:
    MOVLW 0x0A        ;Move W into indexcount
    MOVWF indexcount  ;Send W to indextcount for index table
    MOVLW 0x39        ;Select the character set for display 9
    MOVWF 0x07        ;Send W to PortC
    RETURN
Display8:
    MOVLW 0x09        ;Move W into indexcount
    MOVWF indexcount  ;Send W to indextcount for index table 
    MOVLW 0x38        ;Select the character set for display 8
    MOVWF 0x07        ;Send W to PortC
    RETURN
Display7:
    MOVLW 0x08        ;Move W into indexcount
    MOVWF indexcount  ;Send W to indextcount for index table
    MOVLW 0x37        ;Select the character set for display 7
    MOVWF 0x07        ;Send W to PortC
    RETURN
Display6:
    MOVLW 0x06        ;Move W into indexcount
    MOVWF indexcount  ;Send W to indextcount for index table
    MOVLW 0x36        ;Select the character set for display 6
    MOVWF 0x07        ;Send W to PortC
    RETURN
Display5:
    MOVLW 0x05        ;Move W into indexcount
    MOVWF indexcount  ;Send W to indextcount for index table
    MOVLW 0x35        ;Select the character set for display 5
    MOVWF 0x07        ;Send W to PortC
    RETURN
Display4:
    MOVLW 0x04        ;Move W into indexcount
    MOVWF indexcount  ;Send W to indextcount for index table
    MOVLW 0x34        ;Select the character set for display 4
    MOVWF 0x07        ;Send W to PortC
    RETURN
Display3:
    MOVLW 0x02        ;Move W into indexcount
    MOVWF indexcount  ;Send W to indextcount for index table
    MOVLW 0x33        ;Select the character set for display 3
    MOVWF 0x07        ;Send W to PortC
    RETURN
Display2:
    MOVLW 0x01        ;Move W into indexcount
    MOVWF indexcount  ;Send W to indextcount for index table
    MOVLW 0x32        ;Select the character set for display 2
    MOVWF 0x07        ;Send W to PortC
    RETURN
Display1:
    MOVLW 0x00        ;Move W into indexcount
    MOVWF indexcount  ;Send W to indextcount for index table
    MOVLW 0x31        ;Select the character set for display 1
    MOVWF 0x07        ;Send W to PortC
    RETURN
Display0:
    MOVLW 0x0D        ;Move W into indexcount
    MOVWF indexcount  ;Send W to indextcount for index table
    MOVLW 0x30        ;Select the character set for display 0
    MOVWF 0x07        ;Send W to PortC
    RETURN
LookUp:
    MOVF indexcount,W
    ADDWF PCL,1   ;ADDWF PCL,F - jump into table below
    RETLW 0xEE    ;index 1 C3
    RETLW 0xD4    ;index 2 D3
    RETLW 0xBD    ;index 3 E3
    RETLW 0xB2    ;index 4 F3
    RETLW 0x9F    ;index 5 G3
    RETLW 0x8E    ;index 6 A3
    RETLW 0x7E    ;index 7 B3
    RETLW 0x77    ;index 8 C4
    RETLW 0x6A    ;index 9 D4
    RETLW 0x5E    ;index 10 E4
    RETLW 0x59    ;index 11 F4
    RETLW 0x4F    ;index 12 G4
    RETLW 0x47    ;index 13 A4
    RETLW 0x3F    ;index 14 B4
    RETLW 0x3B    ;index 15 C5
    RETLW 0x35    ;index 16 D5
Delay:
    OutLoop:
    MOVLW 0x04
    MOVWF incount
    InLoop:
    DECFSZ incount,1
    GOTO InLoop
    DECFSZ outcount,1
    GOTO OutLoop
    
    RETURN
	
    End