# 8051 어셈블리어 연습
<!-- # 8051 Assembly Language Practice -->

### 1. Prime_Finder

##### 2~255 사이의 소수를 찾아 그 값을 내부 RAM의 0x30번지부터 저장하는 프로그램

---
### 2. 8051_Clock

##### 8051을 이용한 현재 시각 중, 분과 초를 알려주는 시계

해당 Project에서 8051은 12MHz Clock을 이용한다.  

---
### 3. 8051_RPN_Calculator

##### 8051을 이용해 2자리 수 사이의 사칙연산을 할 수 있는 계산기

역폴란드 표기법을 이용하는 계산기로, 첫째 숫자 입력 이후에 둘째 숫자를 입력하고 나서, 연산자를 입력한다.  
10진수 연산이며, 나누기 연산의 경우 정수 부분만 나타난다.  

---
### 4. 8051_Serial_Command

##### 8051의 Serial Port로 입력받은 명령어를 수행하는 도구

이 프로그램에서는 다음과 같은 명령어를 Serial로 입력받아 수행할 수 있다.  
<table>
    <tr>
        <th>명령어</th>
        <th>설명</th>
    </tr>
    <tr>
        <td>LED (0-7 사이의 숫자) ON</td>
        <td>주어진 LED를 켠다.</td>
    </tr>
    <tr>
        <td>LED (0-7 사이의 숫자) OFF</td>
        <td>주어진 LED를 끈다.</td>
    </tr>
    <tr>
        <td>LED BLINK (0-255 사이의 숫자)</td>
        <td>LED를 입력받은 Machine Cycle 주기로 깜빡인다.</td>
    </tr>
    <tr>
        <td>LED BLINK STOP</td>
        <td>LED의 깜빡임을 멈춘다.</td>
    </tr>
    <tr>
        <td>SEGMENT USE (0-3 사이의 숫자)</td>
        <td>이용할 Segment의 번호를 설정한다.</td>
    </tr>
    <tr>
        <td>SEGMENT ON</td>
        <td>Segment를 켠다.</td>
    </tr>
    <tr>
        <td>SEGMENT OFF</td>
        <td>Segment를 끈다.</td>
    </tr>
    <tr>
        <td>SEGMENT (0-9 사이의 숫자)</td>
        <td>Segment에 해당 숫자를 출력한다.</td>
    </tr>
    <tr>
        <td>MOTOR FORWARD</td>
        <td>Motor를 앞으로 회전시킨다.</td>
    </tr>
    <tr>
        <td>MOTOR REVERSE</td>
        <td>Motor를 뒤로 회전시킨다.</td>
    </tr>
    <tr>
        <td>MOTOR BACKWARD</td>
        <td>Motor를 뒤로 회전시킨다.</td>
    </tr>
    <tr>
        <td>MOTOR STOP</td>
        <td>Motor를 정지시킨다.</td>
    </tr>
    <tr>
        <td>KEYPAD LED ON</td>
        <td>Keypad에 입력된 0-7 사이의 값의 번호의 LED를 점등한다.</td>
    </tr>
    <tr>
        <td>KEYPAD LED OFF</td>
        <td>Keypad에 입력된 0-7 사이의 값의 번호의 LED를 소등한다.</td>
    </tr>
    <tr>
        <td>KEYPAD UART</td>
        <td>Keypad에 입력된 값을 Serial 통신으로 전송한다.</td>
    </tr>
    <tr>
        <td>KEYPAD SEGMENT</td>
        <td>Keypad에 입력된 값을 Segment에 출력한다.</td>
    </tr>
</table>
만일, Serial 입력으로 소문자가 입력된 경우, 자동으로 대문자로 변환해 명령을 수행한다.  
Serial Port의 Baud Rate는 4800 baud rate이며 Serial 통신에서는 Parity Bit를 이용하지 않는다. 또한, 8051의 Clock는 11.0592MHz이다.  

---
### 5. 8051_Doorlock

##### 8051을 이용한 Doorlock

입력은 Keypad를 이용해 받는다.  
- Unlock Mode 이용 시, *를 누른 후, 숫자들을 누르고, 다시 *를 누른다. 초기 비밀번호는 0000이다.
    - 정확한 Password가 입력된 경우, 모든 LED를 점등하고, P3.0, P3.1에 연결된 Motor를 작동시킨다.
    - 틀린 Password가 입력된 경우, Segment에 E가 출력되며 Segment의 점은 점등되지 않는다.
- Password Change Mode 이용 시, *를 4번 누른 후, 숫자들을 누르고, 다시 *를 4번 누른다.
- #가 입력된 경우, 언제나 초기 입력 상태로 돌아간다.
- 잘못된 명령어 입력 시, Segment에 E가 출력되며 Segment의 점 또한 점등된다.
- 입력값이 입력된 경우, LED와 Motor의 작동을 멈춘다.
- Password의 길이는 4~8자리이며, 이 범위를 벗어난 경우, 잘못된 명령어로 인식한다. 특히, 9자리 이상의 Password 입력 시도 시, *을 다시 입력하지 않더라도 잘못된 명령어로 처리되며, 다시 초기 상태로 되돌아간다.
- '*'가 처음 입력되거나, 현재 입력된 숫자가 없는 경우, 모든 LED가 소등된다.
- 입력값이 숫자인 경우, LED가 LED0(P1.0에 있음)에서 LED7(P1.7에 있음) 순서로 점등되며, 동시에 다른 LED들은 소등된다.
- Password 수정 성공 시, 현재 점등되어 있는 LED를 제외한 나머지 모든 LED가 점등되며, 현재 점등된 LED는 소등된다.
- Segment 출력 시를 제외한 나머지 경우에는, Segment가 점등되지 않는다.

---
### 6. FizzBuzz_Solver

##### 8051의 Serial 입출력을 이용한 FizzBuzz 문제를 해결하는 프로그램

1부터 Serial을 통해 입력받은 숫자까지의 자연수에 대해, FizzBuzz 문제를 해결하여 그 결과를 Serial을 통해 출력한다.  

---
### 7. 8051_Motor_Controller

##### 8051에 연결된 Motor를 PWM 제어하는 프로그램

Keypad를 통해 입력받은 값을 기준으로 연결된 Motor를 PWM 제어한다.  
Keypad의 입력이 있을 때, 기존 MOTOR_SPEED 변수의 값에 10을 곱한 후, Keypad 입력값을 더해 MOTOR_SPEED 변수에 저장한다. 만일, 해당 연산의 결과가 255를 초과하는 경우 아래와 같은 연산을 수행한다.  

- MOTOR_SPEED 변수의 값이 25를 초과하는 경우, MOTOR_SPEED 변수의 값의 100의 자리의 값을 제거한다.  
    - 연산한 결과가 25를 초과하는 경우, 연산한 결과의 10의 자리의 값을 제거한다.  
    - 연산한 결과가 25이고 Keypad에 입력된 값이 6 이상인 경우, 연산한 결과의 10의 자리의 값을 제거한다.  
- MOTOR_SPEED 변수의 값이 25이고 Keypad에 입력된 값이 6 이상인 경우, MOTOR_SPEED 변수의 값의 10의 자리의 값을 제거한다.  

위와 같은 연산을 진행한 후, 연산한 결과에 Keypad 입력값을 더해 MOTOR_SPEED 변수에 저장한다.
<br>
MOTOR_SPEED 변수의 값은 Segment를 통해 출력한다.  

---
### 참고 사항

- 2, 3, 5번 프로젝트는 EdSim51DI의 회로도를 기준으로 작성되었습니다. 특히, 5번 프로젝트의 경우, AND Gate Enabled 설정이 필요합니다.  
- 4번 프로젝트는 EdSim51DI의 회로도를 기준으로 작성되었으나, Motor Forward는 P3.6, Motor Reverse는 P3.7 Port를 이용합니다.  
- 7번 프로젝트는 EdSim51DI의 회로도를 기준으로 작성되었으나, Segment Selection Switch는 P2.7과 P2.6 Port를 이용합니다.  
- 4, 5번 프로젝트는 마이크로프로세서 및 HDL 과목의 2024년 이전 수업의 과제를 일부 변형한 프로젝트입니다.  

---
작성자 : YHC03  
최종 작성일 : 2024/5/31  
