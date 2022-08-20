.MODEL SMALL
.STACK 100H 

CR EQU 0DH
LF EQU 0AH

.DATA

.CODE

f PROC
PUSH 0
;int k
MOV SI, -2
MOV AX, 5
MOV [BP + SI], AX
;k=5
label0:
MOV SI, -2
MOV BX, [BP + SI]
MOV AX, 0
CMP BX, AX
JG label2
MOV AX, 0
JMP label3
label2:
MOV AX, 1
label3:
;k>0
CMP AX, 0
JE label1
;while (k>0)
MOV SI, 2
MOV AX, [BP + SI]
INC [BP + SI]
;a++
MOV SI, -2
MOV AX, [BP + SI]
MOV CX, AX
DEC CX
MOV [BP + SI], CX
;k--
JMP label0
label1:
MOV AX, 3
PUSH AX
MOV SI, 2
MOV AX, [BP + SI]
POP BX
XCHG   AX, BX
XOR DX, DX
IMUL BX
PUSH AX
MOV AX, 7
POP BX
SUB BX, AX
MOV AX, BX
;3*a-7
;return 3*a-7
MOV SP, BP
RET
MOV SI, 2
MOV AX, 9
MOV [BP + SI], AX
;a=9
MOV SP, BP
RET
f ENDP
g PROC
PUSH 0
PUSH 0
;int x,i
MOV SI, -2
PUSH SI
PUSH BP
MOV SI, 4
MOV AX, [BP + SI]
PUSH AX
MOV BP, SP
ADD BP, -2
CALL f
POP BP
POP BP
PUSH AX
MOV SI, 4
MOV AX, [BP + SI]
POP BX
ADD AX, BX
PUSH AX
MOV SI, 2
MOV AX, [BP + SI]
POP BX
ADD AX, BX
POP SI
MOV [BP + SI], AX
;x=f(a)+a+b
MOV SI, -4
MOV AX, 0
MOV [BP + SI], AX
;i=0
label4:
MOV SI, -4
MOV BX, [BP + SI]
MOV AX, 7
CMP BX, AX
JL label8
MOV AX, 0
JMP label9
label8:
MOV AX, 1
label9:
;i<7
CMP AX, 0
JE label5
JMP label6
label7:
MOV SI, -4
MOV AX, [BP + SI]
INC [BP + SI]
;i++
JMP label4
label6:
;for(i=0;i<7;i++)
MOV SI, -4
MOV BX, [BP + SI]
MOV AX, 3
XCHG   AX, BX
XOR DX, DX
IDIV BX
MOV BX, DX
MOV AX, 0
CMP BX, AX
JE label10
MOV AX, 0
JMP label11
label10:
MOV AX, 1
label11:
;i%3==0
CMP AX, 0
JE label12
MOV SI, -2
PUSH SI
MOV SI, -2
MOV BX, [BP + SI]
MOV AX, 5
ADD AX, BX
POP SI
MOV [BP + SI], AX
;x=x+5
;if (i%3==0)
JMP label13
label12:
MOV SI, -2
PUSH SI
MOV SI, -2
MOV BX, [BP + SI]
MOV AX, 1
SUB BX, AX
MOV AX, BX
POP SI
MOV [BP + SI], AX
;x=x-1
;else
label13:
JMP label7
label5:
MOV SI, -2
MOV AX, [BP + SI]
;x
;return x
MOV SP, BP
RET
MOV SP, BP
RET
g ENDP


main PROC
MOV AX, @DATA
MOV DS, AX

PUSH BP
MOV BP, SP

PUSH 0
PUSH 0
PUSH 0
;int a,b,i
MOV SI, -2
MOV AX, 1
MOV [BP + SI], AX
;a=1
MOV SI, -4
MOV AX, 2
MOV [BP + SI], AX
;b=2
MOV SI, -2
PUSH SI
PUSH BP
MOV SI, -2
MOV AX, [BP + SI]
PUSH AX
MOV SI, -4
MOV AX, [BP + SI]
PUSH AX
MOV BP, SP
ADD BP, -2
CALL g
POP BP
POP BP
POP BP
POP SI
MOV [BP + SI], AX
;a=g(a,b)
MOV AX, [BP - 2]
;println(a)
CALL PRINT_INT
MOV SI, -6
MOV AX, 0
MOV [BP + SI], AX
;i=0
label14:
MOV SI, -6
MOV BX, [BP + SI]
MOV AX, 4
CMP BX, AX
JL label18
MOV AX, 0
JMP label19
label18:
MOV AX, 1
label19:
;i<4
CMP AX, 0
JE label15
JMP label16
label17:
MOV SI, -6
MOV AX, [BP + SI]
INC [BP + SI]
;i++
JMP label14
label16:
;for(i=0;i<4;i++)
MOV SI, -2
MOV AX, 3
MOV [BP + SI], AX
;a=3
label20:
MOV SI, -2
MOV BX, [BP + SI]
MOV AX, 0
CMP BX, AX
JG label22
MOV AX, 0
JMP label23
label22:
MOV AX, 1
label23:
;a>0
CMP AX, 0
JE label21
;while (a>0)
MOV SI, -4
MOV AX, [BP + SI]
INC [BP + SI]
;b++
MOV SI, -2
MOV AX, [BP + SI]
MOV CX, AX
DEC CX
MOV [BP + SI], CX
;a--
JMP label20
label21:
JMP label17
label15:
MOV AX, [BP - 2]
;println(a)
CALL PRINT_INT
MOV AX, [BP - 4]
;println(b)
CALL PRINT_INT
MOV AX, [BP - 6]
;println(i)
CALL PRINT_INT
MOV AX, 0
;0
;return 0
MOV SP, BP
MOV AH, 4CH
INT 21H
main ENDP



PRINT_INT PROC						

	OR AX, AX						
	JGE END_IF1						
	PUSH AX						
	MOV DL,'-'						
	MOV AH, 2						
	INT 21H						
	POP AX						
	NEG AX						

END_IF1:						
	XOR CX, CX						
	MOV BX, 10D						

REPEAT1:						
	XOR DX, DX						
	DIV BX						
	PUSH DX						
	INC CX						

	OR AX, AX						
	JNE REPEAT1						

	MOV AH, 2						

PRINT_LOOP:						
	POP DX						
	OR DL, 30H						
	INT 21H						
	LOOP PRINT_LOOP						
	MOV AH, 2						
	MOV DL, 10						
	INT 21H						

	MOV DL, 13						
	INT 21H						
	RET						
PRINT_INT ENDP

END MAIN
