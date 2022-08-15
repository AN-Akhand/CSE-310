.MODEL SMALL
.STACK 100H 

CR EQU 0DH
LF EQU 0AH

.DATA

.CODE



main PROC
MOV AX, @DATA
MOV DS, AX

PUSH BP
MOV BP, SP

PUSH 0
PUSH 0
PUSH 0
PUSH 0
MOV SI, -4
PUSH SI
MOV AX, 0
POP SI
MOV [BP + SI], AX
MOV SI, -6
PUSH SI
MOV AX, 1
POP SI
MOV [BP + SI], AX
MOV SI, -8
PUSH SI
MOV AX, 0
POP SI
MOV [BP + SI], AX
label0:
MOV SI, -8
MOV AX, [BP + SI]
PUSH AX
MOV AX, 4
POP BX
CMP BX, AX
JL label4
MOV AX, 0
JMP label5
label4:
MOV AX, 1
label5:
CMP AX, 0
JE label1
JMP label2
label3:
MOV SI, -8
MOV AX, [BP + SI]
INC [BP + SI]
JMP label0
label2:
MOV SI, -2
PUSH SI
MOV AX, 3
POP SI
MOV [BP + SI], AX
label6:
MOV SI, -2
MOV AX, [BP + SI]
DEC [BP + SI]
CMP AX, 0
JE label7
MOV SI, -4
MOV AX, [BP + SI]
INC [BP + SI]
JMP label6
label7:
JMP label3
label1:
MOV AX, [BP - 2]
CALL PRINT_INT
MOV AX, [BP - 4]
CALL PRINT_INT
MOV AX, [BP - 6]
CALL PRINT_INT
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