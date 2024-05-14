#include<reg51.h>

/*
 * 8051Clock
 * 
 * This is a 8051 C file
 *
 * Based on EdSim51DI's Original Circuit
 *
 * Inputs: P2.0, P2.1
 * Outputs: P0.7(Segment Enable), P1(Segment Output), P3.3 & P3.4(Segment Select)
 *
 * Written By: YHC03
 * Create Date: 2024/5/14
 * Last Modified Date: 2024/5/14
*/


// The minute and second of this Clock
unsigned char minute = 0;
unsigned char second = 0;


// Define Switches
sbit enterSwitch = 0xA0;
sbit plusSwitch = 0xA1;


/*
 * increaseSecond() function
 *
 * Function: Increase a second at clock running mode
 * No input and output variables
*/
void increaseSecond()
{
		// First, increase a second
		second++;
		
		// Second, if the second equals 60, increase a minute, and reset the second 
		if(second == 60)
		{
				minute++;
				second = 0;
				
				// If the minute equals, 60, reset the minute
				if(minute >= 60)
				{
						minute = 0;
				}
		}
		return;
}


/*
 * TIMER_0_INTERRUPT() function
 *
 * Called When Timer 0 Interrupt Occurs
 * Function: Count when a seconds goes & Call increaseSecond() function when a second goes
 * No input and output variables
*/
void TIMER_0_INTERRUPT() interrupt 2
{
		// To run 1 second, we have to run this interrupt 16 times
		static unsigned char remaining = 16; // remainings to get 1 second
	
		// Reset the timer
		TL0 = 0xDD;
		TH0 = 0x0B;
	
		// Decrease remaining
		remaining--;
	
		// If the remaining equals to 0, increase the second, and reset the remaining
		if(!remaining)
		{
				remaining = 16;
				increaseSecond();
		}
	
		return;
}


/*
 * print() function
 *
 * Function: Print the clock data to the segments
 * Input variable : mode(0 for Clock Running Mode, 1 for Setting Minute, 2 for Setting Second)
 * No output variable
*/
void print(char mode)
{
		// the data of segment
		const unsigned char segData[10] = { 0xC0, 0xF9, 0xA4, 0xB0, 0x99, 0x92, 0x82, 0xD8, 0x80, 0x90 };
	
		// Get the segment data first - as getting the segment data takes much more time than switching the segment
		
		// If the mode is 2, the mode is changing the second, so put dot on second data
		P1 = segData[second%10] - (mode == 2 ? 0x80 : 0);
		P3 = 0xE7; // Use Segment #0
	
		P1 = segData[second/10];
		P3 = 0xEF; // Use Segment #1
		
		// If the mode is 1, the mode is changing the minute, so put dot on minute data
		P1 = segData[minute%10] - (mode == 1 ? 0x80 : 0);
		P3 = 0xF7; // Use Segment #2
	
		P1 = segData[minute/10];
		P3 = 0xFF; // Use Segment #3
	
		return;
}


/*
 * settings() function
 *
 * Function: Do the clock settings
 * No input and output variables
*/
void settings()
{
		// Wait until the enter switch is not pressed
		while(!(enterSwitch)){print(0);}
		
		// Loop until the enter switch is pressed
		while(enterSwitch)
		{
				// Print the changing minute mode
				print(1);
				
				if(!(plusSwitch)) // If Plus Switch Pressed
				{
						// Increase minute. If the minute equals 60, change the minute to 0.
						minute++;
						if(minute==60){minute = 0;}
						
						while(!(plusSwitch)){print(1);} // Wait until the plus switch is not pressed
				}
		}
		
		// Wait until the enter switch is not pressed
		while(!(enterSwitch)){print(1);}
		
		// Loop until the enter switch is pressed
		while(enterSwitch)
		{
				// Print the changing minute mode
				print(2);
				
				if(!(plusSwitch)) // If Plus Switch Pressed
				{
						// Increase second. If the second equals 60, change the second to 0.
						second++;
						if(second==60){second = 0;}
						
						while(!(plusSwitch)){print(2);} // Increase minute. If the minute equals 60, change the minute to 0.
				}
		}
		
		// Wait until the enter switch is not pressed
		while(!(enterSwitch)){print(2);}
		
		return;
}


void main()
{
		// Initial Setup
		P0 |= 0x80; // Enable 7 segment
		P2 |= 0x03; // Enable Button on P2.0 and P2.1
		TMOD = 0x01; // Set Timer 0 Mode 1
		TL0 = 0xDD; // Set TL0
		TH0 = 0x0B; // Set TH0
		TF0 = 0; // Clear TF0
		IE = 0x82; // Enable Timer Interrupt 0
		TR0 = 1; // Start Timer
		
		// Infinite Loop
		while(1)
		{
				print(0); // Print the minute and second data to segment
				if(!(enterSwitch))
				{
						TR0 = 0; // Pause Timer
						TF0 = 0; // Clear TF0
						settings(); // Goes to Setting Mode
						
						TL0 = 0xDD; // Reset TL0
						TH0 = 0x0B; // Reset TH0
						TR0 = 1; // Start Timer
				}
		}
		
		return;
}