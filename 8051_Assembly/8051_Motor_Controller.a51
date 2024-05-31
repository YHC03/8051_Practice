; 8051_Motor_Controller
;
; Function: PWM Control the Motor attached at 8051
;
; Get the value of speed of the Motor by keypad.
; If new value was found, previous value of MOTOR_SPEED variable will be multiplied with 10, add with keypad value, and save at MOTOR_SPEED variable.
; If the calculation result is larger then 255, following calculation will happen.
; If the previous data is exactly same as 25 and if the keypad value is larger then 5, 10^1 digit of previous data will be removed, and calculate with the new value.
;
; If the previous data is larger then 25, 10^2 digit of previous data will be removed.
; After removing 10^2 digit of previous data, if the processed data is larger then 25, 10^1 digit of processed data will be removed.
; Also, if the processed data is exactly same as 25 and if the keypad value is larger then 5, 10^1 digit of processed data will be removed.
; After processing the value, calculate with the new value, and save at MOTOR_SPEED variable.
;
;
; Motor, Keypad, Keypad Interrupt, Segment Enable Switch are based on EdSim51DI's original connection.
; Segment Selection Switch is connected with P2.7 and P2.6 port.
;
;
; Written By: YHC03

; Port Conntections
;
; Motor: P3.0, P3.1(Forward, Backward)
; Segment Selection Switch: P2.7, P2.6
; Keypad: P0.0-P0.6
; Keypad Interrupt: P3.3
; Segment Enable Switch: P0.7

; Variable Usage
;
; R2: Saves the speed of the motor
; R3: Saves the current keypad data

MOTOR_FWD BIT P3.0
MOTOR_REV BIT P3.1
MOTOR_SPEED EQU 2 ; R2
PUT_MOTOR_SPEED EQU TL0
MOTOR_DEFAULT EQU TL1
KEYPAD_DATA EQU 3 ; R3
SEGMENT_SWITCH0 BIT P2.6
SEGMENT_SWITCH1 BIT P2.7

ORG 0H
LJMP INIT
ORG 0BH
LJMP PWM_SET_MOTOR
ORG 13H
LJMP KEYPAD_UPDATE
ORG 1BH
LJMP PWM_CLEAR_MOTOR


ORG 30H
INIT:
	MOV TMOD, #22H ; Timer 0, 1. Both Timers are on Mode 2.
	MOV MOTOR_SPEED, #0 ; Reset the PWM control value of Motor with 0(Stop the Motor)
	MOV TH0, #0 ; Reset the Initial Value of a timer that counts motor PWM value

	; Reset the Initial Value of a timer that counts initial value
	MOV MOTOR_DEFAULT, #0
	MOV TH1, #0

	; Turn on Both Timer
	SETB TR0
	SETB TR1

	; Stop Motor
	CLR MOTOR_FWD
	CLR MOTOR_REV
	
	; Set the External Keypad Interrupt as Edge Triggered Mode
	SETB IT1

	; Reset the P0 value for Keypad Detection
	MOV P0, #0F0H
	MOV IE, #8EH ; Turn on Timer 0, 1 Interrupt and External Interrupt 1
	MOV IP, #0AH ; Set Interrupt Priority at Timer Interrupts

MAIN:
	; Always Print Segment
	LCALL PRINT_SEGMENT
	SJMP MAIN


; Get the Keypad value, and process the Motor PWM data with the Keypad value.(Interrupt Service Routine)
KEYPAD_UPDATE:
	; Set P0 pin at Keypad Detection Mode
	MOV P0, #0FFH
	
	; Detect Keypad of 1 to 3
	CLR P0.3
FIND_1:
	JB P0.6, FIND_2
	MOV KEYPAD_DATA, #1
	SJMP KEYPAD_UPDATE_FIN
FIND_2:
	JB P0.5, FIND_3
	MOV KEYPAD_DATA, #2
	SJMP KEYPAD_UPDATE_FIN
FIND_3:
	JB P0.4, FIND_4_to_6
	MOV KEYPAD_DATA, #3
	SJMP KEYPAD_UPDATE_FIN

	; Detect Keypad of 4 to 6
FIND_4_to_6:
	SETB P0.3
	CLR P0.2
FIND_4:
	JB P0.6, FIND_5
	MOV KEYPAD_DATA, #4
	SJMP KEYPAD_UPDATE_FIN
FIND_5:
	JB P0.5, FIND_6
	MOV KEYPAD_DATA, #5
	SJMP KEYPAD_UPDATE_FIN
FIND_6:
	JB P0.4, FIND_7_to_9
	MOV KEYPAD_DATA, #6
	SJMP KEYPAD_UPDATE_FIN

	; Detect Keypad of 7 to 9
FIND_7_to_9:
	SETB P0.2
	CLR P0.1
FIND_7:
	JB P0.6, FIND_8
	MOV KEYPAD_DATA, #7	
	SJMP KEYPAD_UPDATE_FIN
FIND_8:
	JB P0.5, FIND_9
	MOV KEYPAD_DATA, #8	
	SJMP KEYPAD_UPDATE_FIN
FIND_9:
	JB P0.4, FIND_REST
	MOV KEYPAD_DATA, #9	
	SJMP KEYPAD_UPDATE_FIN

	; Detect Keypad of *, 0, and #
FIND_REST:
	SETB P0.1
	CLR P0.0
FIND_STAR:
	JB P0.6, FIND_0
	MOV KEYPAD_DATA, #10	
	SJMP KEYPAD_UPDATE_FIN
FIND_0:
	JB P0.5, FIND_SHARP
	MOV KEYPAD_DATA, #0	
	SJMP KEYPAD_UPDATE_FIN
FIND_SHARP:
	JB P0.4, FIND_4_to_6
	MOV KEYPAD_DATA, #11
	SJMP KEYPAD_UPDATE_FIN

	; If no keypad was detected, put 12 at KEYPAD_DATA
NOTHING_FOUND:
	MOV KEYPAD_DATA, #12

KEYPAD_UPDATE_FIN:
	; Reset the Keypad for keypad Interrupt Detection Mode
	MOV P0, #0F0H

	; Check if the Keypad Data is invaild(*, # cannot be input at the Motor Speed Value)
	MOV A, KEYPAD_DATA
	CJNE A, #10, COMPARE_NEXT
COMPARE_NEXT:
	JNC KEYPAD_ERROR

	; Check if overflow happens when input the current Keypad data
	; First, check if the previous MOTOR_SPEED data is larger than 25. If the previous data is larger then 25, overflow will happen
	; Second, check if the previous MOTOR_SPEED data is 25 and current Keypad data is larger then 6. If the previous MOTOR_SPEED data is exactly 25 and current Keypad data is larger then 6, overflow will happen.
	MOV A, MOTOR_SPEED
	CJNE A, #25, COMPARE_IF_OVERFLOWS

	; Check if the previous MOTOR_SPEED data is 25 and current Keypad data is larger then 6.
	MOV A, KEYPAD_DATA
	CJNE A, #6, CONTINUE_OVERFLOW_CHECK
CONTINUE_OVERFLOW_CHECK:
	JC PROCESS_CALCULATION
	SJMP OVERFLOW_PROCESS

	; Check if the previous MOTOR_SPEED data is larger than 25.
COMPARE_IF_OVERFLOWS:
	JC PROCESS_CALCULATION

	; Remove data larger then 100
	MOV A, MOTOR_SPEED
	MOV B, #100
	DIV AB
	MOV MOTOR_SPEED, A

	; Check if the processed data is larger then 25
	CJNE A, #25, COMPARE_IF_OVERFLOWS_PROCESS2

	; Check if the processed MOTOR_SPEED data is 25 and current Keypad data is larger then 6.
	MOV A, KEYPAD_DATA
	CJNE A, #6, CONTINUE_OVERFLOW_CHECK_PROCESS2
CONTINUE_OVERFLOW_CHECK_PROCESS2:
	JC PROCESS_CALCULATION
	SJMP OVERFLOW_PROCESS

	; Check if the processed MOTOR_SPEED data is larger than 25.
COMPARE_IF_OVERFLOWS_PROCESS2:
	JC OVERFLOW_PROCESS

	; Remove the data larger then 10
OVERFLOW_PROCESS:
	MOV A, MOTOR_SPEED
	MOV B, #10
	DIV AB
	MOV MOTOR_SPEED, B

	; Process the calculation: (Previous Data) * 10 + (Keypad Data)
PROCESS_CALCULATION:
	MOV A, MOTOR_SPEED
	MOV B, #10
	MUL AB
	ADD A, KEYPAD_DATA
	MOV MOTOR_SPEED, A

	; Put the Calculated data to the Timer 0
	MOV PUT_MOTOR_SPEED, A
	; Reset the Timer 1. Reset at #02H, correcting delay between processing command(2 cycle).
	MOV MOTOR_DEFAULT, #02H
	
	; Clear Edge-Triggerd Interrupt Flag of External Interrupt 1
	CLR IE1
	RETI
	
	; If the Keypad Value is invaild for calculation
KEYPAD_ERROR:
	; Clear Edge-Triggerd Interrupt Flag of External Interrupt 1
	CLR IE1
	RETI


; Turn Off the Motor when timer expires.(Interrupt Service Routine)
PWM_CLEAR_MOTOR:
	CLR MOTOR_FWD
	RETI


; Turn On the Motor when timer expires.(Interrupt Service Routine)
PWM_SET_MOTOR:
	; Check if the Motor Speed is 0.
	MOV A, MOTOR_SPEED
	; If the Motor Speed is 0, do not move the Motor.
	JZ STOP_MOTOR
	SETB MOTOR_FWD
	RETI

STOP_MOTOR:
	RETI


; Print the PWM Settings data to Segment(Function)
PRINT_SEGMENT:
	; Print data of 10^2 digit at Segment 2
	MOV A, MOTOR_SPEED
	MOV B, #100
	DIV AB
	MOV DPTR, #SEGMENT_DATA
	MOVC A, @A+DPTR
	CLR SEGMENT_SWITCH0
	SETB SEGMENT_SWITCH1
	MOV P1, A

	; Print data of 10^1 digit at segment 1
	MOV A, B
	MOV B, #10
	DIV AB
	MOV DPTR, #SEGMENT_DATA
	MOVC A, @A+DPTR
	SETB SEGMENT_SWITCH0
	CLR SEGMENT_SWITCH1
	MOV P1, A

	; Print data of 10^0 digit at segment 0
	MOV A, B
	MOV DPTR, #SEGMENT_DATA
	MOVC A, @A+DPTR
	CLR SEGMENT_SWITCH1
	CLR SEGMENT_SWITCH0
	MOV P1, A

	RET


; Store Segment Output Value
ORG 750H
SEGMENT_DATA: DB 0C0H, 0F9H, 0A4H, 0B0H, 99H, 92H, 82H, 0D8H, 80H, 90H