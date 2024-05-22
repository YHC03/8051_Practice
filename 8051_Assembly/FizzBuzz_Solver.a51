; 8051 FizzBuzz Problem Solver
;
; Function: Get a number(0 to 255) by Serial Input, and print the value at the Serial, under following conditions.
; If the number can be divided by 3 without remainder, print "Fizz".
; If the number can be divided by 5 without remainder, print "Buzz".
; If the number can be divided by both 3 and 5 without remainder, print "FizzBuzz".
; Otherwise, print the number.
; Repeat this at the natural number from 1 to the input. If the input is 0, do nothing.
;
; The 8051 Serial Baud Rate is 4800 baud rate at 11.0592MHz Clock.
;
; <Known Bugs>
; This program can get multiple values from Serial input, separated by line.
; However, sometimes this program does not work or work inproperly if the time for process is too long.
;
; Creator: YHC03


; <Information of Variables>
; R4: Variable for print "Fizz" and "Buzz", and indicate there is no print of "Fizz" and "Buzz" at the number if the value of R4 is 0.
; R6: Variable for process input value of Serial input, and counting up from 1 to input value.
; R7: Variable for store the input value.
; Bit Addressable RAM 0x7F (MSB of 0x2F): Indicate if the value to print is greater than 100.

ORG 0H
LJMP INIT ; Jump to INIT Function

ORG 30H
INIT:
    MOV SCON, #50H ; Serial 0 Mode 1 with Input Enabled
    MOV TMOD, #20H ; Timer 1 Mode 2
    MOV TH1, #-6 ; Set baud rate to 4800
    MOV TL1, #-6 ; Initialize the Timer 1
    SETB TR1 ; Enable Timer 1
    SJMP MAIN ; Move to Main Function

MAIN:
    MOV R7, #0H ; Reset the input number
WAIT_READ: JNB RI, WAIT_READ ; Wait until Serial Input is found
    CLR RI ; Clear Serial Read Flag

    MOV A, SBUF ; Move Serial data to A
    CJNE A, #0DH, LINE_FINISHED_CHECK ; If the Serial data is '\r', process the calculation

    ; Check if the input is 0. If the input is 0, reset the process.
    MOV A, R7
    JZ MAIN

    ACALL PROCESS ; Process the calculation
    SJMP MAIN ; Reset the process

LINE_FINISHED_CHECK: CJNE A, #0AH, PROCESS_NUMBER ; If the Serial data is '\n', process the calculation
    
    ; Check if the input is 0. If the input is 0, reset the process.
    MOV A, R7
    JZ MAIN

    ACALL PROCESS ; Process the calculation
    SJMP MAIN ; Reset the process

PROCESS_NUMBER:
    XRL A, #30H ; ASCII to BCD
    MOV R6, A ; Move the data to R6, the temporary register
    MOV A, R7 ; Move original data on R7 to A
    MOV B, #10
    MUL AB ; Multiply original data with 10
    ADD A, R6 ; Add the Serial data with previous calculation
    MOV R7, A ; Save the calculation data on R7
    SJMP WAIT_READ ; Wait for next input


; Function for process the calculation
PROCESS:
    MOV R6, #0H ; Initialize the Register for counting up by 1, from 1 to input value. This register starts at 0 because it will immediately increase at 1 at the next statement.

PROCESS_LOOP:
    INC R6 ; Increse the register for count
    MOV R4, #0 ; Initialize the Register for print "Fizz" and "Buzz", with the function of indicating there is no print at current number at R6.
    ; If R4 is 0, there is no print at current number at R6. If R4 is 4, there is a print at current number at R6.

    ; Divide the current number at R6 with 3
    MOV A, R6
    MOV B, #3
    DIV AB

    ; Find if there is no remainder at previous division. If there is no remainder, print "Fizz"
    MOV A, B
    JNZ BUZZ_COMPARE
    ACALL FIZZ_PRINT

    ; Divide the current number at R6 with 5
BUZZ_COMPARE:
    MOV A, R6
    MOV B, #5
    DIV AB

    ; Find if there is no remainder at previous division. If there is no remainder, print "Buzz"
    MOV A, B
    JNZ NUMBER_WRITE
    ACALL BUZZ_PRINT

    ; Find if there is no print at the current number at R6. If there is no print at the current number at R6, print R6.
NUMBER_WRITE:
    MOV A, R4
    JNZ LAST_PROCESS
    ACALL NUMBER_PRINT

    ; Print '\n' at Serial, to print the next number at next line.
LAST_PROCESS:

    MOV SBUF, #0AH
    JNB TI, $
    CLR TI

    ; If R6 is the same as input number, finalize the print. Otherwise, move to the next number. 
    MOV A, R6
    CJNE A, 07H, PROCESS_LOOP

    ; Print '-' 4 times
    MOV R6, #4
PRINT_SEPARATION_LOOP:
    MOV SBUF, #'-'
    JNB TI, $
    CLR TI
    DJNZ R6, PRINT_SEPARATION_LOOP

    ; Print '\n', to print the result of the next input
    MOV SBUF, #0AH
    JNB TI, $
    CLR TI

    ; Return to original function
    RET


; Print "Fizz"
FIZZ_PRINT:
    MOV R4, #0 ; Reset the loop count variable
    MOV DPTR, #STRING_FIZZ ; Get the string data of "Fizz"
FIZZ_PRINT_LOOP:
    ; Get the current pointer of the string "Fizz"
    MOV A, R4
    MOVC A, @A+DPTR

    ; Print the data, processed by the previous statement
    MOV SBUF, A
    JNB TI, $
    CLR TI

    ; Move th next pointer
    INC R4

    ; If print is not finished, print next data
    CJNE R4, #4, FIZZ_PRINT_LOOP

    ; Return to previous function
    RET


; Print "Buzz"
BUZZ_PRINT:
    MOV R4, #0 ; Reset the loop count variable
    MOV DPTR, #STRING_BUZZ; Get the string data of "Buzz"
BUZZ_PRINT_LOOP:
    ; Get the current pointer of the string "Buzz"
    MOV A, R4
    MOVC A, @A+DPTR

    ; Print the data, processed by the previous statement
    MOV SBUF, A
    JNB TI, $
    CLR TI

    ; Move th next pointer
    INC R4

    ; If print is not finished, print next data
    CJNE R4, #4, FIZZ_PRINT_LOOP

    ; Return to previous function
    RET


; Print the nuber stored at R6
NUMBER_PRINT:
    ; Clear the 0x7F Bit Address RAM for check if R6 is greater than 100
    CLR 7FH

    ; Get the value of 10^2 digit of R6 at A, and the remaider of R6 divide 100 at B
    MOV A, R6
    MOV B, #100
    DIV AB

    ; If the value of 10^2 digit is 0, move to 10^1 digit
    JZ PRINT_10

    ; Convert BCD to ASCII
    XRL A, #30H

    ; Print the value to Serial
    MOV SBUF, A
    JNB TI, $
    CLR TI

    ; Check that R6 is greater than 100
    SETB 7FH


PRINT_10:
    ; Get the value of 10^1 digit of R6 at A, and the remaider of R6 divide 10 at B
    MOV A, B
    MOV B, #10
    DIV AB

    ; If the value of both 10^2 and 10^1 digit is 0, move to 10^0 digit
    JNZ WRITE_10
    JNB 7FH, PRINT_1

WRITE_10:
    ; Convert BCD to ASCII
    XRL A, #30H

    ; Print the value to Serial
    MOV SBUF, A
    JNB TI, $
    CLR TI

PRINT_1:
    ; Get the value of 10^0 digit of R6 at A
    MOV A, B

    ; Convert BCD to ASCII
    XRL A, #30H

    ; Print the value to Serial
    MOV SBUF, A
    JNB TI, $
    CLR TI

    ; Return to previous function
    RET


; Save the data of the string "Fizz" and "Buzz"
ORG 700H
STRING_FIZZ: DB "Fizz"
STRING_BUZZ: DB "Buzz"

END