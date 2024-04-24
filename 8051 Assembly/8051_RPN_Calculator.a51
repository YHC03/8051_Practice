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
; Update Date: 24/4/25
; Creator: YHC03
;
;
; Known Issues(24/4/24)
; It does not represents value under 1 in divide mode.
;

ORG 0H
LJMP MAIN

ORG 30H
MAIN:
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
; Temporary Register: R10-R13 (0x0A-0x0D)

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

	Wait1:
		CALL DISPLAY
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
	ADDER:
		MOV A, R4
		ADD A, R5
		MOV 0AH, A ; Temporary Save
		DA A
		MOV 08, A ; Packed BCD of value under 100 

		MOV A, 0AH
		CJNE A, #100, Adder_Next
		Adder_Next:
		JC Adder_Fin ; Answer<99
		INC 09 
		; as 99+99=198<200, Increase another value of 0x09 is not required
		Adder_Fin: INC R7
		JMP INF_LOOP

; SUBTRACT Command
	SUBTRACT:
		ACALL Decimal_to_Hex ; DEC to HEX Conversion
		MOV A, R4
		CLR C
		SUBB A, R5
		JNC NEXT_Cmd ; Check the result is less then 0

		; Answer if less then 0
		INC 32H
		MOV A, R5
		CLR C
		SUBB A, R4

	NEXT_Cmd:
		; as DA command does not works, so manually calculate.
		ACALL Manual_DA
		MOV 08H, 0AH
		INC R7
		JMP INF_LOOP

	; MULTIPLY Command
	MULTIPLY:
		ACALL Decimal_to_Hex ; DEC to HEX Conversion
		MOV A, R4
		MOV B, R5
		MUL AB
		MOV 08, A
		MOV 09, B
		ACALL HEX_to_Decimal_16Bit ; HEX to DEC Conversion
		INC R7
		JMP INF_LOOP

	; DIVIDE Command
	DIVIDE:
		MOV A, R5
		JNZ Next_Divide ; Find if divide by 0
			INC R7
			JMP INF_LOOP
		Next_Divide:
		ACALL Decimal_to_Hex
		MOV A, R4
		MOV B, R5
		DIV AB

		ACALL Manual_DA
		MOV 08H, 0AH
		INC R7
		JMP INF_LOOP



; Change Decimal Number in R4, R5 Register to HEX.
; R0 for temporary use
Decimal_to_Hex:
	MOV A, R4
	MOV R0, #0H ; Where under 4-bits stored. R0's address is 0x00.
	XCHD A, @R0 ; Move under 4-bits to R0 register.
	SWAP A
	MOV B, #10
	MUL AB ; Calculation Results in HEX
	ADD A, R0
	MOV R4, A ; Return to Original Repository

	MOV A, R5
	MOV R0, #0 ; Where under 4-bits stored. R0's address is 0x00.
	XCHD A, @R0 ; Move under 4-bits to R0 register
	SWAP A
	MOV B, #10
	MUL AB ; Calculation Results HEX
	ADD A, R0
	MOV R5, A ; Return to Original Repository

RET


; Returns decimal data at 0x0A, when A stores the target number and A is less then 100
MANUAL_DA:
	MOV B, #10
	DIV AB
	SWAP A
	ADD A, B
	MOV 0AH, A
RET



; R8 For Under byte, R9 For Upper Byte
; 0x0A for temporary use
; 0x0B, 0x0C, 0x0D for temporary set use
; 0x32, 0x33 -> 0x08, 0x09
HEX_to_Decimal_16Bit:
	; The Result is HEX 4-Digits. Let's view as (4)(3)(2)(1).

	; Last Decimal Digit
	;(4->3)->2->1
	MOV A, 09H
	MOV B, #10
	DIV AB

	;4->(3->2)->1
	MOV 0BH, A
	MOV A, B
	SWAP A
	MOV 0AH, A

	MOV A, #0F0H
	ANL A, 08H
	SWAP A
	ADD A, 0AH

	MOV B, #10
	DIV AB

	; 4->3->(2->1)
	MOV 0CH, A
	MOV A, B
	SWAP A
	MOV 0AH, A

	MOV A, #0FH
	ANL A, 08H
	ADD A, 0AH

	MOV B, #10
	DIV AB ; B is first decimal digit

	MOV 32H, B
	MOV 0DH, A

	; Next Digit
	; (3->2)->1
	MOV A, 0BH
	SWAP A
	ADD A, 0CH
	MOV B, #10

	DIV AB

	; 3->(2->1)
	MOV 0BH, A
	MOV A, B
	SWAP A
	ADD A, 0DH
	MOV B, #10
	DIV AB

	MOV 0CH, A
	MOV A, B ; B is second decimal digit
	SWAP A
	ADD A, 32H ; Create a Packed BCD
	MOV 32H, A

	; First 2 decimal digits
	; (2->1)
	MOV A, 0BH
	SWAP A
	ADD A, 0CH
	MOV B, #10
	DIV AB

	SWAP A ; HEX maximum of A is 5
	ADD A, B ; Create a Packed BCD
	MOV 33H, A

	; Return the values to Original Memory
	MOV 08H, 32H
	MOV 09H, 33H

RET



; Datum on 'B' Address
; 1-9 : 1-9
; A : *
; B : 0
; C : #
; Datum on 0x31 Address
; 0 : No Input
; 1 : Something Input
KEY_DECTACTER:
	MOV B, #1H ; Starts at 1
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

KEYCHECK:
	SWAP A
	; A=011(+0), 101(+1), 110(+2)
	MOV 31H, #1
	CJNE A, #5, PushNext
	SJMP SUB_ADDER
	PushNext: JNC DOUBLEADD ;110
	RET
	DOUBLEADD: INC B
	SUB_ADDER: INC B
RET


DISPLAY:
	MOV DPTR, #segData
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
	Print2:
		CJNE R7, #1, PrintOperator
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
	PrintOperator:
		CJNE R7, #2, PrintResult
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
ORG 1000H
segData:
	DB 0C0H, 0F9H, 0A4H, 0B0H, 99H, 92H, 82H, 0D8H, 80H, 90H ; 0 to 9
	DB 88H, 83H, 0C6H, 0A1H, 86H, 8EH ; A to F

END
