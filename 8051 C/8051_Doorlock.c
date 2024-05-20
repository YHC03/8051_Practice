#include<reg51.h>
#include<string.h> // To use strlen(), strncmp(), strncat() functions


/*
 * 8051_Doorlock
 *
 * This is an 8051 C file
 *
 * Function: Perform a function of a doorlock device with 8051
 *
 * To use the unlock mode, press '*', press the numbers, and press '*' again. The initial password is 0000.
 * If the password correct, all of the LED will be turned on.
 * If the password does not correct, the segment will print 'E' without the dot of the segment. After that, the 8051 will send the wrong input to serial.
 *
 * To use the password change mode, press '*' 4 times, press the numbers, and press '*' 4 times again.
 * Then the password will be changed, while the segment printing two LEDs on the bottom of the LED.
 *
 * Press '#' anytime if you want to abort the input process. The segment will not print anything.
 *
 * If the input is invalid, the segment will print 'E' with the dot of the segment.
 *
 * If the input is '*', all of the LED will not be turned on.
 * If the input is a number, one of the LED will be turned on, starting from LED0(on P1.0) to LED7(on P1.7). If one of the LED was turned on, the other LEDs will be turned off.
 *
 * The number of the input number is 4 to 8.
 *
 * Based on EdSim51DI's unmodified circuit.
 *
 * This project uses Serial Input 0 at P3.1 port, and the baud rate is 4800 baud rate without a Parity Bit. The clock which the 8051 using is 11.0592MHz.
 *
 * Written by: YHC03
*/


// Define the maximum length of the input buffer. Maybe the maximum length is 16, with 8 '*' and 8 numbers.
#define BUFFER_LENGTH 16

// Port Definition
sfr PORT_0 = 0x80/*P0*/;
sbit OUT_REM = 0x80/*P0.0*/;
sbit OUT_789 = 0x81/*P0.1*/;
sbit OUT_456 = 0x82/*P0.2*/;
sbit OUT_123 = 0x83/*P0.3*/;
sbit IN_3 = 0x84/*P0.4*/;
sbit IN_2 = 0x85/*P0.5*/;
sbit IN_1 = 0x86/*P0.6*/;

sbit SEGMENT_ENABLE = 0x87/*P0.7*/;
sbit INTR1 = 0xB3/*P3.3*/;
sfr LED = 0x90/*P2*/;


/* getKeypadValue() Function
 *
 * Function: Find the value of the keypad detected, and wait until the keypad undetectd
 * No input and output variable
*/
unsigned char getKeypadValue()
{
	// Variables) output: the value to output
	unsigned char output = '#'; // Initialize with #(for reset the input mode) for the case with no input(Simultaneously clear the keypad)
		
	// Set the P0 at Port Reading Mode
	PORT_0 = 0x7F;
		
	// Find 1 to 3
	OUT_123 = 0;
	if(!IN_1)
	{
		output = '1';
		goto KEYPAD_FINAL_PROCESS;
	}else if(!IN_2){
		output = '2';
		goto KEYPAD_FINAL_PROCESS;
	}else if(!IN_3){
		output = '3';
		goto KEYPAD_FINAL_PROCESS;
	}
		
	// Find 4 to 6
	OUT_123 = 1;
	OUT_456 = 0;
	if(!IN_1)
	{
		output = '4';
		goto KEYPAD_FINAL_PROCESS;
	}else if(!IN_2){
		output = '5';
		goto KEYPAD_FINAL_PROCESS;
	}else if(!IN_3){
		output = '6';
		goto KEYPAD_FINAL_PROCESS;
	}
		
	// Find 7 to 9
	OUT_456 = 1;
	OUT_789 = 0;
	if(!IN_1)
	{
		output = '7';
		goto KEYPAD_FINAL_PROCESS;
	}else if(!IN_2){
		output = '8';
		goto KEYPAD_FINAL_PROCESS;
	}else if(!IN_3){
		output = '9';
		goto KEYPAD_FINAL_PROCESS;
	}
		
	// Find *, 0, and #
	OUT_789 = 1;
	OUT_REM = 0;
	if(!IN_1)
	{
		output = '*';
		goto KEYPAD_FINAL_PROCESS;
	}else if(!IN_2){
		output = '0';
		goto KEYPAD_FINAL_PROCESS;
	}else if(!IN_3){
		output = '#';
		goto KEYPAD_FINAL_PROCESS;
	}
		
	// After finding the key Deteced
KEYPAD_FINAL_PROCESS:
	PORT_0 = 0x70; // Reset P0 for get input value
	while(!INT1); // Wait until the Keypad Input Undetected
		
	// Return the output value
	return output;
}


void main()
{
	// Variables) value: input Buffer, curr: cursor for value[16] variable, commandNum: Number of * at value[16] variable, inputNum: Number of input Numbers at value[16] variable
	unsigned char value[BUFFER_LENGTH], curr = 0, commandNum = 0, inputNum = 0;
	// Variables) i: variable for Loop, password: the password
	unsigned char i = 0, password[9] = "0000"; // Reset the password with 0000
		
	PORT_0 = 0x70; // Reset P0 for get input value
	INTR1 = 1; // Set P3.3 at input mode
	SEGMENT_ENABLE = 0; // Disable the segment
	
	TMOD = 0x20; // Set Timer 1 Mode 2
	SCON = 0x40; // Set Serial Mode 1 without Serial Read
	TH1 = -6; // Set Timer 1 Setting at 4800 baud rate
	TL1 = -6; // Initialize the Timer 1
	TR1 = 1; // Turn on the Timer 1
	TI = 0; // Clear the Serial Write Flag
	
	// Clear the input buffer
	memset(value, '\0', sizeof(value));
	
	// Loop Forever
	while(1)
	{
		// Initialize curr, commandNum, inputNum, and the Input Buffer 
		curr = 0;
		commandNum = 0;
		inputNum = 0;
		memset(value, '\0', sizeof(value));
			
		// Loop Until the Keypad Input Finishes
		while(1)
		{
			// Wait until the Keypad Input Detected
			while(INTR1);
			
			// Get the Keypad Input Value
			value[curr++]=getKeypadValue();
					
			// Disable the segment
			SEGMENT_ENABLE = 0;
					
			// If the value is #, reset the input mode
			if(value[curr - 1] == '#')
			{ 
				commandNum = 254;
				break;
							
			// If the value is *, reset the LED indicating the Input Status
			}else if(value[curr - 1] == '*'){
				LED = 0xFF;
							
				// Increase the number of the *
				commandNum++;
							
			// If the value is a number
			}else{
				// If there is no * before the number, the command is invalid
				if(!commandNum){ break;}
							
				// Increase the number of the #
				inputNum++;
								
				// Turn on, or Move Left the LED that indicates the Input Status
				if(LED == 0xFF || LED == 0x86 || LED == 0x00 || LED == 0x77 || LED == 0x06)
				{
					// Turn on the first LED
					LED = 0xFE;
									
				}else{
					// Turn on the next LED, while turning off the ohter LEDs.
					LED = (LED << 1) + 1;
				}
			}
						
			// If the setting mode was found, exit the input loop
			if(commandNum == 8) { break; }
						
			// If the unlock mode was found, exit the input loop
			if(commandNum == 2 && inputNum) { break; }
						
			// If a invalid command (3 commandNum with a number input) was found, exit the input loop as invalid command
			if(commandNum == 3 && inputNum) { commandNum = 0; break; }
						
			// If a invalid command (5 or more commandNum without a number input) was found, exit the input loop as invalid command
			if(commandNum >= 5 && !inputNum) { commandNum = 0; break; }
						
			// If the inputNum exceed 8, exit the input loop as invalid command
			if(inputNum >= 9) { commandNum = 0; break; }
					
		}
				
				
		// If the unlock mode was found
		if(commandNum == 2 && inputNum >= 4)
		{
			// If the inputValue matches the password value
			if(!strncmp(password, value + 1, inputNum) && (inputNum == strlen(password)))
			{
				// Open the Gate by Turning on the whole LED
				LED = 0x00;
						
			}else{
				// Print 'E' without a dot on the segment, indicating the wrong input was found
				SEGMENT_ENABLE = 1; // Enable the segment
				LED = 0x86;
							
				// Send the wrong input value to Serial
				for(i = 0; i < inputNum; i++)
				{
					SBUF = *(value + i + 1); // Send the wrong input data
					while(!TI); // Wait until the serial send finishes
					TI = 0; // Clear the serial write flag
				}
				
				// Send ", " to distinguish the value with the other wrong input value			
				SBUF = ','; // Send ','
				while(!TI); // Wait until the serial send finishes
				TI = 0; // Clear the serial write flag
				SBUF = ' '; // Send ' '
				while(!TI); // Wait until the serial send finishes
				TI = 0; // Clear the serial write flag
			}
						
		// If the setting mode was found
		}else if(commandNum == 8 && inputNum >= 4){
			strncpy(password, value + 4, inputNum); // Set the password with the input value
			password[inputNum] = '\0'; // put '\0' to indicate the end of the password
				
			// Enable the segment
			SEGMENT_ENABLE = 0;

			LED = 0x77; // Set LED to indicate Password Setting is now Finished
					
		// If reseting the input
		}else if(commandNum == 254){
			// Cancel
			LED = 0xFF; // Clear LED
					
		// If the input is invalid
		}else{
			// Wrong Command
			SEGMENT_ENABLE = 1; // Enable the segment
			LED = 0x06; // Print 'E' with a dot on the segment, indicating the input is invalid
		}
	}
		
	return;
}