# 8051 C언어 연습
<!-- # 8051 C Language Practice -->

### 1. 8051_RPN_Calculator

##### 8051을 이용해 2자리 수 사이의 사칙연산을 할 수 있는 계산기

역폴란드 표기법을 이용하는 계산기로, 첫째 숫자 입력 이후에 둘째 숫자를 입력하고 나서, 연산자를 입력한다.  
10진수 연산이며, 나누기 연산은 7-Segment에서 최대한 표시할 수 있는 만큼의 소수 부분이 소수점 구분과 함께 나타난다.  

---
### 2. 8051Clock

##### 8051을 이용한 현재 시각 중, 분과 초를 알려주는 시계

해당 Project에서 8051은 12MHz Clock을 이용한다.  

---
### 3. 8051_Serial_Command

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
        <td>LED 깜빡임을 멈춘다.</td>
    </tr>
    <tr>
        <td>SEGMENT ENABLE</td>
        <td>Segment를 켠다.</td>
    </tr>
    <tr>
        <td>SEGMENT DISABLE</td>
        <td>Segment를 끈다.</td>
    </tr>
    <tr>
        <td>SEGMENT USE (0-3 사이의 숫자)</td>
        <td>이용할 Segment의 번호를 설정한다.</td>
    </tr>
    <tr>
        <td>SEGMENT PRINT (0-9 사이의 숫자)</td>
        <td>Segment에 해당 숫자를 출력한다.</td>
    </tr>
    <tr>
        <td>SEGMENT (A-H 사이의 Alphabet) ON</td>
        <td>주어진 Alphabet의 Segment를 켠다. H 입력 시, Segment의 점 LED를 켠다.</td>
    </tr>
    <tr>
        <td>SEGMENT (A-H 사이의 Alphabet) OFF</td>
        <td>주어진 Alphabet의 Segment를 끈다. H 입력 시, Segment의 점 LED를 끈다.</td>
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
        <td>KEYPAD SEGMENT</td>
        <td>Keypad에 입력된 값을 Segment에 출력한다.</td>
    </tr>
    <tr>
        <td>KEYPAD LED</td>
        <td>Keypad에 입력된 0-7 사이의 값의 번호의 LED를 점등한다.</td>
    </tr>
    <tr>
        <td>KEYPAD UART</td>
        <td>Keypad에 입력된 값을 Serial 통신으로 전송한다.</td>
    </tr>
</table>


---
### 4. 8051_Doorlock

##### 8051을 이용한 Doorlock

입력은 Keypad를 이용해 받는다.  
- Unlock Mode 이용 시, *를 누른 후, 숫자들을 누르고, 다시 *를 누른다. 초기 비밀번호는 0000이다.
    - 정확한 Password가 입력된 경우, 모든 LED를 점등한다.
    - 틀린 Password가 입력된 경우, Segment에 E가 출력되며 Segment의 점은 점등되지 않는다. 이후, 틀린 Password가 Serial로 전송된다.
- Password Change Mode 이용 시, *를 4번 누른 후, 숫자들을 누르고, 다시 *를 4번 누른다.
    - Password 변경 성공 시, Segment의 가장 아래의 LED 2개를 점등한다.
- #가 입력된 경우, 언제나 초기 입력 상태로 돌아간다.
- 잘못된 명령어 입력 시, Segment에 E가 출력되며 Segment의 점 또한 점등된다.
- 입력값이 *인 경우, 모든 LED를 소등한다.
- 입력값이 숫자인 경우, LED가 LED0(P1.0에 있음)에서 LED7(P1.7에 있음) 순서로 점등하며, 동시에 다른 LED는 소등한다.


---
1, 2, 4번 프로젝트는 EdSim51DI의 회로도를 기준으로 작성되었습니다.  
3번 프로젝트는 EdSim51DI의 회로도를 기준으로 작성되었으나, Motor Forward는 P3.6, Motor Reverse는 P3.7 Port를 이용합니다. 
3, 4번 프로젝트에서 Serial Port의 Baud Rate는 4800 baud rate이며 Serial 통신에서 Parity Bit를 이용하지 않습니다. 또한, 해당 프로젝트에서 8051의 Clock는 11.0592MHz이다.  
3, 4번 프로젝트는 마이크로프로세서 및 HDL 과목의 2024년 이전 수업의 과제를 일부 변형한 프로젝트입니다.  

---
작성자 : YHC03  
최종 작성일 : 2024/5/18  