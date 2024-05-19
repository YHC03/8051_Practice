#include<reg51.h>
#include<string.h> // To use strlen(), strcmp(), strtok() functions
#include<math.h> // To use pow() function

/* 8051_Serial_Command
 * 
 * This is an 8051 C file
 *
 * Brief Function : Run commands, by Serial Input
 * 
 * Serial Functions
 * 
 * LED # ON : Turn on that led(0-7)
 * LED # OFF : Turn off that led(0-7)
 * LED BLINK ### : Blink all LED at machine cycle of the specific number(0-255)
 * LED BLINK STOP : Stop Blinking all LED
 * SEGMENT ENABLE : Enable the Segment
 * SEGMENT DISABLE : Disable the Segment
 * SEGMENT USE # : Switch Segment Output to the number(0-3)
 * SEGMENT PRINT # : Print the number(0-9) at Segment
 * SEGMENT @ ON : Turn on that segment. Dot at the Segment can be turned on by typing H.
 * SEGMENT @ OFF : Turn off that segment. Dot at the Segment can be turn on by typing H.
 * MOTOR FORWARD : Run the Motor Forward
 * MOTOR REVERSE : Run the Motor Reverse
 * MOTOR BACKWARD : Run the Motor Backward
 * MOTOR STOP : Stop the Motor
 * KEYPAD SEGMENT : Scan the Keypad, and print the result on the segment
 * KEYPAD LED ON : Scan the Keypad, and turn on the LED of the specific number pressed at the Keypad
 * KEYPAD LED OFF : Scan the Keypad, and turn off the LED of the specific number pressed at the Keypad
 * KEYPAD UART : Scan the Keypad, and print the result at the UART.
 * 
 * # for number, @ for Alphabet
 * 
 * 
 * LED, Segment, Segment Enable, Segment change, Segment, Keypad swiches are based on EdSim51DI's unmodified circuit.
 * Motor Forward is connected at P3.6 port, Motor Reverse is connected at P3.7 port.
 * 
 * This project uses Serial Input 0 at P3.1 port, and the baud rate is 4800 baud rate without a Parity Bit. The clock which the 8051 using is 11.0592MHz.
 * 
 * Written By: YHC03
*/




// set the max number of letters of the serial input command
#define MAX_SERIAL_LENGTH 30

sbit LED_and_Segment_Pin0 = 0x90/*P2.0 port*/; // LED & Segment Pin 0
sbit LED_and_Segment_Pin1 = 0x91/*P2.1 port*/; // LED & Segment Pin 1
sbit LED_and_Segment_Pin2 = 0x92/*P2.2 port*/; // LED & Segment Pin 2
sbit LED_and_Segment_Pin3 = 0x93/*P2.3 port*/; // LED & Segment Pin 3
sbit LED_and_Segment_Pin4 = 0x94/*P2.4 port*/; // LED & Segment Pin 4
sbit LED_and_Segment_Pin5 = 0x95/*P2.5 port*/; // LED & Segment Pin 5
sbit LED_and_Segment_Pin6 = 0x96/*P2.6 port*/; // LED & Segment Pin 6
sbit LED_and_Segment_Pin7 = 0x97/*P2.7 port*/; // LED & Segment Pin 7
sfr LED_and_Segment_All = 0x90/*P2 port*/; // LED & Segment Port(All)

sbit segment_Switch = 0x87/*P0.7 port*/; // Segment Print Enable Switch
sbit segment_SW0 = 0xB3/*P3.3 port*/; // Segment Change Switch 0
sbit segment_SW1 = 0xB4/*P3.4 port*/; // Segment Change Switch 1
sbit motor_FORWARD = 0xB6/*P3.6 port*/; // Motor Forward Switch
sbit motor_REVERSE = 0xB7/*P3.7 port*/; // Motor Reverse Switch

sbit KEYPAD_Y1 = 0x86/*P0.6 port*/; //Keypad Y1
sbit KEYPAD_Y2 = 0x85/*P0.5 port*/; //Keypad Y2
sbit KEYPAD_Y3 = 0x84/*P0.4 port*/; //Keypad Y3
sbit KEYPAD_X1 = 0x83/*P0.3 port*/; //Keypad X1
sbit KEYPAD_X2 = 0x82/*P0.2 port*/; //Keypad X2
sbit KEYPAD_X3 = 0x81/*P0.1 port*/; //Keypad X3
sbit KEYPAD_X4 = 0x80/*P0.0 port*/; //Keypad X4


/* segmentNumChange() Function
 *
 * Function: Change the Number of the segment to enable
 * Input variable: num(Number of the segment to enable)
 * No output variable
*/
void segmentNumChange(unsigned char num)
{
    // Switch by the input value
    switch(num)
    {
    case 0: // If the input value is 0
        // Use Segment 0 for printing value
        segment_SW0 = 0;
        segment_SW1 = 0;
        break;

    case 1: // If the input value is 1
        // Use Segment 1 for printing a value
        segment_SW0 = 1;
        segment_SW1 = 0;
        break;

    case 2: // If the input value is 2
        // Use Segment 2 for printing a value
        segment_SW0 = 0;
        segment_SW1 = 1;
        break;

    case 3: // If the input value is 3
        // Use Segment 3 for printing a value
        segment_SW0 = 1;
        segment_SW1 = 1;
        break;
    }

    return;
}


/* setLED() Function
 *
 * Function: Print the value of command on selected LED
 * Input variables: port(Number of LED to use), command(Command for the LED, 1 to On and 0 to Off)
 * No output variable
*/
void setLED(unsigned char port, unsigned char command)
{
    // Switch by the variable port
    switch(port)
    {
    case 0: // If the value is 0
        // Print the inversed value of command at port 0
        LED_and_Segment_Pin0 = !command;
        break;

    case 1: // If the value is 1
        // Print the inversed value of command at port 1
        LED_and_Segment_Pin1 = !command;
        break;

    case 2: // If the value is 2
        // Print the inversed value of command at port 2
        LED_and_Segment_Pin2 = !command;
        break;

    case 3: // If the value is 3
        // Print the inversed value of command at port 3
        LED_and_Segment_Pin3 = !command;
        break;

    case 4: // If the value is 4
        // Print the inversed value of command at port 4
        LED_and_Segment_Pin4 = !command;
        break;

    case 5: // If the value is 5
        // Print the inversed value of command at port 5
        LED_and_Segment_Pin5 = !command;
        break;

    case 6: // If the value is 6
        // Print the inversed value of command at port 6
        LED_and_Segment_Pin6 = !command;
        break;

    case 7: // If the value is 7
        // Print the inversed value of command at port 7
        LED_and_Segment_Pin7 = !command;
        break;
    }

    return;
}


/* getEnabledKey() Function
 *
 * Function: Get and return the number of the keypad pressed
 * No input variable
 * Output variable: the number of the keypad pressed (0-9 for specific number, 0x0A for *, 0x0B for #,0x0C for nothing pressed)
*/
unsigned char getEnabledKey()
{
    // Initialize the Keypad Settings
    KEYPAD_X1 = 1;
    KEYPAD_X2 = 1;
    KEYPAD_X3 = 1;
    KEYPAD_X4 = 1;

    // Set Keypad State Input Mode
    KEYPAD_Y1 = 1;
    KEYPAD_Y2 = 1;
    KEYPAD_Y3 = 1;

    // Scan 1-3
    KEYPAD_X1 = 0;
    if(!KEYPAD_Y1){return 1;}
    if(!KEYPAD_Y2){return 2;}
    if(!KEYPAD_Y3){return 3;}

    // Scan 4-6
    KEYPAD_X1 = 1;
    KEYPAD_X2 = 0;
    if(!KEYPAD_Y1){return 4;}
    if(!KEYPAD_Y2){return 5;}
    if(!KEYPAD_Y3){return 6;}

    // Scan 7-9
    KEYPAD_X2 = 1;
    KEYPAD_X3 = 0;
    if(!KEYPAD_Y1){return 7;}
    if(!KEYPAD_Y2){return 8;}
    if(!KEYPAD_Y3){return 9;}

    // Scan *, 0, and #
    KEYPAD_X3 = 1;
    KEYPAD_X4 = 0;
    if(!KEYPAD_Y1){return 0x0A;}
    if(!KEYPAD_Y2){return 0;}
    if(!KEYPAD_Y3){return 0x0B;}

    // Reset the Keypad Settings
    KEYPAD_X4 = 1;

    // Return 0x0C that nothing was pressed
    return 0x0C;
}


/* Blink_LED() Function
 *
 * Function: Process the LED blinking
 * No input and output variable
*/
void Blink_LED() interrupt 1
{
    // Inverse the LED state
    LED_and_Segment_All = ~LED_and_Segment_All;

    return;
}


/* getInputNum() Function
 *
 * Function: Get the number from the string of the last
 * Input variable: The string to find the number
 * Output variable: The number the string indicates
*/
unsigned char getInputNum(unsigned char* input)
{
    // Variables) result: The result, pointer: the pointer of the string
    unsigned char result = 0, pointer = 0;
    
    // Loop until the string ends
    while(*(input + pointer) != '\0')
    {
        // Multiply 10, to make the previous number is actually 10 times bigger
        result *= 10;

        // Add number at the current pointer of the string
        result += *(input+pointer) ^ 0x30;

        // Increse the string pointer
        pointer++;
    }

    // Return the result
    return result;
}


void main()
{
    // Variables) command: Serial Input Value(string), i: variable for repeat, cur: input cursor for command[30]
    unsigned char command[MAX_SERIAL_LENGTH], i, cur;

    // Variables) *(first, second, third)command: First, Second, Third Command seperated by blank
    unsigned char *firstCommand, *secondCommand, *thirdCommand;

    // Variables) targNum: Pin number to print, Key_Input: get the key Input
    unsigned char targNum, Key_Input;

    // SEGMENT_DATA: Constant that stores which data to print at segment (*: A, #: B, Nothing Input: No Output)
    const unsigned char SEGMENT_DATA[13] = { 0xC0, 0xF9, 0xA4, 0xB0, 0x99, 0x92, 0x82, 0xD8, 0x80, 0x90, 0x88, 0x83, 0xFF };

    // Reset the Segment Switch
    segment_SW0 = 0;
    segment_SW1 = 0;
    
    // Reset the Motor
    motor_FORWARD = 0;
    motor_REVERSE = 0;

    TMOD = 0x22; // Set Timer 0 Mode 2, Timer 1 Mode 1
    TH1 = -6; // 4800 baud rate
    TL1 = -6; // Set initial value at TL1
    SCON = 0x50; // Set Serial Mode 1 with Enabling Serial Read
    TR1 = 1; // Start Timer 1
    IE = 0x82; // Interrupt 1 Enable

    // Initialize the value of variable command
    for(i = 0; i < MAX_SERIAL_LENGTH; i++)
        command[i]='\0';
    
    // Loop Forever
    while(1)
    {
        // Reset cursor for input value
        cur = 0;

        // Loop Until the input finishes
        while(1)
        {
            // Wait Until the input finish
            while(!RI);

            // Reset Serial Input Bit
            RI = 0;

            // Get value of SBUF, and increase cursor
            command[cur++] = SBUF;

            // If the input letter is small letter, change with capital letter
            if(command[cur-1] >= 'a' && command[cur-1] <= 'z')
            {
                command[cur-1] -= 'a' - 'A';
            }

            // If the command input finish
            if(command[cur-1] == '\r')
            {
                // Mark end on the last value, instead of \r
                command[cur-1] = '\0';

                // Exit the loop for input
                break;
            }

            // If the command input exceeds the variable's size
            if(cur >= MAX_SERIAL_LENGTH)
            {
                // Clear Serial Buffer
                do{
                    // Wait Until the input finish
                    while(!RI);

                    // Reset Serial Input Bit
                    RI = 0;

                    // Get serial value at the last value of variable command
                    command[cur-1] = SBUF;

                }while(command[cur-1] != '\r'); // Loop until the last value was processed

                // Mark end on the last value, instead of \r
                command[cur-1] = '\0';

                // Exit the loop for input
                break;
            }
        }

        // Get the first command
        firstCommand = strtok(command, " ");

        // Switch by the first command, LED, SEGMENT, and MOTOR
        if(!strcmp(firstCommand, "LED")) // If the first command is LED
        {
            // Get the second command
            secondCommand = strtok(NULL, " ");

            if(!strcmp(secondCommand, "BLINK")) // If the second command is Blink
            {
                // Get the third command
                thirdCommand = strtok(NULL, " ");

                // If the third command is STOP
                if(!strcmp(thirdCommand, "STOP"))
                {
                    // Stop Timer 0
                    TR0 = 0;
                }else{
                    // Change Ascii value to number
                    targNum = getInputNum(thirdCommand);

                    // Set the data to timer 0
                    TH0 = 0xFF - targNum;
                    TL0 = 0xFF - targNum;

                    // Start Timer 0
                    TR0 = 1;
                }
            }else{ // If the second command is a number

                // Change Ascii value to number
                targNum = (*secondCommand) ^ 0x30;

                // Get the third command
                thirdCommand = strtok(NULL, " ");

                // Switch by the third command
                if(!strcmp(thirdCommand, "ON")) // If the third command is ON
                {
                    // Turn on the LED selected by the second command
                    setLED(targNum, 1);
                }else if(!strcmp(thirdCommand, "OFF")){ // If the third command is OFF
                    // Turn on the LED selected by the second command
                    setLED(targNum, 0);
                } // If the third command is neither ON nor OFF, the command is an Error
            }

        }else if(!strcmp(firstCommand, "SEGMENT")){ // If the first command is SEGMENT

            // Get the second command
            secondCommand = strtok(NULL, " ");

            // Switch by the second command
            if(!strcmp(secondCommand, "ON")) // If the second command is ON
            {
                // Enable Segment
                segment_Switch = 1;

            }else if(!strcmp(secondCommand, "OFF")){ // If the second command is OFF
                // Disable Segment
                segment_Switch = 0;

            }else if(!strcmp(secondCommand, "USE")){ // If the second command is USE
                // Get the third command
                thirdCommand = strtok(NULL, " ");

                // Change Ascii value to number
                targNum = (*thirdCommand) ^ 0x30;

                // Change the segment to print the value
                segmentNumChange(targNum);

            }else if(!strcmp(secondCommand, "PRINT")){ // If the second command is PRINT
                // Get the third command
                thirdCommand = strtok(NULL, " ");

                // Change Ascii value to number
                targNum = (*thirdCommand) ^ 0x30;

                // If the Number is 0 to 9, print the value on segment. Otherwise, the command is an Error
                if(targNum >= 0 && targNum <= 9 && strlen(thirdCommand) == 1)
                {
                    // Print the value on segment
                    LED_and_Segment_All = SEGMENT_DATA[targNum];
                }

            }else if(*secondCommand >= 'A' && *secondCommand <= 'H' && strlen(secondCommand) == 1){ // If the second command is an Alphabet
                // Change the Alphabet to number to print
                targNum = *secondCommand - 'A';

                // Get the third command
                thirdCommand = strtok(NULL, " ");

                // Switch by the third command
                if(!strcmp(thirdCommand, "ON")) // If the third command is 1
                {
                    // Turn on the LED
                    setLED(targNum, 1);

                }else if(!strcmp(thirdCommand, "OFF")){ // If the third command is 0
                    // Turn off the LED
                    setLED(targNum, 0);
                }
            }

        }else if(!strcmp(firstCommand, "MOTOR")){ // If the first command is MOTOR

            // Get the second command
            secondCommand = strtok(NULL, " ");

            // Switch by the second command
            if(!strcmp(secondCommand, "FORWARD")) // If the second command is FORWARD
            {
                // Set the motor as forward running mode
                motor_FORWARD = 1;
                motor_REVERSE = 0;

            }else if(!strcmp(secondCommand, "REVERSE") || !strcmp(secondCommand, "BACKWARD")){ // If the second command is REVERSE or BACKWARD
                // Set the motor as reverse running mode
                motor_FORWARD = 0;
                motor_REVERSE = 1;

            }else if(!strcmp(secondCommand, "STOP")){ // If the second command is STOP
                // Stop the motor
                motor_FORWARD = 0;
                motor_REVERSE = 0;
            }

        }else if(!strcmp(firstCommand, "KEYPAD")){ // If the first command is KEYPAD

            // Get the second command
            secondCommand = strtok(NULL, " ");
            
            if(!strcmp(secondCommand, "SEGMENT"))
            {
                // Set the segment by the value of the keypad
                LED_and_Segment_All = SEGMENT_DATA[getEnabledKey()];

            }else if(!strcmp(secondCommand, "LED")){ // If the second command is LED
            	// Get the third command
		thirdCommand = strtok(NULL, " ");
				
		// Switch by the third command
                if(!strcmp(thirdCommand, "ON")) // If the third command is 1
                {
                    // Turn on the LED by the value of the keypad
                    setLED(getEnabledKey(), 1);

                }else if(!strcmp(thirdCommand, "OFF")){ // If the third command is 0
                    // Turn off the LED by the value of the keypad
                    setLED(getEnabledKey(), 0);
                }

            }else if(!strcmp(secondCommand, "UART")){ // If the second command is UART
                // Get the value of the keypad
                Key_Input = getEnabledKey();

                if(Key_Input <= 0x0C) // If the Input value is vaild
                {
                    // If the input is * or #
                    if(Key_Input == 0x0B) // If the input is #
                    {
                        Key_Input = '#';
                    }else if(Key_Input == 0x0A){ // If the input is *
                        Key_Input = '*';
                    }else{ // If the input is a number
                        Key_Input = Key_Input ^ 0x30;
                    }
                    
                    // Send the data to Serial Output
                    SBUF = Key_Input;

                    // Wait Until the output finish
                    while(!TI);

                    // Reset Serial Output Bit
                    TI = 0;
                }
            }
        }

    }

    return;
}