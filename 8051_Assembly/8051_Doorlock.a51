; 8051_Doorlock
;
; Function: Perform a function of a doorlock device with 8051
;
; To use the unlock mode, press '*', press the numbers, and press '*' again. The initial password is 0000.
; If the password correct, LED on P1.0 will be turned on, and Motor on P3.0, P3.1 will run forward.
; If the password does not correct, nothing will happen.
;
; To use the password change mode, press '*' 4 times, press the numbers, and press '*' 4 times again.
; Then the password will be changed.
;
; Press '#' anytime if you want to abort the input process. The segment will not print anything.
;
; If the input was detected, LED on P1.0 will be turned off, and Motor on P3.0, P3.1 will stop.
; But if the password correct, LED and Motor will be turned on as mentioned above, after turning off the LED and Motor by detection of the input.
; 
;
; Based on EdSim51DI's unmodified circuit with AND Gate Enabled settings.
;
;
; Written by: YHC03


; Memory Used
;
; R0(0x00): Pointer to store the input value
; R1(0x01): Pointer to read password to compare password, or reset the input value
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

    ; Set the Keypad with Input Mode
    MOV P0, #0F0H

    ; Move to Main Function

MAIN:
    LCALL CLEARCOMMAND ; Clear the input buffer
    MOV R0, #30H ; Reset the pointer for input
    MOV R7, #0 ; Reset the number of '*'
    
WAIT: JB P3.3, WAIT ; Wait until the Key Detected
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
    LJMP SET_PASSWORD ; Jump to SET_PASSWORD label


NUMBER_INPUT:
    MOV A, R7 ; Get the number of *
    CJNE A, #1, NEXT_CRITERIA ; If the number of * is 1(assume unlock mode). Else check is the mode is password change mode
    SJMP WAIT ; If there is no number input, wait until the input finishes
NEXT_CRITERIA: CJNE A, #4, MAIN ; If the number of * is 4(assmume password change mode). Else reset the input mode, as the input is invalid.
    SJMP WAIT ; If there is no number input, wait until the input finishes


; Password Settings
SET_PASSWORD:
    MOV R0, #34H ; Move the pointer to first number
    MOV R1, #70H ; Move the pointer to first password location
SET_PASSWORD_LOOP: ; Loop until the password ends
    MOV A, @R0
    CJNE A, #'*', CONTIUNE_CHANGE ; If * was found, the password is now end
    MOV @R1, #0DH ; Put \r at the end of the password
    SJMP MAIN ; Reset the input
CONTIUNE_CHANGE:
    MOV @R1, A ; Save the password letter
    INC R0 ; Move to next letter
    INC R1
    SJMP SET_PASSWORD_LOOP ; Loop until the * was found at the input


; Compare the password with the one saved in 8051
COMPARE:
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
    CLR P1.0 ; Turn on the LED

    LJMP MAIN ; Reset the input

    
WRONG: ; If the password wrong
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
    MOV P0, #0F0H ; Set Keypad Detection Mode
WAIT_UNPRESSED: MOV A, P0
    CJNE A, #0F0H, WAIT_UNPRESSED ; Wait until the keypad undetectd
    RET


; Find the keypad input(Function)
KEYPAD_INPUT:
    MOV P0, #0FFH ; Set Input Mode

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