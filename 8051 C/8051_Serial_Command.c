#include<reg51.h>
#include<string.h> // To use strlen(), strcmp(), strtok() functions
#include<math.h> // To use pow() function

/* 8051_Serial_Command
 * 
 * Brief Function : Run commands, by Serial Input
 * 
 * Serial Functions
 * 
 * LED # ON : Turn on that led(0-7)
 * LED # OFF : Turn off that led(0-7)
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
 * 
 * # for number, @ for Alphabet
 * 
 * LED, Segment, Segment Enable, Segment change swiches are based on EdSim51DI's unmidified circuit.
 * Motor Forward is connacted at P3.6 port, Motor Reverse is connacted at P3.7 port.
 * 
 * This project uses Serial Input 0 at P3.1 port, and the baud rate is 4800 baud rate. The clock which the 8051 using is 11.0592MHz.
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


void main()
{
    // Variables) command: Serial Input Value(string), i: variable for repeat, cur: input cursor for command[30]
    unsigned char command[MAX_SERIAL_LENGTH], i, cur;

    // Variables) *(first, second, third)command: First, Second, Third Command seperated by blank
    unsigned char *firstCommand, *secondCommand, *thirdCommand;

    // Variable) targNum: Pin number to print
    unsigned char targNum;

    // segData: Constant that stores which data to print at segment
    const unsigned char segData[10] = { 0xC0, 0xF9, 0xA4, 0xB0, 0x99, 0x92, 0x82, 0xD8, 0x80, 0x90 };

    TMOD = 0x20; // Set Timer 1 Mode 2
    TH1 = -6; // 4800 baud rate
    TL1 = -6; // Set initial value at TL1
    SCON = 0x50; // Set Serial Mode 1 with Enabling Serial Read
    TR1 = 1; // Start Timer 1

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

            // Change Ascii value to number
            targNum = (*secondCommand) ^ 0x30;

            // Get the third command
            thirdCommand = strtok(NULL, " ");

            // Switch by the third command
            if(!strcmp(thirdCommand, "ON")) // If the third command is ON
            {
                // Turn on the LED selected by the second command
                setLED(targNum, 1);
            }else if(!strcmp(secondCommand, "OFF")){ // If the third command is OFF
                // Turn on the LED selected by the second command
                setLED(targNum, 0);
            } // If the third command is neither ON nor OFF, the command is an Error

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
                    LED_and_Segment_All = segData[targNum];
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
        }

    }

    return;
}