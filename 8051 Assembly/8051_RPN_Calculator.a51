; Reverse Polish Notation Calculator
;
; Function: 2-Digit Number Calculation
;
; Based on EdSim51DI's Unmodified Circuit
;
; Switches
; P0.0-6: Keypad(to Input Numbers)
; P2.0: Enter (Unused When Operator Input Mode)
; P2.4: Add
; P2.3: Subtract
; P2.2: Multiply
; P2.1: Divide
;
; Create Date: 24/4/18
; Update Date: 24/4/19
; Creator: YHC03
;
;
; Known Issues(24/4/19)
; It Represents HEX Output(Not Decimal)
; In Add and Subtract Operation, using DA Command will be a solution.
;

ORG 0H
MOV SP, #10H ; Stack Pointer Location Change
MOV P0, #0FFH ; Put Read Mode on Keypad
MOV P2, #1FH ; Put Read Mode on Using Switches

; Print Register: R8, R9 (08H, 09H Direct Addressing)
; R8 for Lower 8-bits
; R9 for Higher 8-bits
; First Data Register: R4
; Second Data Register: R5
; Point Location Register: R6 (Unused Now-24/04/19)
; Current Location Register: R7(0: First Number, 1: Second Number, 2: Operator, 3: Result)

MOV R7, #0H
INF_LOOP:
MOV R4, #0 ; Init R4
MOV R5, #0 ; Init R5
CALL DISPLAY
DETECT1st: ACALL KEY_DECTACTER ; Find Number
; DELAY
MOV A, 31H
JZ Next1st ; No Input

MOV A, B
CJNE A, #0BH, SecondIf_1st ; Find 0
MOV B, #0 ; B=0
SJMP Adder1
SecondIf_1st: ; Find * and #
JNC Next1st ; If Input was #
CJNE A, #0AH, Adder1 ; Find *
SJMP Next1st

Adder1:
MOV R7, #0H
MOV A, R4
SWAP A
ANL A, #0F0H
ADD A, B
MOV R4, A

Wait1: CALL DISPLAY
ACALL KEY_DECTACTER
MOV A, 31H
JNZ Wait1 ; Wait Until Key Undetects

Next1st: ; Find Enter
CALL DISPLAY
MOV C, P2.0
JC DETECT1st

; DELAY

DETECT1st2:
CALL DISPLAY
MOV C, P2.0
JNC DETECT1st2 ; Wait Until Undetect

CJNE R7, #3, NoBug
BugFix: MOV R7, #0H
NoBug: INC R7 ; First->Second




; SECOND
DETECT2nd:
ACALL KEY_DECTACTER ; Find Number
;DELAY
MOV A, 31H
JZ Next2nd ; No Input

MOV A, B
CJNE A, #0BH, SecondIf_2nd ; Find 0
MOV B, #0 ; B=0
SJMP Adder2
SecondIf_2nd: ; Find * and #
JNC Next2nd ; If input was #
CJNE A, #0AH, Adder2 ; Find *
SJMP Next2nd

Adder2:
MOV A, R5
SWAP A
ANL A, #0F0H
ADD A, B
MOV R5, A

Wait2:
CALL DISPLAY
ACALL KEY_DECTACTER
MOV A, 31H
JNZ Wait2 ; Wait Until Key Undetects

Next2nd: ; Find Enter
CALL DISPLAY
MOV C, P2.0
JC DETECT2nd

DETECT2nd2:
CALL DISPLAY
MOV C, P2.0
JNC DETECT2nd2 ; Wait Until Undetect

; DELAY
INC R7 ; Second -> Operator




; Operator
MOV 08, #0H ; Lower 8bit
MOV 09, #0H ; Higher 8bit
OperatorLoop:
CALL DISPLAY
MOV A, #1EH
ANL A, P2
CJNE A, #1EH, OperatorNext ; Nothing
SJMP OperatorLoop

; Datum on 0x32
; 1 for Answer less then 0
; 0 for Answer greater, or equals to 0
OperatorNext:
MOV 32H, #0H ; 0 for +, 1 for -
RRC A ; Neglect Enter Data
RRC A ; Divide Command
JNC DIVIDE
RRC A ; Multiply Command
JNC MULTIPLY
RRC A ; Subtract Command
JNC SUBTRACT
SJMP ADDER ; Otherwise, Add Command


; ADD Command
ADDER: MOV A, R4
ADD A, R5
JNC Adder_Fin
INC 09
Adder_Fin: MOV 08, A
INC R7
JMP INF_LOOP

; SUBTRACT Command
SUBTRACT:
MOV A, R4
CLR C
SUBB A, R5
JNC NEXT_Cmd ; Check the result is less then 0

INC 32H
CLR C
MOV A, R5
SUBB A, R4

NEXT_Cmd: MOV 08, A
INC R7
JMP INF_LOOP

; MULTIPLY Command
MULTIPLY:
MOV A, R4
MOV B, R5
MUL AB
MOV 08, A
MOV 09, B
INC R7
JMP INF_LOOP

; DIVIDE Command
DIVIDE:
MOV A, R5
JNZ Next_Divide ; Find if divide by 0
INC R7
JMP INF_LOOP

Next_Divide: MOV A, R4
MOV B, R5
DIV AB
MOV 08, A
INC R7
JMP INF_LOOP

; Datum on 'B' Address
; 1-9 : 1-9
; A : *
; B : 0
; C : #
; Datum on 0x31 Address
; 0 : No Input
; 1 : Something Input
KEY_DECTACTER:
MOV B, #0H
MOV 31H, #0H ; Init FinishChecker
MOV P0, #0FFH
CLR P0.3 ; Row 123
ACALL KEY_DETECTION
MOV A, 31H
JNZ FINAL
INC B
INC B
INC B

SETB P0.3
CLR P0.2 ; Row 456
ACALL KEY_DETECTION
MOV A, 31H
JNZ FINAL
INC B
INC B
INC B

SETB P0.2
CLR P0.1 ; Row 789
ACALL KEY_DETECTION
MOV A, 31H
JNZ FINAL
INC B
INC B
INC B

SETB P0.1
CLR P0.0 ; Row *0#
ACALL KEY_DETECTION
MOV A, 31H
JNZ FINAL

FINAL: RET


KEY_DETECTION:
MOV A, P0
ANL A, #70H
CJNE A, #70H, KEYCHECK
RET ; Key Not Detected
KEYCHECK: SWAP A
; A=011(+1), 101(+2), 110(+3)
MOV 31H, #1
INC B
CJNE A, #5, PushNext
SJMP SUB_ADDER
PushNext: JNC DOUBLEADD ;110
RET
DOUBLEADD: INC B
SUB_ADDER: INC B
RET


DISPLAY: MOV DPTR, #segData
CJNE R7, #0, Print2

; Print 1st Number
Print1:
CLR P0.7
ANL P3, #11100111B
MOV A, #0FH
ANL A, R4
MOVC A, @A+DPTR

MOV P1, A
SETB P0.7

CLR P0.7
SETB P3.3
MOV A, #0F0H
ANL A, R4
SWAP A
MOVC A, @A+DPTR
MOV P1, A
SETB P0.7

RET

; Print 2nd Number
Print2: CJNE R7, #1, PrintOperator
CLR P0.7
ANL P3, #11100111B
MOV A, #0FH
ANL A, R5
MOVC A, @A+DPTR
MOV P1, A
SETB P0.7

CLR P0.7
SETB P3.3
MOV A, #0F0H
ANL A, R5
SWAP A
MOVC A, @A+DPTR
MOV P1, A
SETB P0.7

RET

; Print Operator
PrintOperator: CJNE R7, #2, PrintResult
; Just Print .(dot)
SETB P0.7
ANL P3, #11100111B
MOV P1, #7FH
RET

; Print Result
PrintResult:
CLR P0.7
ANL P3, #11100111B
MOV A, #0FH
ANL A, 08
MOVC A, @A+DPTR
MOV P1, A
SETB P0.7

CLR P0.7
SETB P3.3
MOV A, #0F0H
ANL A, 08
SWAP A
MOVC A, @A+DPTR
MOV P1, A
SETB P0.7

CLR P0.7
XRL P3, #00011000B

; Print - if the answer is less then 0
MOV A, 32H
JZ Print3rd
MOV P1, #0BFH 
SETB P0.7
RET

Print3rd:
MOV A, #0FH
ANL A, 09
MOVC A, @A+DPTR
MOV P1, A
SETB P0.7

CLR P0.7
SETB P3.3
MOV A, #0F0H
ANL A, 09
SWAP A
MOVC A, @A+DPTR
MOV P1, A
SETB P0.7

RET

; Segment data for HEX numbers
ORG 700H
segData: DB 0C0H, 0F9H, 0A4H, 0B0H, 99H, 92H, 82H, 0D8H, 80H, 90H, 88H, 83H, 0C6H, 0A1H, 86H, 8EH

END
