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

이 Project는 마이크로프로세서 및 HDL 과목의 2024년 이전 수업의 과제이다.  

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
        <td>MOTOR STOP</td>
        <td>Motor를 정지시킨다.</td>
    </tr>
</table>

Serial Port의 Baud Rate는 4800 baud rate이며 Serial 통신에서 Parity Bit를 이용하지 않는다. 또한, 8051의 Clock는 11.0592MHz이다.  

---
2, 3번 프로젝트는 EdSim51DI의 회로도를 기준으로 작성되었습니다.  
4번 프로젝트는 EdSim51DI의 회로도를 기준으로 작성되었으나, Motor Forward는 P3.6, Motor Reverse는 P3.7 Port를 이용합니다.  

---
작성자 : YHC03  
최종 작성일 : 2024/5/17  