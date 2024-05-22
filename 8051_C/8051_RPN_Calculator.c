#include<reg51.h>
/*
* Reverse Polish Notation Calculator
* Function: 2-Digit Number Calculation
*
* Written By: YHC03
*
* This is an 8051 C File
* Based on EdSim51DI's Unmodified Circuit
*
* Switches
* P0.0-6: Keypad(to Input Numbers)
* P2.0: Enter (Unused When Operator Input Mode)
* P2.4: Add
* P2.3: Subtract
* P2.2: Multiply
* P2.1: Divide
*
* Create Date : 24/4/25
* Update Date : 24/5/2
*
*/

// Mode for Calculator(0: Input1, 1: Input2, 2: Operand, 3: Answer)
unsigned char mode = 0;
// Input data
unsigned char dat[2] = {0, 0};
// Result
int result = 0;
// Location of decimal point, especially for divide operation
unsigned char dotLocation=0;

// Define Input Pin
sbit ENTER = 0xA0; // P2.0
sbit PLUS = 0xA4; // P2.4
sbit MINUS = 0xA3; // P2.3
sbit MULTIPLY = 0xA2; // P2.2
sbit DIVIDE = 0xA1; // P2.1

// Setup For Input Pin
void setup()
{
	P2 = 0x1F;
	P0 = 0xFF;
}

// Print value to segment
void printSeg()
{
	// Segment Output Data
	const unsigned char segData[10] = { 0xC0, 0xF9, 0xA4, 0xB0, 0x99, 0x92, 0x82, 0xD8, 0x80, 0x90 };
	
	/*
	* Value to print, differ by mode
	*
	* mode 0 -> Print dat[0]
	* mode 1 -> Print dat[1]
	* mode 2 -> Print dot on LSB
	* mode 3 -> Print result, if result < 0, only 2 segemts are used to represent numbers
	*/
	
	// Tmp is a variable for a number to print at the segment
	unsigned char tmp = 0;
	
	// Print datum differs from the mode
	switch(mode)
	{
	case 0:
		// 10^0 digit of input number #1
		tmp = dat[0] % 10;
		P3 = 0xE7; // Use Segment #0
		P1 = segData[tmp];
		
		// 10^1 digit of input number #1
		tmp = (unsigned char)(dat[0] / 10);
		P3 = 0xEF; // Use Segment #1
		P1 = segData[tmp];
		
		return;
		
	case 1:
		// 10^0 digit of input number #2
		tmp = dat[1] % 10;
		P3 = 0xE7; // Use Segment #0
		P1 = segData[tmp];
		
		// 10^1 digit of input number #2
		tmp = (unsigned char)(dat[1] / 10);
		P3 = 0xEF; // Use Segment #1
		P1 = segData[tmp];
		
		return;
	case 2:
		// Just print . on segment #0
		P3 = 0xE7;
		P1 = 0x7F;
		
		return;
	case 3:
		// Print just 2 digits when the result is less then 0, as 0-99=-99
		if(result<0)
		{
			// 10^0 digit of the output number
			tmp = (unsigned char)((-result) % 10);
			P3 = 0xE7; // Use Segment #0
			P1 = segData[tmp];
			
			// 10^1 digit of the output number
			tmp = (unsigned char)(((-result) / 10) % 10);
			P3 = 0xEF; // Use Segment #1
			P1 = segData[tmp];
			
			// Print - on the second segment
			P3 = 0xF7; // Use Second Segment
			P1 = 0xBF; // Print -

		}else{
			// 10^0 digit of the output number
			P3 = 0xE7; // Use Segment #0
			tmp = (unsigned char)(result % 10);
			P1 = segData[tmp] - (dotLocation == 0 ? 0x80 : 0x00); // If dotLocation is same as the segment, also print a dot.
			
			// 10^1 digit of the output number
			tmp = (unsigned char)((result / 10) % 10);
			P3 = 0xEF; // Use Segment #1
			P1 = segData[tmp] - (dotLocation == 1 ? 0x80 : 0x00); // If dotLocation is same as the segment, also print a dot.
			
			// 10^2 digit of the output number
			tmp = (unsigned char)((result / 100) % 10);
			P3 = 0xF7; // Use Segment #2
			P1 = segData[tmp] - (dotLocation == 2 ? 0x80 : 0x00); // If dotLocation is same as the segment, also print a dot.
			
			// 10^3 digit of the output number
			tmp = (unsigned char)(result / 1000);
			P3 = 0xFF; // Use Segment #3
			P1 = segData[tmp] - (dotLocation == 3 ? 0x80 : 0x00); // If dotLocation is same as the segment, also print a dot.
		}
		
		return;
	}
	return;
}


// Generate Target Number with Input
void pack(unsigned char p, unsigned char input)
{
	// Discard the 10^1 digit, and move the 10^0 digit to 10^1 digit
	dat[p] = dat[p] % 10;
	dat[p] = dat[p] * 10;
	
	// Add the input value to the data
	// as the input value is less then 10, it is the same as 10^0 digit of the number
	dat[p] += input;
}


// Numeric Key Detection
unsigned char keyDetect()
{
	// Assign the foundNum variable as 12, which means noting detected.
	unsigned char foundNum = 12;
	
	// Set P0's lower 4-bit value to 0, to know if any key is now pressed.
	P0 = 0xF0;
	if(P0 == 0xF0)
	{
		return 12; // Nothing Detected
	}
	
	// If some key is pressed, find which key was pressed.
	P0 = 0xF7; // 1-3
	if(P0 != 0xF7) // If key 1-3 wasn't pressed
	{
		if(P0 == 0xB7) // 1
		{
			foundNum = 1;
		}else if(P0 == 0xD7) // 2
		{
			foundNum = 2;
		}else{ // 3
			foundNum = 3;
		}
		return foundNum;
	}
	P0 = 0xFB; // 4-6
	if(P0 != 0xFB) // If key 4-6 wasn't pressed
	{
		if(P0 == 0xBB) // 4
		{
			foundNum=4;
		}else if(P0 == 0xDB){ // 5
			foundNum=5;
		}else{ // 6
			foundNum=6;
		}
		return foundNum;
	}
	P0 = 0xFD; // 7-9
	if(P0!=0xFD) // If key 7-9 wasn't pressed
	{
		if(P0 == 0xBD) // 7
		{
			foundNum = 7;
		}else if(P0 == 0xDD){ // 8
			foundNum = 8;
		}else{ // 9
			foundNum = 9;
		}
		return foundNum;
	}
	P0 = 0xFE; // Last 3 Buttons
	if(P0 == 0xFE) // If no keys are detected
	{
		return 12; // No Detection
	}
	if(P0 == 0xDE) // 0
	{
		return 0;
	}else{
		return 12; // * or #
	}
	
	return 12;
}


// Keypad Undetect Wait
void keyUndetect()
{
	// Set P0's lower 4-bit value to 0, to know if any key is now pressed.
	P0 = 0xF0;
	while(P0 != 0xF0)
	{
		// Loop until all of the keys of the keypad are not pressed
		printSeg();
	}
	
	return;
}


// Find the Numeric Key Value
unsigned char keyFind()
{
	// Get the keypad input data
	unsigned char answer = keyDetect();
	
	// If keypad was pressed
	if(answer != 12)
	{
		// If the print mode is printing the result
		if(mode == 3)
		{
			// Change print mode to printing the first operand
			mode = 0;
		}
		
		// Wait until any of the key is not pressed
		keyUndetect();
	}
	
	// Return the number of the keypad pressed
	return answer;
}


// Enter Key Undetect Wait
void enterUndetect()
{
	while(!ENTER) // While Enter key is Pressed
	{
		printSeg();
	}
	
	// Increase the mode
	if(mode == 3)
	{
		// For the first operand is 0 when the answer is now shown to the 7-segment display
		mode = 1;
	}else{
		mode++;
	}

	return;
}


// Enter Key Detection
void enterDetect()
{
	if(!ENTER) // If enter is now pressed
	{
		// Wait until the enter is now unpressed
		enterUndetect();
	}
	
	return;
}


// Calculate Function
void calculate(unsigned char operator)
{
	// Variables for divide calculation, especially for values under 1
	int tmpDivision = 0, tmpRemain = 0;
	
	// Initialize the decimal point location
	dotLocation = 0;
	
	// Initialize the result variable
	result = 0;
	
	// Switch by the operator inputs
	switch(operator)
	{
	case 1: // Add
		result = (int)dat[0] + dat[1];
		break;
		
	case 2: // Subtract
		result = (int)dat[0] - dat[1];
		break;
		
	case 3: // Multiply
		result = (int)dat[0] * dat[1];
		break;
		
	case 4: // Divide
		if(dat[1] == 0) // If user is now trying to divide by 0
		{
			// Just set the result 0
			break;
		}
		
		// Get the quotient and the remainder of the operand
		tmpDivision = (int)(dat[0] / dat[1]);
		tmpRemain = dat[0] % dat[1];
		
		if(tmpDivision / 10 != 0) // If the quotient is 10~99. It does not exceed 100, as 99 / 1 = 99
		{
			// Set the value on 10^2 location
			result = tmpDivision * 100;
			// and the decimal point to 10^2
			dotLocation = 2;
			
			// Multiply with 10 to get one decimal place of the divide operation
			tmpRemain *= 10;
			// Divide operation with the original operand
			tmpDivision = (int)(tmpRemain / dat[1]);
			
			// Add the value on 10^1 location
			result += tmpDivision * 10;
			// Get the next remainder to calculate
			tmpRemain %= dat[1];
			
			
			// Multiply with 10 to get two decimal place of the divide operation
			tmpRemain *= 10;
			// Divide operation with the original operand
			tmpDivision = (int)(tmpRemain / dat[1]);
			
			// Add the value on 10^0 location
			result += tmpDivision;
			// Get the next remainder to calculate
			tmpRemain %= dat[1];
			
			// Multiply with 10 to get three decimal place of the divide operation
			tmpRemain *= 10;
			// Divide operation with the original operand
			tmpDivision = (int)(tmpRemain / dat[1]);
			
			// If the value is over 5, round up the value
			if(tmpDivision >= 5)
			{
				result++;
			}
			
		}else{ // If the quotient is 0~9.
			
			// Set the value on 10^3 location
			result = tmpDivision * 1000;
			// dnd the decimal point to 10^3
			dotLocation = 3;
			
			
			// Multiply with 10 to get one decimal place of the divide operation
			tmpRemain *= 10;
			// Divide operation with the original operand
			tmpDivision = (int)(tmpRemain / dat[1]);
			
			// Add the value on 10^2 location
			result += tmpDivision * 100;
			// Get the next remainder to calculate
			tmpRemain %= dat[1];
			
			
			// Multiply with 10 to get two decimal place of the divide operation
			tmpRemain *= 10;
			// Divide operation with the original operand
			tmpDivision = (int)(tmpRemain / dat[1]);
			
			// Add the value on 10^1 location
			result += tmpDivision * 10;
			// Get the next remainder to calculate
			tmpRemain %= dat[1];
			
			
			// Multiply with 10 to get three decimal place of the divide operation
			tmpRemain *= 10;
			// Divide operation with the original operand
			tmpDivision = (int)(tmpRemain / dat[1]);
			
			// Add the value on 10^0 location
			result += tmpDivision;
			// Get the next remainder to calculate
			tmpRemain %= dat[1];
			
			// Multiply with 10 to get four decimal place of the divide operation
			tmpRemain *= 10;
			// Divide operation with the original operand
			tmpDivision = (int)(tmpRemain / dat[1]);
			
			// If the value is over 5, round up the value
			if(tmpDivision >= 5)
			{
				result++;
			}
		}
	}
	// Reset the operand to prevent error with the operands of the next calculation
	dat[0] = 0;
	dat[1] = 0;
	
	return;
}


// Operator Detection
void operatorDetect()
{
	// First, increase the print mode
	mode++;
	
	// Calculate if the operator button is pressed
	if(!PLUS) // Add
	{
		calculate(1); // ADD Calculation
		
	}else if(!MINUS){ // Subtract
		calculate(2); // SUBTRACT Calculation
		
	}else if(!MULTIPLY){ // Multiply
		calculate(3); // MULTIPLY Calculation
		
	}else if(!DIVIDE){ // Divide
		calculate(4); // DIVIDE Calculation
		
	}else{ // If no operator button is now pressed
		
		// Decrease the print mode
		mode--;
	}
	
	return;
}

// Main function
void main()
{
	// Temporary variable to store the input key value
	unsigned char temp = 0;
	
	// Initialize
	setup();
	
	// Infinite loop
	while(1)
	{
		// Input 1st Operand
		while(mode == 3 || mode == 0)
		{
			// Print the segment
			printSeg();
			
			// Key detection
			temp = keyFind();
			// If the key is now detected
			if(temp != 12)
			{
				// Apply the input data to the operand variable
				pack(0, temp);
			}
			
			// Enter key detection
			enterDetect();
		}
		
		// Input 2nd Operand
		while(mode == 1)
		{
			// Print the segment
			printSeg();
			
			// Key detection
			temp = keyFind();
			// If the key is now detected
			if(temp != 12)
			{
				// Apply the input data to the operand variable
				pack(1, temp);
			}
			
			// Enter key detection
			enterDetect();
		}
		
		// Operator Input & Calculation
		while(mode == 2)
		{
			// Print the segment
			printSeg();
			
			// Operator detection
			operatorDetect();
		}
	}
	
	return;
}