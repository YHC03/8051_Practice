; R3(H, L) : 1, 2nd Segment(Minute)
; R2(H, L) : 3, 4th Segment(Second)
; This is an 8051 Assembly File
; Using EdSim51DI's Unmodified circuit.
; 8051 with 12MHz Clock
; Delay is not accurate.
; This code's function is now just a Stop-Watch without Stop Function.(2024/4/17)
; Date: 2024/4/17
; Written By: YHC03

ORG 0H
Loop: 
ACALL RUN ; Process +1 Second
ACALL PRINT ; Print&Delay 1 Second
SJMP Loop

RUN:
CLR P0.7 ; Turn Off Segments While in Calculation
INC R2 ; Increase Second
MOV A, R2
ANL PSW, #00111011B
DA A
MOV R2, A ; Process PACKED
ANL A, #0F0H
SWAP A
CLR C
SUBB A, #6
JNZ FINAL ; Check Minute
MOV R2, #0H ; Clear Second

INC R3 ; Increase Minute
MOV A, R3
ANL PSW, #00111011B
DA A
MOV R3, A ; Process PACKED
ANL A, #0F0H ; Get upper bits only
SWAP A
CLR C
SUBB A, #6
JNZ FINAL
MOV R3, #0H ; Clear Minute

FINAL: SETB P0.7 ; Turn On Segments When Calculation Finishes
RET

PRINT: MOV DPTR, #DATABASE

MOV 18H, #3
LOOP1: MOV 19H, #100
LOOP2: MOV 1AH, #100
LOOP3: NOP

; Print Minute
MOV A, #0F0H
ANL A, R3
SWAP A
MOVC A, @A+DPTR
CLR P0.7
MOV P1, A
ORL P3, #00011000B
SETB P0.7

MOV A, #0FH
ANL A, R3
MOVC A, @A+DPTR
CLR P0.7
MOV P1, A
CLR P3.3
SETB P0.7

; Print Second
MOV A, #0F0H
ANL A, R2
SWAP A
MOVC A, @A+DPTR
CLR P0.7
MOV P1, A
XRL P3, #00011000B
SETB P0.7

MOV A, #0FH
ANL A, R2
MOVC A, @A+DPTR
CLR P0.7
MOV P1, A
CLR P3.3
SETB P0.7

DJNZ 1AH, LOOP3
DJNZ 19H, LOOP2
DJNZ 18H, LOOP1
RET

ORG 750H ;Where 7-Segment Data Stores
DATABASE: DB 0C0H, 0F9H, 0A4H, 0B0H, 99H, 92H, 82H, 0D8H, 80H, 90H

END






