/* 
* Reverse Polish Notation Calculator
* Function: 2-Digit Number Calculation
*
* Written By: YHC03
*
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
* Create Date: 24/4/25
* Update Date : 24/4/27
*
* Known Issues(24/4/25)
* Currently not works well
*/
#include<reg51.h>

// Mode for Calculator(0: Input1, 1: Input2, 2: Operand, 3: answer)
unsigned char mode = 0;
// Input data
unsigned char dat[2] = {0, 0};
// Result
short result = 0;
// Segment Output Data
const unsigned char segData[10]={ 0xC0, 0xF9, 0xA4, 0xB0, 0x99, 0x92, 0x82, 0xD8, 0x80, 0x90 };

// Setup For Input
void setup()
{
	P2=0x1F;
	P0=0xFF;
}

// Print data to segment
void printSeg()
{
/*
* mode 0 -> dat[0]
* mode 1 -> dat[1]
* mode 2 -> print dot on LSB
* mode 3 -> print result, if result < 0, only 2 segemts are used to represent numbers
*/
	unsigned char tmp=0;
	switch(mode)
	{
	case 0:
		P3=0xE7; // Use Last Segment
		tmp=dat[0]%10;
		P1=segData[tmp];
		P3 = P3 + 0x08; // Use Third Segment
		tmp=(unsigned char)(dat[0]/10);
		P1=segData[tmp];
		return;
	case 1:
		P3=0xE7; // Use Last Segment
		tmp=dat[1]%10;
		P1=segData[tmp];
		P3 = P3 + 0x08; // Use Third Segment
		tmp=(unsigned char)(dat[1]/10);
		P1=segData[tmp];
		return;
	case 2:
		P3=0xE7;
		P1=0x7F; // Print .
		return;
	case 3:
		if(result<0)
		{
			P3=0xE7; // Use Last Segment
			tmp=(unsigned char)((-result)%10);
			P1=segData[tmp];
			P3 = P3 + 0x08; // Use Third Segment
			tmp=(unsigned char)(((-result)/10)%10);
			P1=segData[tmp];
			P3 = P3 + 0x08; // Use Second Segment
			P1=0xBF; // Print -
		}else{
			P3=0xE7; // Use Last Segment
			tmp=(unsigned char)(result%10);
			P1=segData[tmp];
			P3 = P3 + 0x08; // Use Third Segment
			tmp=(unsigned char)((result/10)%10);
			P1=segData[tmp];
			P3 = P3 + 0x08; // Use Second Segment
			tmp=(unsigned char)((result/100)%10);
			P1=segData[tmp];
			P3 = P3 + 0x08; // Use First Segment
			tmp=(unsigned char)(result/1000);
			P1=segData[tmp];
		}
		return;
	}
	return;
}



// Generate Target Number with Input
void pack(unsigned char* target, unsigned char input)
{
	*target = (*target)%10;
	*target = (*target)*10;
	*target += input;
}

// Numeric Key Detection
unsigned char keyDetect()
{
	unsigned char foundNum=12;
	P0=0xF0;
	if(P0==0xF0)
	{
		return 12; // Nothing Detected
	}
	P0=0xF7; // 1-3
	if(P0!=0xF7)
	{
		if(P0==0xB7) // 1
		{
			foundNum=1;
		}else if(P0==0xD7) // 2
		{
			foundNum=2;
		}else{ // 3
			foundNum=3;
		}
		return foundNum;
	}
	P0=0xFB; // 4-6
	if(P0!=0xFB)
	{
		if(P0==0xBB) // 4
		{
			foundNum=4;
		}else if(P0==0xDB){ // 5
			foundNum=5;
		}else{ // 6
			foundNum=6;
		}
		return foundNum;
	}
	P0=0xFD; // 7-9
	if(P0!=0xFD)
	{
		if(P0==0xBD) // 7
		{
			foundNum=7;
		}else if(P0==0xDD){ // 8
			foundNum=8;
		}else{ // 9
			foundNum=9;
		}
		return foundNum;
	}
	P0=0xFE; // Last 3 Buttons
	if(P0==0xFE)
	{
		return 12; // No Detection
	}
	if(P0==0xDE) // 0
	{
		return 0;
	}else{
		return 12; // * or #
	}
}

// Keypad Undetect Wait
void keyUndetect()
{
	P0=0xF0;
	while(P0==0xF0)
	{
		printSeg();
	}
	return;
}

// Numeric Key Find
unsigned char keyFind()
{
	unsigned char answer=keyDetect();
	if(answer!=12)
	{
		if(mode==3)
		{
			mode = 0;
		}
		keyUndetect();
	}
	return answer;
}

// Enter Key Undetect Wait
void enterUndetect()
{
	while(!(P2^0)) // While Enter Pressed
	{
		printSeg();
	}
	
	if(mode==3) // Increase Mode
	{
		mode=1;
	}else{
		mode++;
	}
}

// Enter Key Detection
void enterDetect()
{
	if(!(P2^0)) //enter Pressed
	{
		enterUndetect();
	}
}

// Calculate Function
void calculate(unsigned char operator)
{
	result = 0;
	switch(operator)
	{
	case 1: // Add
		result=(short)(dat[0]+dat[1]);
		return;
	case 2: // Subtract
		result=(short)(dat[0]-dat[1]);
		return;
	case 3: // Multiply
		result=(short)(dat[0]*dat[1]);
		return;
	case 4: // Divide
		if(dat[1]==0) //divide by 0
		{
			return;
		}
		result=(short)(dat[0]/dat[1]);
	}
	return;
}

// Operator Detect
void operatorDetect()
{
	mode++;
	if(!(P2^4)) // Add
	{
		calculate(1);
	}else if(!(P2^3)){ // Subtract
		calculate(2);
	}else if(!(P2^2)){ // Multiply
		calculate(3);
	}else if(!(P2^1)){ // Divide
		calculate(4);
	}else{
		mode--;
	}
}


void main()
{
	unsigned char temp=0;
	setup();
	
	while(1)
	{
		// Input 1st Operand
		while(mode==3 || mode==0)
		{
			printSeg();
			temp=keyFind();
			if(temp!=12)
			{
				pack(dat, temp);
			}
			enterDetect();
		}
		// Input 2nd Operand
		while(mode==1)
		{
			printSeg();
			temp=keyFind();
			if(temp!=12)
			{
				pack((dat+1), temp);
			}
			enterDetect();
		}
		// Operator Input & Calculation
		while(mode==2)
		{
			printSeg();
			operatorDetect();
		}
	}
}