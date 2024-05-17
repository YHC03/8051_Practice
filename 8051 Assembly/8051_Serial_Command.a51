; 8051_Serial_Command
;
; Brief Function : Run commands, by Serial Input
;
; Serial Functions
;
; LED # ON : Turn on that LED(0-7)
; LED # OFF : Turn off that LED(0-7)
; SEGMENT ON : Turn on the Segment Display
; SEGMENT OFF : Turn of the Segment Display
; SEGMENT # : Print that number(0-9) on the Segment Display
; MOTOR FORWARD : Run the Motor Forward
; MOTOR REVERSE : Run the Motor Reverse
; MOTOR STOP : Stop the Motor
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
; R4(0x04): Loop for the process that the value is the same as the known command
; R7(0x07), B(0xF0): Temporary saves the value of R1, or @R1
; 0x08, 0x09: Return address (Written By Stack Pointer)
; 0x30-0x7F: The Input Value (with \r at the end of the value)
;
; This project uses Serial Input 0 at P3.1 port, and the baud rate is 4800 baud rate without a Parity Bit. The clock which the 8051 using is 11.0592MHz.
;
; Written By: YHC03


ORG 0H
LJMP INIT

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
    MOV TMOD, #20H ; Timer 1 Mode 2
    MOV TH1, #-6 ; Set Baud Rate as 4800 baud rate at 11.0592MHz
    MOV TL1, #-6 ; Reset TL1
    MOV SCON, #50H ; Serial1 Mode 1 with Input Enabled
    CLR RI ; Clear Serial Read Flag
    SETB TR1 ; Start Timer

    ; Move to Main Function

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
    CJNE A, #0DH, READ ; Do until the Serial data is \r (meaning that the input finished)

    ; Return to Main Function
    RET


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
    CJNE A, 0F0H, FAILURE ; Compare if the letter is not correct. If incorrect, the command unmatches, so the command is invalid
    INC DPTR ; Move to next letter
    INC R1 ; Increase the data pointer of input value
    DJNZ R4, LOOP_MOTOR ; Loop until the comparison of the value finished
    
    ; If comparison succeed, move to next stage
    JMP MOTOR_CONTROL
    
    ; If input value doesn't match the known commands, the command is invalid. Return to main function.
FAILURE: RET


; Second Stage

LED_CONTROL: ; If the First command is LED
    MOV A, @R1 ; Get the Second command
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


JMP_LED_OFF: ; Find if the command is 'LED # OFF'
    CJNE A, #'F', JMP_FAILURE ; If the second letter of the Third command is neither N nor F, the command is invalid
    INC R1 ; Move to next letter
    MOV A, @R1 ; Get the next letter
    CJNE A, #'F', JMP_FAILURE ; If the third letter of the Third command is not F, the command is invalid
    INC R1 ; Move to next letter
    MOV A, @R1 ; Get the next letter(\r assumed)
    CJNE A, #0DH, JMP_FAILURE ; If the last letter is not \r, the command is invaild
    
    ; The Command is "LED # OFF"
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
    CJNE A, 0F0H, MOTOR_STOP ; Compare if the letter is not correct. If incorrect, move to next command
    INC DPTR ; Move to next letter
    INC R1 ; Increase the data pointer of input value
    DJNZ R4, LOOP_REVERSE ; Loop until the comparison of the value finished

    ; The command is 'MOTOR REVERSE'
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


ORG 700H ; Where Constants stores
WORD_LED: DB "LED " ; Word 'LED' with a blank on the right side of the word
WORD_SEGMENT: DB "SEGMENT " ; Word 'SEGMENT' with a blank on the right side of the word
WORD_MOTOR: DB "MOTOR " ; Word 'MOTOR' with a blank on the right side of the word
WORD_FORWARD: DB "FORWARD", 0DH ; Word 'FORWARD' with \r on the right side of the word
WORD_REVERSE: DB "REVERSE", 0DH ; Word 'REVERSE' with \r on the right side of the word
WORD_STOP: DB "STOP", 0DH ; Word 'STOP' with \r on the right side of the word

SEGMENT_DATA: DB 0C0H, 0F9H, 0A4H, 0B0H, 99H, 92H, 82H, 0D8H, 80H, 90H ; Segment data to print on the segment display


END