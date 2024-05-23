; 8051_Doorlock
;
; Function: Perform a function of a doorlock device with 8051
;
; To use the unlock mode, press '*', press the numbers, and press '*' again. The initial password is 0000.
; If the password correct, LED on P1.0 will be turned on, and Motor on P3.0, P3.1 will run forward.
; If the password does not correct, the segment will print 'E' without the dot of the segment.
;
; To use the password change mode, press '*' 4 times, press the numbers, and press '*' 4 times again.
; Then the password will be changed.
;
; Press '#' anytime if you want to abort the input process. The segment will not print anything.
;
; If the input was detected, LED and Segment on P1.0 will be turned off, and Motor on P3.0, P3.1 will stop.
; And, if the input is '*', all of the LED will not be turned on.
; If the input is a number, one of the LED will be turned on, starting from LED0(on P1.0) to LED7(on P1.7). If one of the LED was turned on, the other LEDs will be turned off.
;
; But if the password correct, LED and Motor will be turned on as mentioned above, after turning off the LED and Motor by detection of the input.
; If the input is invalid, the segment will print 'E' with the dot of the segment.
; 
; The number of the input number is 4 to 8.
;
; Based on EdSim51DI's unmodified circuit with AND Gate Enabled settings.
;
;
; Written by: YHC03


; Memory Used
;
; R0(0x00): Pointer to store the input value
; R1(0x01): Pointer to read password to compare password, or reset the input value
; R2(0x02): Memory to count the number of input without '*' and '#' at a input
; R7(0x07): Memory to count the number of '*'
; 0x30 - 0x5F: Memory for store input value
; 0x70 - 0x7F: Memory for store password


ORG 0H
LJMP INIT

ORG 30H
INIT:
    ; Reset the value of the Password with 0000
    MOV 70H, #0
    MOV 71H, #0
    MOV 72H, #0
    MOV 73H, #0
    MOV 74H, #0DH ; Put \r to indicate the end of the password

    ; Reset the Motor
    CLR P3.0
    CLR P3.1

    ; Set the Keypad with Input Mode, and turn off the Segment
    MOV P0, #70H

    ; Move to Main Function
    SJMP MAIN

MAIN:
    LCALL CLEARCOMMAND ; Clear the input buffer
    MOV R0, #30H ; Reset the pointer for input
    MOV R7, #0 ; Reset the number of '*'
    MOV R2, #0 ; Reset the number of the numbers input
    
WAIT: JB P3.3, WAIT ; Wait until the Key Detected
    CLR P0.7 ; Turn Off the Segment
    MOV P1, #0FFH ; Clear the LED and Segment
    LCALL KEYPAD_CONTROL ; Get and save the keypad data 
    SETB P1.0 ; Turn off the LED which indicates the door is now unlocked
    CLR P3.0 ; Turn off the Motor which indicates the door is now unlocked

    MOV R1, 0 ; Copy R0 to R1
    DEC R1 ; Decrease the R1, to read the Input value
    MOV A, @R1 ; Read the last letter
    CJNE A, #'#', CONTINUE_FIND ; If the last letter is #. Else, check if the input is *
    SJMP MAIN ; Reset the input process

CONTINUE_FIND: CJNE A, #'*', NUMBER_INPUT ; If the last letter is *
    INC R7 ; Increase the number of *

    CJNE R7, #2, IF_8 ; If * has been encounterd twice. Else check if * has been encountered 8 times.
    CJNE R0, #32H, COMPARE ; If there is a number input, jump to COMPARE label to find if the input value is the same as the password
    LJMP WAIT ; If there is no number input, wait until the password setting input finishes

IF_8: CJNE R7, #8, WAIT ; If * has been encountered 8 times. Else wait until the other command was input
    MOV A, R2 ; Get the count of number input
    CLR C ; Clear Carry Bit to process subraction
    SUBB A, #4 ; Subtract by 4, if the input is less then 4, the carry bit will be 1
    JC ERROR_RESET ; Process the reset by wrong input

    ; If there is no error
    LJMP SET_PASSWORD ; Jump to SET_PASSWORD label


NUMBER_INPUT:
    INC R2 ; Increse the number input
    CJNE R2, #9, CONTINUE_READ ; If the input number count is 9
    SJMP ERROR_RESET ; Process the reset by wrong input

CONTINUE_READ:
    ACALL PRINT_STATUS ; Print the input Status
    MOV A, R7 ; Get the number of *
    CJNE A, #1, NEXT_CRITERIA ; If the number of * is 1(assume unlock mode). Else check is the mode is password change mode
    SJMP WAIT ; If there is no number input, wait until the input finishes
NEXT_CRITERIA: CJNE A, #4, ERROR_RESET ; If the number of * is 4(assmume password change mode). Else reset the input mode, as the input is invalid.
    SJMP WAIT ; If there is no number input, wait until the input finishes


ERROR_RESET:
    SETB P0.7 ; Turn on the segment
    MOV P1, #06H ; Print 'E.' at segment
    SJMP MAIN ; Reset


; Print the number of the input without '*' and '#'
PRINT_STATUS:
    MOV A, R2 ; Get the input count

FIND_IF_1: ; If the input count is 1
    DEC A ; Move to next number to compare
    JNZ FIND_IF_2 ; If the number is not 1, find if the number is 2
    MOV P1, #0FEH ; Turn on LED0, and turn off the other LEDs
    RET ; Return to Previous Function

FIND_IF_2: ; If the input count is 2
    DEC A ; Move to next number to compare
    JNZ FIND_IF_3 ; If the number is not 2, find if the number is 3
    MOV P1, #0FDH ; Turn on LED1, and turn off the other LEDs
    RET ; Return to Previous Function

FIND_IF_3: ; If the input count is 3
    DEC A ; Move to next number to compare
    JNZ FIND_IF_4 ; If the number is not 3, find if the number is 4
    MOV P1, #0FBH ; Turn on LED2, and turn off the other LEDs
    RET ; Return to Previous Function

FIND_IF_4: ; If the input count is 4
    DEC A ; Move to next number to compare
    JNZ FIND_IF_5 ; If the number is not 4, find if the number is 5
    MOV P1, #0F7H ; Turn on LED3, and turn off the other LEDs
    RET ; Return to Previous Function

FIND_IF_5: ; If the input count is 5
    DEC A ; Move to next number to compare
    JNZ FIND_IF_6 ; If the number is not 5, find if the number is 6
    MOV P1, #0EFH ; Turn on LED4, and turn off the other LEDs
    RET ; Return to Previous Function

FIND_IF_6: ; If the input count is 6
    DEC A ; Move to next number to compare
    JNZ FIND_IF_7 ; If the number is not 6, find if the number is 7
    MOV P1, #0DFH ; Turn on LED5, and turn off the other LEDs
    RET ; Return to Previous Function

FIND_IF_7: ; If the input count is 7
    DEC A ; Move to next number to compare
    JNZ FIND_IF_8 ; If the number is not 7, find if the number is 8
    MOV P1, #0BFH ; Turn on LED6, and turn off the other LEDs
    RET ; Return to Previous Function

FIND_IF_8: ; If the input count is 8
    DEC A ; Move to next number to compare
    JNZ NOT_FOUND ; If the number is not 8, return to previous function
    MOV P1, #07FH ; Turn on LED7, and turn off the other LEDs
    RET ; Return to Previous Function

NOT_FOUND: ; If the number is not 8, return to previous function
    RET ; Return to Previous Function


; Password Settings
SET_PASSWORD:
    MOV R0, #34H ; Move the pointer to first number
    MOV R1, #70H ; Move the pointer to first password location
SET_PASSWORD_LOOP: ; Loop until the password ends
    MOV A, @R0
    CJNE A, #'*', CONTIUNE_CHANGE ; If * was found, the password is now end
    MOV @R1, #0DH ; Put \r at the end of the password
    AJMP MAIN ; Reset the input
CONTIUNE_CHANGE:
    MOV @R1, A ; Save the password letter
    INC R0 ; Move to next letter
    INC R1
    SJMP SET_PASSWORD_LOOP ; Loop until the * was found at the input


; Compare the password with the one saved in 8051
COMPARE:
    MOV A, R2 ; Get the count of number input
    CLR C ; Clear Carry Bit to process subraction
    SUBB A, #4 ; Subtract by 4, if the input is less then 4, the carry bit will be 1
    JC ERROR_RESET ; Process the reset by wrong input

    MOV R0, #31H ; Move the pointer to first number
    MOV R1, #70H ; Move the pointer to first password location
COMPARE_LOOP: ; Loop until the password ends
    CLR C ; Clear carry bit to perfowm subtraction
    MOV A, @R0
    SUBB A, @R1 ; Find if there is a difference between 
    JNZ FIND_END ; If the password doesn't match, the password should be end
    INC R0 ; Move to next letter
    INC R1
    SJMP COMPARE_LOOP

FIND_END: ; Find if the password ends
    MOV A, @R0
    CJNE A, #'*', WRONG ; If the input letter is not * at the end, the password is wrong
    MOV A, @R1
    CJNE A, #0DH, WRONG ; If the password is not \r at the end, the password is wrong

    ; The Password is Right
    SETB P3.0 ; Turn on the Motor
    MOV P1, #0H ; Turn on all LED

    LJMP MAIN ; Reset the input

    
WRONG: ; If the password is wrong
    SETB P0.7 ; Turn on the segment
    MOV P1, #86H ; Print 'E' at segment
    LJMP MAIN ; Reset the input


; Clear the input value(Function)
CLEARCOMMAND:
    MOV R1, #30H ; Move the pointer to the start value
CLEARCOMMAND_CONTINUE:
    MOV @R1, #0H ; Clear the value
    INC R1 ; Move to next value
    CJNE R1, #60H, CLEARCOMMAND_CONTINUE ; Repeat until the pointer is 0x60 (Clear 0x30 - 0x5F)
    MOV 30H, #'*' ; Store '*' at 0x30, to prevent some errors by checking '*' was found at the first of the input value.
    RET


; Get and save the keypad input value(Function)
KEYPAD_CONTROL:
    LCALL KEYPAD_INPUT ; Get the Keypad value
    INC R0 ; Move to next memory
    MOV P0, #70H ; Set Keypad Detection Mode
WAIT_UNPRESSED: MOV A, P0
    CJNE A, #70H, WAIT_UNPRESSED ; Wait until the keypad undetectd
    RET


; Find the keypad input(Function)
KEYPAD_INPUT:
    MOV P0, #7FH ; Set Input Mode

    CLR P0.3 ; Scan 1 to 3
    JB P0.6, NEXT_2 ; If 1 was found, store the value, and return from the function
    MOV @R0, #1
    RET
NEXT_2: JB P0.5, NEXT_3 ; If 2 was found, store the value, and return from the function
    MOV @R0, #2
    RET
NEXT_3: JB P0.4, NEXT_4to6 ; If 3 was found, store the value, and return from the function
    MOV @R0, #3
    RET

NEXT_4to6:
    SETB P0.3 ; Stop scanning 1 to 3
    CLR P0.2 ; Scan 4 to 6
    JB P0.6, NEXT_5 ; If 4 was found, store the value, and return from the function
    MOV @R0, #4
    RET
NEXT_5: JB P0.5, NEXT_6 ; If 5 was found, store the value, and return from the function
    MOV @R0, #5
    RET
NEXT_6: JB P0.4, NEXT_7to9 ; If 6 was found, store the value, and return from the function
    MOV @R0, #6
    RET

NEXT_7to9:
    SETB P0.2 ; Stop scanning 4 to 6
    CLR P0.1 ; Scan 7 to 9
    JB P0.6, NEXT_8 ; If 7 was found, store the value, and return from the function
    MOV @R0, #7
    RET
NEXT_8: JB P0.5, NEXT_9 ; If 8 was found, store the value, and return from the function
    MOV @R0, #8
    RET
NEXT_9: JB P0.4, NEXT_REM ; If 9 was found, store the value, and return from the function
    MOV @R0, #9
    RET

NEXT_REM:
    SETB P0.1 ; Stop scanning 7 to 9
    CLR P0.0 ; Scan *, 0, and #
    JB P0.6, NEXT_0 ; If * was found, store the value, and return from the function
    MOV @R0, #'*'
    RET
NEXT_0: JB P0.5, NEXT_SHARP ; If 0 was found, store the value, and return from the function
    MOV @R0, #0
    RET
NEXT_SHARP: JB P0.4, UNDETECTED ; If # was found, store the value, and return from the function
    MOV @R0, #'#'
    RET

; If nothing was detected, store '#', to prevent error happening, and return from the function
UNDETECTED: MOV @R0, #'#'
    RET

END