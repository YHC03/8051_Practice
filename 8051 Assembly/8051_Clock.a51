; R3(H, L) : 1, 2nd Segment(Minute)
; R2(H, L) : 3, 4th Segment(Second)
; R4 : Settings Mode (0: Minute Setting, 1: Second Setting, 2: Running)
; This is an 8051 Assembly File
; Using EdSim51DI's Unmodified circuit.
; 8051 with 12MHz Clock
; Delay is Inaccurate in Few Machine Cycle.
; Date: 2024/4/17-2024/5/11
; Written By: YHC03
;
; Switch Usage
; P2.0 : Clock Settings, Commit
; P2.1 : Increase Minute or Second

ORG 0H
LJMP MAIN

ORG 0BH ; Timer 0 Interrupt
LJMP INTERRUPT1

ORG 30H
MAIN:
MOV P2, #03H
MOV R4, #2H
MOV IE, #82H ; Interrupt Set
MOV TMOD, #01H ; Timer Set
SETB TF0 ; Init the value of Timer 0
SETB TR0

MAIN_LOOP:
	ACALL DELAY ; Print&Delay 1 Second
	ACALL IncreaseSecond ; Process +1 Second
SJMP MAIN_LOOP



; Increase Second
IncreaseSecond:
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
	JNZ Final_Second ; Check Minute
	MOV R2, #0H ; Clear Second
	CJNE R4, #2H, Final_Second
	SJMP IncreaseMinute ; In Running Mode, Increase Minute

Final_Second:
	SETB P0.7 ; Turn On Segments When Calculation Finishes
	RET



; Increase Minute
IncreaseMinute:
	CLR P0.7 ; Turn Off Segments While in Calculation
	INC R3 ; Increase Minute
	MOV A, R3
	ANL PSW, #00111011B
	DA A
	MOV R3, A ; Process PACKED
	ANL A, #0F0H ; Get upper bits only
	SWAP A
	CLR C
	SUBB A, #6
	JNZ Final_Minute
	MOV R3, #0H ; Clear Minute

Final_Minute:
	SETB P0.7 ; Turn On Segments When Calculation Finishes
	RET



; Delay a second
; Memory address using for delay loop: R0
DELAY:
	MOV R0, #16
	LOOP:
		ACALL PRINT
		MOV C, P2.0
		JC Continue
			CLR TR0
			ACALL SETTINGS

			; After Settings, Reset Timer and Delay time
			MOV R0, #16
			MOV TL0, #0DDH
			MOV TH0, #0BH
			SETB TR0

		Continue:
	CJNE R0, #0, LOOP
RET



; Clock Settings
SETTINGS:
	MOV R4, #0H
	WaitUntil: ACALL PRINT
		MOV C, P2.0
	JNC WaitUntil

; Settings Stage 1 : Minute
SetMinute:
	ACALL PRINT
	MOV C, P2.1
	JC SetMinute_2nd
	ACALL IncreaseMinute
	WaitUntilMinute1: ACALL PRINT
		MOV C, P2.1
	JNC WaitUntilMinute1

SetMinute_2nd:
	MOV C, P2.0
	JC SetMinute
	INC R4
	WaitUntilMinute2: ACALL PRINT
		MOV C, P2.0
	JNC WaitUntilMinute2

; Settings Stage 2: Second
SetSecond:
	ACALL PRINT
	MOV C, P2.1
	JC SetSecond_2nd
	ACALL IncreaseSecond
	WaitUntilSecond1: ACALL PRINT
		MOV C, P2.1
	JNC WaitUntilSecond1

SetSecond_2nd:
	MOV C, P2.0
	JC SetSecond
	INC R4
	WaitUntilSecond2: ACALL PRINT
		MOV C, P2.0
	JNC WaitUntilSecond2

RET



; Print Clock
PRINT:
	MOV DPTR, #DATABASE

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
	CJNE R4, #0H, Next_Min
		ANL A, #7FH ; Indicates Minute Modification Mode
	Next_Min:
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
	CJNE R4, #1H, Next_Sec
		ANL A, #7FH ; Indicates Second Modification Mode
	Next_Sec:
	CLR P0.7
	MOV P1, A
	CLR P3.3
	SETB P0.7

RET

ORG 500H
INTERRUPT1:
	; Originally Delay For 62500 Machine Cycle, but adding machine cycles outside the timer control, 2 was added on Timer's Initial Value.
	MOV TL0, #0DDH
	MOV TH0, #0BH
	DEC R0
	RETI

ORG 750H ; Where 7-Segment Data Stores
DATABASE:
	DB 0C0H, 0F9H, 0A4H, 0B0H, 99H, 92H, 82H, 0D8H, 80H, 90H

END
