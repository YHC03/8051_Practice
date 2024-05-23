; 8051_Serial_Command
;
; Brief Function : Run commands, by Serial Input
;
; Serial Functions
;
; LED # ON : Turn on that LED(0-7)
; LED # OFF : Turn off that LED(0-7)
; LED BLINK ### : Blink all LED at machine cycle of the specific number(0-255)
; LED BLINK STOP : Stop Blinking all LED
; SEGMENT ON : Turn on the Segment Display
; SEGMENT OFF : Turn of the Segment Display
; SEGMENT # : Print that number(0-9) on the Segment Display
; MOTOR FORWARD : Run the Motor Forward
; MOTOR REVERSE : Run the Motor Reverse
; MOTOR BACKWARD : Run the Motor Backward
; MOTOR STOP : Stop the Motor
; KEYPAD LED ON : Scan the Keypad, and turn on the LED of the specific number pressed at the Keypad
; KEYPAD LED OFF : Scan the Keypad, and turn off the LED of the specific number pressed at the Keypad
; KEYPAD UART : Scan the Keypad, and print the result at the UART.
; KEYPAD SEGMENT : Scan the Keypad, and print the result on the segment
;
; # for number
;
;
; LED, Segment, Segment Enable swiches are based on EdSim51DI's unmodified circuit.
; Motor Forward is connected at P3.6 port, Motor Reverse is connected at P3.7 port.
;
; Registers used
;
; R0(0x00): Pointer for read value
; R1(0x01): Pointer for process the value read
; R2(0x02): Temporary Register for calculating the interval for blinking the LED
; R3(0x03): Temporary Register for saving the value of P0 when getting the data from the Keypad
; R4(0x04): Loop for the process that the value is the same as the known command
; R7(0x07): Temporary saves the value of R1, or @R1
; B(0xF0): Temporary saves the value of R1, @R1, and the value of the number of LED for turning on or off
; 0x08, 0x09: Return address (Written By Stack Pointer)
; 0x30-0x7F: The Input Value (with \r at the end of the value)
;
; This project uses Serial Input 0 at P3.1 port, and the baud rate is 4800 baud rate without a Parity Bit. The clock which the 8051 using is 11.0592MHz.
;
; Written By: YHC03


ORG 0H
LJMP INIT

ORG 0BH
LJMP TIMER_0_ISR

ORG 30H
INIT:
    ; Reset Segment Switch
    CLR P3.4
    CLR P3.3

    ; Reset Motor
    CLR P3.6
    CLR P3.7

    ; Initialize Input Pointer
    MOV R0, #30H

    ; Set Timer and Serial
    MOV TMOD, #22H ; Timer 0 Mode 2, Timer 1 Mode 2
    MOV TH1, #-6 ; Set Baud Rate as 4800 baud rate at 11.0592MHz
    MOV TL1, #-6 ; Reset TL1
    MOV SCON, #50H ; Serial1 Mode 1 with Input Enabled
    CLR RI ; Clear Serial Read Flag
    CLR TR0 ; Stop Timer 0
    SETB TR1 ; Start Timer 1
    MOV IE, #82H ; Set Timer 0 Interrupt
    SJMP MAIN ; Move to Main Function

MAIN:
    ; Reset Input Pointer
    MOV R0, #30H

    ; Read Serial Data
    ACALL READ

    ; Compare
    ACALL START_COMPARE

    ; Infinite Loop
    SJMP MAIN


READ:
    JNB RI, READ ; Wait Until Data Read
    CLR RI ; Clear Serial Read Flag
    MOV A, SBUF ; Move serial data to ACC

    CJNE R0, #7FH, READ_CONTINUE ; If Data Overflows
    MOV @R0, A ; Write at the last RAM. The final value must be '\r' because it can get out of the loop unless the input value is '\r'.
    CJNE A, #0DH, READ ; Do until the Serial data is \r (meaning that the input finished)

    ; Return to Main Function
    RET

READ_CONTINUE:
    MOV @R0, A ; Move the data to @R0
    INC R0 ; Increse R0 Pointer
    
    ; Find if the last letter of the input is '\r' or '\n'
    
    ; Find if the last letter of the input is '\n'
    CJNE A, #0AH, COMPARE_SERIAL_END ; If the Serial data is '\n' (meaning that a line of a input finished)
    DEC R0 ; Decrese R0 Pointer, to modify the last letter of the input
    MOV @R0, #0DH ; Replace '\n' with '\r' at the last letter of the input
    SJMP LINE_FINISHED
    
COMPARE_SERIAL_END: ; Find if the last letter of the input is '\r'
    CJNE A, #0DH, READ ; Do until the Serial data is '\r' (meaning that the input finished)

    ; Return to Main Function
LINE_FINISHED: RET


; Compare & Run Function
START_COMPARE:

LED_START: ; Find if the First Value is 'LED '
    MOV R1, #30H ; Initialize the pointer of the data
    MOV R4, #4 ; Set the length of value to find
    MOV DPTR, #WORD_LED ; Get the value to find

LOOP_LED:
    CLR A
    MOVC A, @A+DPTR ; Get the data of current letter of compare data
    MOV B, @R1 ; Get the data of current letter of input data
    CJNE A, 0F0H, SEGMENT_START ; Compare if the letter is not correct. If incorrect, move to next command
    INC DPTR ; Move to next letter
    INC R1 ; Increase the data pointer of input value
    DJNZ R4, LOOP_LED ; Loop until the comparison of the value finished

    ; If comparison succeed, move to next stage
    JMP LED_CONTROL


SEGMENT_START: ; Find if the First Value is 'SEGMENT '
    MOV R1, #30H ; Initialize the pointer of the data
    MOV R4, #8 ; Set the length of value to find
    MOV DPTR, #WORD_SEGMENT ; Get the value to find

LOOP_SEGMENT:
    CLR A
    MOVC A, @A+DPTR ; Get the data of current letter of compare data
    MOV B, @R1 ; Get the data of current letter of input data
    CJNE A, 0F0H, MOTOR_START ; Compare if the letter is not correct. If incorrect, move to next command
    INC DPTR ; Move to next letter
    INC R1 ; Increase the data pointer of input value
    DJNZ R4, LOOP_SEGMENT ; Loop until the comparison of the value finished

    ; If comparison succeed, move to next stage
    JMP SEGMENT_CONTROL


MOTOR_START: ; Find if the First Value is 'MOTOR '
    MOV R1, #30H ; Initialize the pointer of the data
    MOV R4, #6 ; Set the length of value to find
    MOV DPTR, #WORD_MOTOR ; Get the value to find

LOOP_MOTOR:
    CLR A
    MOVC A, @A+DPTR ; Get the data of current letter of compare data
    MOV B, @R1 ; Get the data of current letter of input data
    CJNE A, 0F0H, KEYPAD_START ; Compare if the letter is not correct. If incorrect, the command unmatches, so the command is invalid
    INC DPTR ; Move to next letter
    INC R1 ; Increase the data pointer of input value
    DJNZ R4, LOOP_MOTOR ; Loop until the comparison of the value finished
    
    ; If comparison succeed, move to next stage
    JMP MOTOR_CONTROL


KEYPAD_START: ; Find if the First Value is 'KEYPAD '
    MOV R1, #30H ; Initialize the pointer of the data
    MOV R4, #7 ; Set the length of value to find
    MOV DPTR, #WORD_KEYPAD ; Get the value to find

LOOP_KEYPAD:
    CLR A
    MOVC A, @A+DPTR ; Get the data of current letter of compare data
    MOV B, @R1 ; Get the data of current letter of input data
    CJNE A, 0F0H, FAILURE ; Compare if the letter is not correct. If incorrect, the command unmatches, so the command is invalid
    INC DPTR ; Move to next letter
    INC R1 ; Increase the data pointer of input value
    DJNZ R4, LOOP_KEYPAD ; Loop until the comparison of the value finished
    
    ; If comparison succeed, move to next stage
    JMP KEYPAD_CONTROL

    
    ; If input value doesn't match the known commands, the command is invalid. Return to main function.
FAILURE: RET


; Second Stage

LED_CONTROL: ; If the First command is LED
    MOV A, @R1 ; Get the Second command
    CJNE A, #'B', LED_GET_NUMBER

    MOV R4, #6 ; Set the length of value to find
    MOV DPTR, #WORD_BLINK ; Get the value to find
LOOP_BLINK:
    CLR A
    MOVC A, @A+DPTR ; Get the data of current letter of compare data
    MOV B, @R1 ; Get the data of current letter of input data
    CJNE A, 0F0H, JMP_FAILURE ; Compare if the letter is not correct. If incorrect, the command is invalid
    INC DPTR ; Move to next letter
    INC R1 ; Increase the data pointer of input value
    DJNZ R4, LOOP_BLINK ; Loop until the comparison of the value finished

    MOV A, @R1
    CJNE A, #'S', LED_GET_BLINK_VALUE

    MOV R4, #5 ; Set the length of value to find
    MOV DPTR, #WORD_STOP ; Get the value to find
LOOP_BLINK_STOP:
    CLR A
    MOVC A, @A+DPTR ; Get the data of current letter of compare data
    MOV B, @R1 ; Get the data of current letter of input data
    CJNE A, 0F0H, JMP_FAILURE ; Compare if the letter is not correct. If incorrect, the command is invalid
    INC DPTR ; Move to next letter
    INC R1 ; Increase the data pointer of input value
    DJNZ R4, LOOP_BLINK_STOP ; Loop until the comparison of the value finished

    ; The command is 'LED BLINK STOP'
    CLR TR0
    RET

LED_GET_BLINK_VALUE:
    MOV R2, #0H
    MOV A, @R1
LED_GET_BLINK_VALUE_LOOP:
    CJNE A, #0DH, NEXT_BLINK_VALUE

    ; Process Completed of 'LED BLINK ###'
    MOV A, #0H ; Initialize the original value
    CLR C ; Clear carry bit
    SUBB A, R2 ; Process the interval for timer
    MOV TH0, A ; Put the data to Timer 0 value
    MOV TL0, A
    SETB TR0 ; Turn on Timer 0
    RET

NEXT_BLINK_VALUE:
    MOV A, R2
    MOV B, #10
    MUL AB
    MOV B, A
    MOV A, @R1
    XRL A, #30H
    ADD A, B
    MOV R2, A
    INC R1
    MOV A, @R1
    SJMP LED_GET_BLINK_VALUE_LOOP

LED_GET_NUMBER:
    XRL A, #30H ; ASCII -> BCD
    MOV B, A ; Save the data
    INC R1 ; Move to blank command

    MOV A, @R1 ; Get the data(blank assumed)
    CJNE A, #' ', FAILURE ; If the data is not blank, the command is invaild (FAILURE used instead JMP_FAILURE to prevent target out of range error)

    INC R1 ; Move to the Third command

    MOV A, @R1 ; Get the Third command
    CJNE A, #'O', FAILURE ; If the first letter of the Third command is not O, the command is invaild (FAILURE used instead JMP_FAILURE to prevent target out of range error)
    INC R1 ; Move to next letter

    MOV A, @R1 ; Get the next letter of the command
    CJNE A, #'N', JMP_LED_OFF ; If the second letter of the Third command is not N, the command can be OFF
    INC R1 ; Move to next letter
    MOV A, @R1 ; Get the next letter of the command(\r assumed)
    CJNE A, #0DH, FAILURE ; If the last letter is not \r, the command is invaild (FAILURE used instead JMP_FAILURE to prevent target out of range error)

    ; The Command is "LED # ON"
    ACALL LED_ON
    RET


JMP_LED_OFF: ; Find if the command is 'LED # OFF'
    CJNE A, #'F', JMP_FAILURE ; If the second letter of the Third command is neither N nor F, the command is invalid
    INC R1 ; Move to next letter
    MOV A, @R1 ; Get the next letter
    CJNE A, #'F', JMP_FAILURE ; If the third letter of the Third command is not F, the command is invalid
    INC R1 ; Move to next letter
    MOV A, @R1 ; Get the next letter(\r assumed)
    CJNE A, #0DH, JMP_FAILURE ; If the last letter is not \r, the command is invaild
    
    ; The Command is "LED # OFF"
    ACALL LED_OFF
    RET

    ; If the command is invalid, return to main function
JMP_FAILURE: RET


; If the First command is SEGMENT
SEGMENT_CONTROL:
    MOV A, @R1 ; Get the first letter of the Second command

    CJNE A, #'O', WRITE_SEGMENT ; If the first letter of the Second command is 'O', the command can be 'SEGMENT ON' or 'SEGMENT OFF'
    INC R1 ; Move to next letter
    MOV A, @R1 ; Get the next letter
    CJNE A, #'N', JMP_SEGMENT_OFF ; If the second letter of the Second command is not N, the command can be OFF
    INC R1 ; Move to next letter
    MOV A, @R1 ; Get the next letter(\r assumed)
    CJNE A, #0DH, JMP_FAILURE ; If the last letter is not \r, the command is invaild

    ; The command is 'SEGMENT ON'
    SETB P0.7
    RET ; After the command finishes, return to main function

JMP_SEGMENT_OFF: ; Find if the command is 'SEGMENT OFF'
    CJNE A, #'F', JMP_FAILURE ; If the second letter of the Third command is neither N nor F, the command is invalid
    INC R1 ; Move to next letter
    MOV A, @R1 ; Get the next letter
    CJNE A, #'F', JMP_FAILURE ; If the third letter of the Third command is not F, the command is invalid
    INC R1 ; Move to next letter
    MOV A, @R1 ; Get the next letter(\r assumed)
    CJNE A, #0DH, JMP_FAILURE ; If the last letter is not \r, the command is invaild

    ; The command is 'SEGMENT OFF'
    CLR P0.7
    RET ; After the command finishes, return to main function

WRITE_SEGMENT: ; The command is 'SEGMENT #' assumed, but the command can be invalid if the command does not finishes at the number
    INC R1 ; Move to next letter
    MOV 7, @R1 ; Get the next letter(\r assumed)
    CJNE R7, #0DH, JMP_FAILURE ; If the last letter is not \r, the command is invaild

    ; The command is 'SEGMENT #'
    ; ASCII -> BCD
    XRL A, #30H

    ; Get the segment data of the number
    MOV DPTR, #SEGMENT_DATA
    MOVC A, @A+DPTR

    ; Print the segment data to the Port 1(Which the Segment connected)
    MOV P1, A
    RET ; After the command finishes, return to main function


; If the First command is MOTOR
MOTOR_CONTROL:
    MOV 7, R1 ; Backup the pointer of the input value

    MOV R4, #8 ; Set the length of value to find
    MOV DPTR, #WORD_FORWARD ; Get the value to find

LOOP_FORWARD:
    CLR A
    MOVC A, @A+DPTR ; Get the data of current letter of compare data
    MOV B, @R1 ; Get the data of current letter of input data
    CJNE A, 0F0H, MOTOR_REVERSE ; Compare if the letter is not correct. If incorrect, move to next command
    INC DPTR ; Move to next letter
    INC R1 ; Increase the data pointer of input value
    DJNZ R4, LOOP_FORWARD ; Loop until the comparison of the value finished

    ; The command is 'MOTOR FORWARD'
    SETB P3.6
    CLR P3.7
    RET ; After the command finishes, return to main function


MOTOR_REVERSE:
    MOV 1, R7 ; Restore the pointer of the input value
    MOV R4, #8 ; Set the length of value to find
    MOV DPTR, #WORD_REVERSE ; Get the value to find

LOOP_REVERSE:
    CLR A
    MOVC A, @A+DPTR ; Get the data of current letter of compare data
    MOV B, @R1 ; Get the data of current letter of input data
    CJNE A, 0F0H, MOTOR_BACKWARD ; Compare if the letter is not correct. If incorrect, move to next command
    INC DPTR ; Move to next letter
    INC R1 ; Increase the data pointer of input value
    DJNZ R4, LOOP_REVERSE ; Loop until the comparison of the value finished

    ; The command is 'MOTOR REVERSE'
    CLR P3.6
    SETB P3.7
    RET ; After the command finishes, return to main function


MOTOR_BACKWARD:
    MOV 1, R7 ; Restore the pointer of the input value
    MOV R4, #9 ; Set the length of value to find
    MOV DPTR, #WORD_BACKWARD ; Get the value to find

LOOP_BACKWARD:
    CLR A
    MOVC A, @A+DPTR ; Get the data of current letter of compare data
    MOV B, @R1 ; Get the data of current letter of input data
    CJNE A, 0F0H, MOTOR_STOP ; Compare if the letter is not correct. If incorrect, move to next command
    INC DPTR ; Move to next letter
    INC R1 ; Increase the data pointer of input value
    DJNZ R4, LOOP_BACKWARD ; Loop until the comparison of the value finished

    ; The command is 'MOTOR BACKWARD'
    CLR P3.6
    SETB P3.7
    RET ; After the command finishes, return to main function


MOTOR_STOP:
    MOV 1, R7 ; Restore the pointer of the input value
    MOV R4, #5 ; Set the length of value to find
    MOV DPTR, #WORD_STOP ; Get the value to find

LOOP_STOP:
    CLR A
    MOVC A, @A+DPTR ; Get the data of current letter of compare data
    MOV B, @R1 ; Get the data of current letter of input data
    CJNE A, 0F0H, MOTOR_FAILURE ; Compare if the letter is not correct. If incorrect, the command unmatches, so the command is invalid
    INC DPTR ; Move to next letter
    INC R1 ; Increase the data pointer of input value
    DJNZ R4, LOOP_STOP ; Loop until the comparison of the value finished

    ; The command is 'MOTOR STOP'
    CLR P3.6
    CLR P3.7
    RET ; After the command finishes, return to main function


    ; If the command is invalid, return to main function
MOTOR_FAILURE: RET


KEYPAD_CONTROL:
    MOV 7, R1 ; Backup the pointer of the input value

    MOV R4, #4 ; Set the length of value to find
    MOV DPTR, #WORD_LED ; Get the value to find
LOOP_KEYPAD_LED:
    CLR A
    MOVC A, @A+DPTR ; Get the data of current letter of compare data
    MOV B, @R1 ; Get the data of current letter of input data
    CJNE A, 0F0H, KEYPAD_UART ; Compare if the letter is not correct. If incorrect, move to next command
    INC DPTR ; Move to next letter
    INC R1 ; Increase the data pointer of input value
    DJNZ R4, LOOP_KEYPAD_LED ; Loop until the comparison of the value finished


    MOV A, @R1 ; Get the first letter of the Third command
    CJNE A, #'O', KEYPAD_LED_FAILURE ; If the first letter of the Third command is 'O', the command can be 'KEYPAD LED ON' or 'KEYPAD LED OFF'
    INC R1 ; Move to next letter
    MOV A, @R1 ; Get the next letter
    CJNE A, #'N', JMP_KEYPAD_LED_OFF ; If the second letter of the Third command is not N, the command can be OFF
    INC R1 ; Move to next letter
    MOV A, @R1 ; Get the next letter(\r assumed)
    CJNE A, #0DH, KEYPAD_LED_FAILURE ; If the last letter is not \r, the command is invaild

    ; The command is 'KEYPAD LED ON'
    ACALL KEYPAD_GET_NUM ; Get the value of pressed Keypad
    MOV A, B
    JZ NO_NUMBER_INPUT ; If no data was found

    XRL A, #30H ; ASCII -> BCD
    MOV B, A
    ACALL LED_ON ; Turn on the LED
    RET ; After the command finishes, return to main function

JMP_KEYPAD_LED_OFF: ; Find if the command is 'KEYPAD LED OFF'
    CJNE A, #'F', KEYPAD_LED_FAILURE ; If the second letter of the Third command is neither N nor F, the command is invalid
    INC R1 ; Move to next letter
    MOV A, @R1 ; Get the next letter
    CJNE A, #'F', KEYPAD_LED_FAILURE ; If the third letter of the Third command is not F, the command is invalid
    INC R1 ; Move to next letter
    MOV A, @R1 ; Get the next letter(\r assumed)
    CJNE A, #0DH, KEYPAD_LED_FAILURE ; If the last letter is not \r, the command is invaild

    ; The command is 'KEYPAD LED OFF'
    ACALL KEYPAD_GET_NUM ; Get the value of pressed Keypad
    MOV A, B
    JZ NO_NUMBER_INPUT ; If no data was found

    XRL A, #30H ; ASCII -> BCD
    MOV B, A
    ACALL LED_OFF ; Turn off the LED
    RET ; After the command finishes, return to main function

KEYPAD_LED_FAILURE:
NO_NUMBER_INPUT:
    RET ; After the command finishes, return to main function

KEYPAD_UART:
    MOV R7, 1

    MOV R4, #4 ; Set the length of value to find
    MOV DPTR, #WORD_UART ; Get the value to find
LOOP_KEYPAD_UART:
    CLR A
    MOVC A, @A+DPTR ; Get the data of current letter of compare data
    MOV B, @R1 ; Get the data of current letter of input data
    CJNE A, 0F0H, KEYPAD_SEGMENT ; Compare if the letter is not correct. If incorrect, move to next command
    INC DPTR ; Move to next letter
    INC R1 ; Increase the data pointer of input value
    DJNZ R4, LOOP_KEYPAD_UART ; Loop until the comparison of the value finished

    ; Check if the last letter is '\r'
    MOV A, @R1 ; Get the last word
    CJNE A, #0DH, KEYPAD_SEGMENT ; Compare if the letter is not correct. If incorrect, move to next command

    ; The command is 'KEYPAD UART'
    ACALL KEYPAD_GET_NUM
    MOV A, B
    JZ NO_NUMBER_TO_PRINT ; If no data was found

    ; Print the value
    MOV SBUF, A
    JNB TI, $
    CLR TI

NO_NUMBER_TO_PRINT:
    RET ; After the command finishes, return to main function

KEYPAD_SEGMENT:
    MOV R7, 1

    MOV R4, #7 ; Set the length of value to find
    MOV DPTR, #WORD_SEGMENT ; Get the value to find
LOOP_KEYPAD_SEGMENT:
    CLR A
    MOVC A, @A+DPTR ; Get the data of current letter of compare data
    MOV B, @R1 ; Get the data of current letter of input data
    CJNE A, 0F0H, KEYPAD_FAIL ; Compare if the letter is not correct. If incorrect, the command is invalid
    INC DPTR ; Move to next letter
    INC R1 ; Increase the data pointer of input value
    DJNZ R4, LOOP_KEYPAD_SEGMENT ; Loop until the comparison of the value finished

    ; Check if the last letter is '\r'
    MOV A, @R1 ; Get the last word
    CJNE A, #0DH, KEYPAD_FAIL ; Compare if the letter is not correct. If incorrect, the command is invalid

    ; The command is 'KEYPAD SEGMENT'
    ACALL KEYPAD_GET_NUM
    MOV A, B ; Get the data from register B
    JZ NO_NUMBER_SEGMENT ; If no data was found
    
    ; Process if the input is '*' or '#' (Cannot Print on the segment)
    CLR C
    SUBB A, #'0'
    JC NO_NUMBER_SEGMENT ; When the input is '*' or '#', the carry bit will be 1, as the ASCII value of '*' and '#' is less then '0'.

    MOV A, B ; Get the data from register B
    XRL A, #30H ; ASCII -> BCD
    MOV DPTR, #SEGMENT_DATA
    MOVC A, @A+DPTR ; Get the Segment data
    MOV P1, A

NO_NUMBER_SEGMENT:
    RET ; After the command finishes, return to main function

    ; If the command is invalid, return to main function
KEYPAD_FAIL: RET


; Get the keypad value, and send to B register as ASCII character(0 for nothing, Function)
KEYPAD_GET_NUM:
    MOV A, #0H
    MOV B, #0H
    MOV R3, P0

    ; Find 1 to 3
    MOV A, R3
    ANL A, #0F7H
    MOV R3, A
    MOV P0, A
    JB P0.6, FIND_2
    MOV B, #'1'
FIND_2: JB P0.5, FIND_3
    MOV B, #'2'
FIND_3: JB P0.4, FIND_4_TO_6
    MOV B, #'3'

FIND_4_TO_6:
    ; Find 4 to 6
    MOV A, R3
    ADD A, #4H ; 0xF7 -> 0xFB
    MOV R3, A
    MOV P0, A
    JB P0.6, FIND_5
    MOV B, #'4'
FIND_5: JB P0.5, FIND_6
    MOV B, #'5'
FIND_6: JB P0.4, FIND_7_TO_9
    MOV B, #'6'

FIND_7_TO_9:
    ; Find 7 to 9
    MOV A, R3
    ADD A, #2H ; 0xF7 -> 0xFD
    MOV R3, A
    MOV P0, A
    JB P0.6, FIND_8
    MOV B, #'7'
FIND_8: JB P0.5, FIND_9
    MOV B, #'8'
FIND_9: JB P0.4, FIND_REST
    MOV B, #'9'

FIND_REST:
    ; Find *, 0, and #
    MOV A, R3
    ADD A, #1H ; 0xFD -> 0xFE
    MOV R3, A
    MOV P0, A
    JB P0.6, FIND_0
    MOV B, #'*'
FIND_0: JB P0.5, FIND_SHARP
    MOV B, #'0'
FIND_SHARP: JB P0.4, FINAL_RETURN
    MOV B, #'#'

FINAL_RETURN:
    ; Reset the Keypad
    MOV A, R3
    ADD A, #1H ; 0xFE -> 0xFF
    MOV P0, A

    RET



; Turn on the LED specified at B(Function)
LED_ON:
    MOV A, B ; Move the port data to A

    ; Process Branch Table
    JZ ON_0
    DEC A
    JZ ON_1
    DEC A
    JZ ON_2
    DEC A
    JZ ON_3
    DEC A
    JZ ON_4
    DEC A
    JZ ON_5
    DEC A
    JZ ON_6
    DEC A
    JZ ON_7

    ; If the value is not 0 to 7, the command is invalid
    RET


    ; The branch table for 'LED # ON'
    ; After the command finishes, return to main function
ON_0: CLR P1.0
    RET
ON_1: CLR P1.1
    RET
ON_2: CLR P1.2
    RET
ON_3: CLR P1.3
    RET
ON_4: CLR P1.4
    RET
ON_5: CLR P1.5
    RET
ON_6: CLR P1.6
    RET
ON_7: CLR P1.7
    RET


; Turn off the LED specified at B(Function)
LED_OFF:
    MOV A, B ; Move the port data to A

    ; Process Branch Table
    JZ OFF_0
    DEC A
    JZ OFF_1
    DEC A
    JZ OFF_2
    DEC A
    JZ OFF_3
    DEC A
    JZ OFF_4
    DEC A
    JZ OFF_5
    DEC A
    JZ OFF_6
    DEC A
    JZ OFF_7

    ; If the value is not 0 to 7, the command is invalid
    RET
    
    ; The branch table for 'LED # OFF'
    ; After the command finishes, return to main function
OFF_0: SETB P1.0
    RET
OFF_1: SETB P1.1
    RET
OFF_2: SETB P1.2
    RET
OFF_3: SETB P1.3
    RET
OFF_4: SETB P1.4
    RET
OFF_5: SETB P1.5
    RET
OFF_6: SETB P1.6
    RET
OFF_7: SETB P1.7
    RET


; Timer 0 Interrupt
TIMER_0_ISR:
    XRL P1, #0FFH ; Blink the LED
    RETI

ORG 700H ; Where Constants stored
WORD_LED: DB "LED " ; Word 'LED' with a blank on the right side of the word
WORD_SEGMENT: DB "SEGMENT " ; Word 'SEGMENT' with a blank on the right side of the word
WORD_MOTOR: DB "MOTOR " ; Word 'MOTOR' with a blank on the right side of the word
WORD_KEYPAD: DB "KEYPAD " ; Word 'KEYPAD' with a blank on the right side of the word
WORD_BLINK: DB "BLINK " ; Word 'BLINK' with a blank on the right side of the word

WORD_UART: DB "UART" ; Word 'UART'
WORD_FORWARD: DB "FORWARD", 0DH ; Word 'FORWARD' with \r on the right side of the word
WORD_REVERSE: DB "REVERSE", 0DH ; Word 'REVERSE' with \r on the right side of the word
WORD_BACKWARD: DB "BACKWARD", 0DH ; Word 'BACKWARD' with \r on the right side of the word
WORD_STOP: DB "STOP", 0DH ; Word 'STOP' with \r on the right side of the word

SEGMENT_DATA: DB 0C0H, 0F9H, 0A4H, 0B0H, 99H, 92H, 82H, 0D8H, 80H, 90H ; Segment data to print on the segment display


END