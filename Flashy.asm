; Sometimes it's useful to give bad examples (as long
; as it's clear that it's a bad example) and that's what
; this code is.
; - It is completely unmaintable, because
;    - it's uncommented,
;    - it has no debugging functionality,
;    - it uses nondescriptive labels and names, and
;    - it's monolithic instead of modular.
; - It does things in foolish ways, sometimes for
;   the sake of saving a word or two of memory, and
;   sometimes because it was easier to hack it together
;   rather than spend the time to do it right.
; - Thinking in broader terms, it doesn't even do a
;   good job of demonstrating the neopixel peripheral,
;   because all it does is display random colors, which
;   doesn't help the user understand how to use the peripheral
;   or what it's capable of doing.

; tl;dr: Don't spend much time here.  All of this is an
; example of what NOT to do.

ORG 0
	LOADI RandArray
	STORE Ind
Start:
	LOADI 0
	STORE Cont
	OR    CR
	SHIFT 6
	OR    CG
	SHIFT 5
	OR    CB
	AND   B4
	OUT   NeoPixel
CheckRed:
	ILOAD Ind
	AND   BR
	JZERO RedDown
	LOAD  CR
	ADDI  1
	SHIFT 10
	SHIFT -10
	JNEG  CheckGreen
	AND   B5
	STORE CR
	LOADI 1
	STORE Cont
	JUMP  CheckGreen
RedDown:
	LOAD  CR
	ADDI  -1
	JNEG  CheckGreen
	STORE CR
	LOADI 1
	STORE Cont
CheckGreen:
	ILOAD Ind
	AND   BG
	JZERO GreenDown
	LOAD  CG
	ADDI  1
	SHIFT 10
	SHIFT -10
	JNEG  CheckBlue
	AND   B5
	STORE CG
	LOADI 1
	STORE Cont
	JUMP  CheckBlue
GreenDown:
	LOAD  CG
	ADDI  -1
	JNEG  CheckBlue
	STORE CG
	LOADI 1
	STORE Cont
CheckBlue:	
	ILOAD Ind
	AND   BB
	JZERO BlueDown
	LOAD  CB
	ADDI  1
	SHIFT 10
	SHIFT -10
	JNEG  CheckAll
	AND   B5
	STORE CB
	LOADI 1
	STORE Cont
	JUMP  CheckAll
BlueDown:
	LOAD  CB
	ADDI  -1
	JNEG  CheckAll
	STORE CB
	LOADI 1
	STORE Cont
CheckAll:
	LOADI  -1000
	ADDI   -1000
	ADDI   -1000
	ADDI   -1000
	ADDI   -1000
	ADDI   -1000
	ADDI   -1000
	ADDI   -1000
DelayLoop:
	ADDI   -1
	JZERO  SDRet
	JUMP   DelayLoop
SDRet:
	LOAD  Cont
	JPOS  Start
	LOADI RandArray
	SUB   Ind
	STORE Ind
	LOADI 0
	SUB   Ind
	ADDI  1
	AND   B5
	STORE Ind
	LOADI RandArray
	ADD   Ind
	STORE Ind
	JUMP  Start	

	
	
CR:   DW 0
CG:   DW 0
CB:   DW 0
B4:   DW &B0111101111101111
B5:   DW &B11111
Ind:  DW 0
BR:   DW 4
BG:   DW 2
BB:   DW 1
Cont: DW 0

RandArray:
DW 0
DW 1
DW 2
DW 3
DW 4
DW 5
DW 6
DW 7
DW 0
DW 0
DW 7
DW 0
DW 1
DW 5
DW 0
DW 6
DW 6
DW 7
DW 1
DW 0
DW 7
DW 6
DW 6
DW 3
DW 5
DW 7
DW 1
DW 7
DW 1
DW 0
DW 5
DW 4
DW 3
DW 7
DW 1
DW 6
DW 3
DW 7
DW 0
DW 4
DW 2
DW 6
DW 6
DW 4
DW 4
DW 5
DW 5
DW 7
DW 7
DW 0
DW 2
DW 6
DW 4
DW 7
DW 5
DW 5
DW 5
DW 2
DW 2
DW 1
DW 1
DW 3
DW 3
DW 6

; IO address constants
Switches:  EQU &H000
LEDs:      EQU &H001
Timer:     EQU &H002
Hex0:      EQU &H004
Hex1:      EQU &H005
I2C_cmd:   EQU &H090
I2C_data:  EQU &H091
I2C_rdy:   EQU &H092
NeoPixel:  EQU &H0A0
