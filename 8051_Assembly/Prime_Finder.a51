; This is an 8051 asm file.
; Find prime number and write it, starting at RAM 0x30.
; Creator: YHC03
; Date: 24/04/17-24/04/24
ORG 0H
LJMP MAIN

ORG 30H
MAIN:
MOV 30H, #02H ; Cannot run 2 at this algorithm
MOV R1, #31H ; Write Begins at 31H
MOV R2, #3H ; Starts from 3

OUTER: MOV R3, #2H ; Loop Until Overflows
	LOOP: MOV A, R2 ; Loop Until not prime number found, or same number encounters
		MOV B, R3
		DIV AB
		MOV A, B
		JZ FAIL
		INC R3
		MOV A, R3
	CJNE A, 02, LOOP ; Inner Loop

		MOV @R1, 02
		INC R1
	FAIL: INC R2
		MOV A, R2
JNZ OUTER ; Outer Loop
END
