; ReadX: tilt left and its positive, tilt right and its negative
; ReadY: tilt down and its positive, tilt up and its negative

ORG 0
Start:
	LOADI 1
	CALL DEBUG
	; LOADI 0
	; OUT Neo_All16
	; JUMP Start

Init:
	LOADI 1
	STORE CurBodySize
	LOADI 1 ; start moving rightwards
	STORE CurDir
	LOAD ScreenWidth
	SHIFT -1
	STORE Body1X
	LOAD ScreenHeight
	SHIFT -1
	STORE Body1Y

	LOAD	Background
	OUT		Neo_All16

	; draw initial snake pos
	LOAD Body1X
	STORE   XYToIndexX
	LOAD Body1Y
	STORE   XYToIndexY
	CALL    XYToIndex ; get head's index
	AND		EightBits
	OUT		Neo_Addr
	LOAD	SnakeColor
	OUT		Neo_Single16

	; get an apple and draw it
	CALL GetNewApplePos
	CALL DrawNewApplePos

	LOADI 2
	CALL DEBUG

SnakeGameLoop:
	LOADI 5
	CALL DELAYAC ; wait 0.1 seconds
	; DIRECTION HANDLING - Updates CurDir
    ; first determine if readx or ready is more extreme
        ; then, look at that direction and see which way its tilted more towards
    
	; move in direction of tilt, unless its the opposite of CurDir, then keep going in CurDir
    CALL ReadY
    STORE CurReadY
    CALL Abs
	; OUT Hex0 ; for debugging
    STORE ReadYAbsTemp
    
    CALL ReadX
    STORE CurReadX
    CALL Abs
	; OUT Hex0 ; for debugging

    SUB ReadYAbsTemp ; ACC = abs(readX) - abs(readY)
	; OUT Hex0 ; for debugging
    JPOS MoreX ; if readx > ready: go to moreX
	JUMP MoreY ; if ready > go to moreY

    MoreX:
        LOAD CurReadX
		JPOS MoreLeft
		JUMP MoreRight

        MoreLeft:
            ; LOADI &B1
			LOADI -1
			STORE NewDir
            JUMP DirOutput
        
        MoreRight:
            ; LOADI &B10
			LOADI 1
			Store NewDir
            JUMP DirOutput

    MoreY:
        LOAD CurReadY
		JPOS MoreDown
		JUMP MoreUp

        MoreDown:
            ; LOADI &B100
			LOADI -2
			Store NewDir
            JUMP DirOutput
        
        MoreUp:
            ; LOADI &B1000
			LOADI 2
			Store NewDir
            JUMP DirOutput

    DirOutput:
		LOAD NewDir
		ADD CurDir
		JZERO SkipSetCurDir ; set curDir = newDir if newDir != opposite of curDir
		LOAD NewDir
		STORE CurDir
		SkipSetCurDir:

		LOAD CurDir
        ; OUT Hex0 ; for debugging

	; AT THIS POINT CurDir has our current direction we will move in ============

	LOADI 4
	CALL DEBUG

	; update nextX and nextY
	LOAD CurDir
	ADDI -1
	JZERO MovingRight
	LOAD CurDir
	ADDI 1
	JZERO MovingLeft
	LOAD CurDir
	ADDI -2
	JZERO MovingUp
	LOAD CurDir
	ADDI 2
	JZERO MovingDown
	JUMP MovingDown

	MovingRight:
		LOAD Body1X
		ADDI 1
		STORE NextX
		LOAD Body1Y
		STORE NextY
		JUMP EndMoving
	MovingLeft:
		LOAD Body1X
		ADDI -1
		STORE NextX
		LOAD Body1Y
		STORE NextY
		JUMP EndMoving
	MovingUp:
		LOAD Body1X
		STORE NextX
		LOAD Body1Y
		ADDI 1
		STORE NextY
		JUMP EndMoving
	MovingDown:
		LOAD Body1X
		STORE NextX
		LOAD Body1Y
		ADDI -1
		STORE NextY
		JUMP EndMoving

	EndMoving:

	; at this point NextX and NextY hold the next position of the snake's head

	LOAD NextX
	OUT Hex0

	LOADI 8
	CALL DEBUG

	; now we must check if we won
	LOAD CurBodySize
	SUB MaxBodySize
	JZERO SnakeWin ; if curbodysize >= max body size: you win
	JPOS SnakeWin

	; Now we must check if we're about to move off the screen and go to SnakeLose if so
	LOAD NextX
	JNEG SnakeLose ; if x < 0
	SUB ScreenWidth
	JZERO SnakeLose ; if x >= width
	JPOS SnakeLose
	
	LOAD NextY
	JNEG SnakeLose ; if y < 0
	SUB ScreenHeight
	JZERO SnakeLose ; if y >= height
	JPOS SnakeLose

	; check if we're about to eat an apple, if so set EatingApple = 1, else = 0
	LOAD AppleX
	SUB NextX
	JNEG NotEatingApple
	JPOS NotEatingApple
	LOAD AppleY
	SUB NextY
	JNEG NotEatingApple
	JPOS NotEatingApple

	LOADI 1
	STORE EatingApple
	JUMP EndEatingApple
	NotEatingApple:
	LOADI 0
	STORE EatingApple
	JUMP EndEatingApple
	EndEatingApple:

	; TODO: check if snake's NextX, NextY is touching any of its current body parts, including the last one if EatingApple
	LOAD NextX
	SUB Body1X
	JNEG EndBodyCheck1
	JPOS EndBodyCheck1
	LOAD NextY
	SUB Body1Y
	JNEG EndBodyCheck1
	JPOS EndBodyCheck1
	JUMP SnakeLose
	EndBodyCheck1:
	LOAD NextX
	SUB Body2X
	JNEG EndBodyCheck2
	JPOS EndBodyCheck2
	LOAD NextY
	SUB Body2Y
	JNEG EndBodyCheck2
	JPOS EndBodyCheck2
	JUMP SnakeLose
	EndBodyCheck2:
	LOAD NextX
	SUB Body3X
	JNEG EndBodyCheck3
	JPOS EndBodyCheck3
	LOAD NextY
	SUB Body3Y
	JNEG EndBodyCheck3
	JPOS EndBodyCheck3
	JUMP SnakeLose
	EndBodyCheck3:
	LOAD NextX
	SUB Body4X
	JNEG EndBodyCheck4
	JPOS EndBodyCheck4
	LOAD NextY
	SUB Body4Y
	JNEG EndBodyCheck4
	JPOS EndBodyCheck4
	JUMP SnakeLose
	EndBodyCheck4:
	
	LOAD EatingApple
	JPOS BodyCheck5 ; if eating apple, check last body part
	JUMP EndBodyCheck5
	BodyCheck5:
	LOAD NextX
	SUB Body5X
	JNEG EndBodyCheck5
	JPOS EndBodyCheck5
	LOAD NextY
	SUB Body5Y
	JNEG EndBodyCheck5
	JPOS EndBodyCheck5
	JUMP SnakeLose
	EndBodyCheck5:

	LOADI 16
	CALL DEBUG

	; Now we must shift all body parts back and add our new node to the front
	; must shift back from back to front
	LOAD Body4X
	STORE Body5X
	LOAD Body4Y
	STORE Body5Y
	LOAD Body3X
	STORE Body4X
	LOAD Body3Y
	STORE Body4Y
	LOAD Body2X
	STORE Body3X
	LOAD Body2Y
	STORE Body3Y
	LOAD Body1X
	STORE Body2X
	LOAD Body1Y
	STORE Body2Y
	; now Body1 is open to fill in
	LOAD NextX
	STORE Body1X
	LOAD NextY
	STORE Body1Y

	LOADI 32
	CALL DEBUG

	; Now we must draw snake onto screen, meaning draw new head, if we ate apple, inc size, erase old tail if we didnt ate apple (if we lost this, that means we won anyway, so we dont need it).
	LOAD NextX
	STORE   XYToIndexX
	LOAD NextY
	STORE   XYToIndexY
	CALL    XYToIndex ; get head's index
	AND		EightBits
	OUT		Neo_Addr
	LOAD	SnakeColor
	OUT		Neo_Single16
	
	; erase old tail (make sure to increment CurBodySize first so that if we grow it removes the correct thing)
	LOAD EatingApple
	JPOS IncSize
	JUMP EndIncSize
	; JZERO EraseTail
	; JUMP GetNewApplePosLabel

	IncSize:
		LOAD CurBodySize ; inc size
		ADDI 1
		STORE CurBodySize
	EndIncSize:

	LOAD EatingApple
	JZERO EraseTail ; erase tail if we didnt eat an apple
	JUMP EndEraseTail

	EraseTail: ; only erase tail if we didnt eat an apple!
		; erase tail - tail will be the (CurBodySize + 1)th body
		LOAD CurBodySize
		ADDI -1
		JZERO EraseBody2 ; if new body size is 1, erase body 2
		ADDI -1
		JZERO EraseBody3 ; if new body size is 2, erase body 3, etc...
		ADDI -1
		JZERO EraseBody4
		ADDI -1
		JZERO EraseBody5
		
		EraseBody2:
			LOAD Body2X
			STORE   XYToIndexX
			LOAD Body2Y
			STORE   XYToIndexY
			JUMP EndEraseBody
		EraseBody3:
			LOAD Body3X
			STORE   XYToIndexX
			LOAD Body3Y
			STORE   XYToIndexY
			JUMP EndEraseBody
		EraseBody4:
			LOAD Body4X
			STORE   XYToIndexX
			LOAD Body4Y
			STORE   XYToIndexY
			JUMP EndEraseBody
		EraseBody5:
			LOAD Body5X
			STORE   XYToIndexX
			LOAD Body5Y
			STORE   XYToIndexY
			JUMP EndEraseBody

		EndEraseBody:

		CALL    XYToIndex ; get old tail's index
		AND		EightBits
		OUT		Neo_Addr
		LOAD	Background ; set to background color
		OUT		Neo_Single16
		; JUMP EndEraseTail
	EndEraseTail:

	LOAD EatingApple
	JPOS GetNewApplePosLabel
	JUMP EndGetNewApplePosLabel

	GetNewApplePosLabel:
		; if EatingApple = 1: CALL GetNewApplePos to generate a new apple pos
		CALL GetNewApplePos
		JUMP EndGetNewApplePosLabel
	EndGetNewApplePosLabel:

	LOADI 64
	CALL DEBUG

	; draw apple position regardless of EatingApple
	CALL DrawNewApplePos

	LOADI 128
	CALL DEBUG

	JUMP SnakeGameLoop

SnakeLose:
	; set screen to all red, maybe put snake length on hex display
	LOAD	LoseColor
	OUT		Neo_All16
	LOAD CurBodySize
	OUT Hex0
	LOADI 256
	CALL DEBUG
	JUMP SnakeLose

SnakeWin:
	; set screen to all green, maybe put snake length of hex display also
    LOAD	WinColor
	OUT		Neo_All16
	LOAD CurBodySize
	OUT Hex0
	LOADI 512
	CALL DEBUG
	JUMP SnakeWin

XYToIndex:
	LOAD XYToIndexY
	AND Bit0
	JPOS XYToIndexOdd
	JUMP XYToIndexEven

	XYToIndexEven:
		LOAD XYToIndexY
		ADDI 1
		SHIFT 5
		SUB XYToIndexX
		ADDI -1
		JUMP EndXYToIndex
	XYToIndexOdd:
		LOAD XYToIndexY
		SHIFT 5 ; * 32
		ADD XYToIndexX
		JUMP EndXYToIndex

	EndXYToIndex:
	RETURN

GetNewApplePos:
	LOADI 1 ; reset prevkey1
	STORE PrevKey1
	LOADI 0 ; reset ApplePosCounter
	STORE ApplePosCounter
	GetNewApplePosLoop:
		LOAD ApplePosCounter
		ADDI 1
		AND EightBits ; keep within [0-255]
		STORE ApplePosCounter
		LOAD PrevKey1
		STORE Temp
		IN		Key1
		STORE PrevKey1
		JZERO	GetNewApplePosLoop ; user is pressing key1, loop until they let go
		; if we get here they aren't pressing key1, check if they used to be
		LOAD Temp
		JZERO GetNewApplePosLoopEnd; they used to be pressing key1, finish loop
		JUMP GetNewApplePosLoop
	GetNewApplePosLoopEnd:

	; now we use ApplePosCounter to extract a x and y value, x is easier since its a power of 2
	; XXXXXYYY
	LOAD ApplePosCounter
	SHIFT -3
	AND LowFiveBits ; XXXXX
	STORE AppleX

	LOAD ApplePosCounter
	AND LowThreeBits ; YYY
	; y is [0-5], so if this is > 5, subtract 2, so if its 6 it becomes 2 and it its 7 it becomes 3
	ADDI -5
	JPOS AppleSubTwo
	; otherwise just store y
	LOAD ApplePosCounter
	AND LowThreeBits
	STORE AppleY
	JUMP EndAppleSub
	AppleSubTwo:
		LOAD ApplePosCounter
		AND LowThreeBits
		ADDI -4
		STORE AppleY
	EndAppleSub:
	RETURN

DrawNewApplePos:
	LOAD AppleX
	STORE XYToIndexX
	LOAD AppleY
	STORE XYToIndexY
	CALL    XYToIndex ; get old tail's index
	AND		EightBits
	OUT		Neo_Addr
	LOAD	FruitColor ; set to fruit color
	OUT		Neo_Single16
	RETURN

DEBUG:
	OUT LEDs
	RETURN

;*******************************************************************************
; Subroutine to configure the I2C for reading accelerometer data.
; Only needs to be done once after each reset.
;*******************************************************************************
SetupI2C:
	LOAD   AccCfg      ; load the number of commands
	STORE  CmdCnt
	LOADI  AccCfg      ; Load list address
	ADDI   1           ; Increment to first command
	STORE  CmdPtr
I2CCmdLoop:
	CALL   BlockI2C    ; wait for idle
	LOAD   I2CWCmd     ; load write command
	OUT    I2C_CMD     ; to I2C_CMD register
	ILOAD  CmdPtr      ; load current command
	OUT    I2C_DATA    ; to I2C_DATA register
	OUT    I2C_RDY     ; start the communication
	CALL   BlockI2C    ; wait for it to finish
	LOAD   CmdPtr
	ADDI   1           ; Increment to next command
	STORE  CmdPtr
	LOAD   CmdCnt
	ADDI   -1          ; Check if finished
	STORE  CmdCnt
	JPOS   I2CCmdLoop
	RETURN
CmdPtr: DW 0
CmdCnt: DW 0

;*******************************************************************************
; Subroutine to read the X-direction acceleration.
; Returns the value in AC.
;*******************************************************************************
ReadX:
	CALL   BlockI2C    ; ensure bus is idle
	LOAD   I2CRCmd     ; load read command
	OUT    I2C_CMD     ; send read command to I2C_CMD register
	LOAD   AccXAddr    ; load ADXL345 register address for X acceleration 
	OUT    I2C_DATA    ; send to I2C_DATA register
	OUT    I2C_RDY     ; start the communication
	CALL   BlockI2C    ; wait for it to finish
	IN     I2C_data    ; put the data in AC
	CALL   SwapBytes   ; bytes are returned in wrong order; swap them
	RETURN
ReadY:
	CALL   BlockI2C    ; ensure bus is idle
	LOAD   I2CRCmd     ; load read command
	OUT    I2C_CMD     ; send read command to I2C_CMD register
	LOAD   AccYAddr    ; load ADXL345 register address for X acceleration 
	OUT    I2C_DATA    ; send to I2C_DATA register
	OUT    I2C_RDY     ; start the communication
	CALL   BlockI2C    ; wait for it to finish
	IN     I2C_data    ; put the data in AC
	CALL   SwapBytes   ; bytes are returned in wrong order; swap them
	RETURN
; This subroutine swaps the high and low bytes in AC
SwapBytes:
	STORE  SBT1
	SHIFT  8
	STORE  SBT2
	LOAD   SBT1
	SHIFT  -8
	AND    LoByte
	OR     SBT2
	RETURN
SBT1: DW 0
SBT2: DW 0

;*******************************************************************************
; Subroutine to block until I2C peripheral is idle.
; Enters error loop if no response for ~0.1 seconds.
;*******************************************************************************
BlockI2C:
	LOAD   Zero
	STORE  Temp        ; Used to check for timeout
BI2CL:
	LOAD   Temp
	ADDI   1           ; this will result in ~0.1s timeout
	STORE  Temp
	JZERO  I2CError    ; Timeout occurred; error
	IN     I2C_RDY     ; Read busy signal
	JPOS   BI2CL       ; If not 0, try again
	RETURN             ; Else return
I2CError:
	LOAD   Zero
	ADDI   &H12C       ; "I2C"
	OUT    Hex0        ; display error message
	JUMP   I2CError

;*******************************************************************************
; DelayAC: Pause for some multiple of 0.1 seconds.
; Call this with the desired delay in AC.
; E.g. if AC is 10, this will delay for 10*0.1 = 1 second
;*******************************************************************************
DelayAC:
	STORE  DelayTime   ; Save the desired delay
	OUT    Timer       ; Reset the timer
WaitingLoop:
	IN     Timer       ; Get the current timer value
	SUB    DelayTime
	JNEG   WaitingLoop ; Repeat until timer = delay value
	RETURN
DelayTime: DW 0

;*******************************************************************************
; Abs: 2's complement absolute value
; Returns abs(AC) in AC
; Negate: 2's complement negation
; Returns -AC in AC
;*******************************************************************************
Abs:
	JPOS   Abs_r
Negate:
	XOR    NegOne       ; Flip all bits
	ADDI   1            ; Add one (i.e. negate 2's complement number)
Abs_r:
	RETURN
A2_R1n: ; region 1 negative
	ADDI   360          ; Add 360 if we are in octant 8
	RETURN
A2_R3: ; region 3
	CALL   A2_calc      ; Octants 4, 5            
	ADDI   180          ; theta' = theta + 180
	RETURN
A2_sw: ; switch arguments; octants 2, 3, 6, 7 
	LOAD   AtanY        ; Swap input arguments
	STORE  AtanT
	LOAD   AtanX
	STORE  AtanY
	LOAD   AtanT
	STORE  AtanX
	JPOS   A2_R2        ; If Y positive, octants 2,3
	CALL   A2_calc      ; else octants 6, 7
	CALL   Negate       ; Negatge the number
	ADDI   270          ; theta' = 270 - theta
	RETURN
A2_R2: ; region 2
	CALL   A2_calc      ; Octants 2, 3
	CALL   Negate       ; negate the angle
	ADDI   90           ; theta' = 90 - theta
	RETURN
A2_calc:
	; calculates R/(1 + 0.28125*R^2)
	LOAD   AtanY
	STORE  d16sN        ; Y in numerator
	LOAD   AtanX
	STORE  d16sD        ; X in denominator
	CALL   A2_div       ; divide
	LOAD   dres16sQ     ; get the quotient (remainder ignored)
	STORE  AtanRatio
	STORE  m16sA
	STORE  m16sB
	CALL   A2_mult      ; X^2
	STORE  m16sA
	LOAD   A2c
	STORE  m16sB
	CALL   A2_mult
	ADDI   256          ; 256/256+0.28125X^2
	STORE  d16sD
	LOAD   AtanRatio
	STORE  d16sN        ; Ratio in numerator
	CALL   A2_div       ; divide
	LOAD   dres16sQ     ; get the quotient (remainder ignored)
	STORE  m16sA        ; <= result in radians
	LOAD   A2cd         ; degree conversion factor
	STORE  m16sB
	CALL   A2_mult      ; convert to degrees
	STORE  AtanT
	SHIFT  -7           ; check 7th bit
	AND    One
	JZERO  A2_rdwn      ; round down
	LOAD   AtanT
	SHIFT  -8
	ADDI   1            ; round up
	RETURN
A2_rdwn:
	LOAD   AtanT
	SHIFT  -8           ; round down
	RETURN
A2_mult: ; multiply, and return bits 23..8 of result
	CALL   Mult16s
	LOAD   mres16sH
	SHIFT  8            ; move high word of result up 8 bits
	STORE  mres16sH
	LOAD   mres16sL
	SHIFT  -8           ; move low word of result down 8 bits
	AND    LoByte
	OR     mres16sH     ; combine high and low words of result
	RETURN
A2_div: ; 16-bit division scaled by 256, minimizing error
	LOADI  9            ; loop 8 times (256 = 2^8)
	STORE  AtanT
A2_DL:
	LOAD   AtanT
	ADDI   -1
	JPOS   A2_DN        ; not done; continue shifting
	CALL   Div16s       ; do the standard division
	RETURN
A2_DN:
	STORE  AtanT
	LOAD   d16sN        ; start by trying to scale the numerator
	SHIFT  1
	XOR    d16sN        ; if the sign changed,
	JNEG   A2_DD        ; switch to scaling the denominator
	XOR    d16sN        ; get back shifted version
	STORE  d16sN
	JUMP   A2_DL
A2_DD:
	LOAD   d16sD
	SHIFT  -1           ; have to scale denominator
	STORE  d16sD
	JUMP   A2_DL
AtanX:      DW 0
AtanY:      DW 0
AtanRatio:  DW 0        ; =y/x
AtanT:      DW 0        ; temporary value
A2c:        DW 72       ; 72/256=0.28125, with 8 fractional bits
A2cd:       DW 14668    ; = 180/pi with 8 fractional bits

;*******************************************************************************
; Mult16s:  16x16->32-bit signed multiplication
; Based on Booth's algorithm.
; Written by Kevin Johnson.  No licence or copyright applied.
; Warning: does not work with factor B = -32768 (most-negative number).
; To use:
; - Store factors in m16sA and m16sB.
; - Call Mult16s
; - Result is stored in mres16sH and mres16sL (high and low words).
;*******************************************************************************
Mult16s:
	LOADI  0
	STORE  m16sc        ; clear carry
	STORE  mres16sH     ; clear result
	LOADI  16           ; load 16 to counter
Mult16s_loop:
	STORE  mcnt16s      
	LOAD   m16sc        ; check the carry (from previous iteration)
	JZERO  Mult16s_noc  ; if no carry, move on
	LOAD   mres16sH     ; if a carry, 
	ADD    m16sA        ;  add multiplicand to result H
	STORE  mres16sH
Mult16s_noc: ; no carry
	LOAD   m16sB
	AND    One          ; check bit 0 of multiplier
	STORE  m16sc        ; save as next carry
	JZERO  Mult16s_sh   ; if no carry, move on to shift
	LOAD   mres16sH     ; if bit 0 set,
	SUB    m16sA        ;  subtract multiplicand from result H
	STORE  mres16sH
Mult16s_sh:
	LOAD   m16sB
	SHIFT  -1           ; shift result L >>1
	AND    c7FFF        ; clear msb
	STORE  m16sB
	LOAD   mres16sH     ; load result H
	SHIFT  15           ; move lsb to msb
	OR     m16sB
	STORE  m16sB        ; result L now includes carry out from H
	LOAD   mres16sH
	SHIFT  -1
	STORE  mres16sH     ; shift result H >>1
	LOAD   mcnt16s
	ADDI   -1           ; check counter
	JPOS   Mult16s_loop ; need to iterate 16 times
	LOAD   m16sB
	STORE  mres16sL     ; multiplier and result L shared a word
	RETURN              ; Done
c7FFF: DW &H7FFF
m16sA: DW 0 ; multiplicand
m16sB: DW 0 ; multipler
m16sc: DW 0 ; carry
mcnt16s: DW 0 ; counter
mres16sL: DW 0 ; result low
mres16sH: DW 0 ; result high

;*******************************************************************************
; Div16s:  16bit/16bit -> 16bit R16bit signed division
; Written by Kevin Johnson.  No licence or copyright applied.
; Warning: Results undefined if denominator = 0.
; To use:
; - Store numerator in d16sN and denominator in d16sD.
; - Call Div16s
; - Result is stored in dres16sQ and dres16sR (quotient and remainder).
; Requires Abs subroutine
;*******************************************************************************
Div16s:
	LOADI  0
	STORE  dres16sR     ; clear remainder result
	STORE  d16sC1       ; clear carry
	LOAD   d16sN
	XOR    d16sD
	STORE  d16sS        ; sign determination = N XOR D
	LOADI  17
	STORE  d16sT        ; preload counter with 17 (16+1)
	LOAD   d16sD
	CALL   Abs          ; take absolute value of denominator
	STORE  d16sD
	LOAD   d16sN
	CALL   Abs          ; take absolute value of numerator
	STORE  d16sN
Div16s_loop:
	LOAD   d16sN
	SHIFT  -15          ; get msb
	AND    One          ; only msb (because shift is arithmetic)
	STORE  d16sC2       ; store as carry
	LOAD   d16sN
	SHIFT  1            ; shift <<1
	OR     d16sC1       ; with carry
	STORE  d16sN
	LOAD   d16sT
	ADDI   -1           ; decrement counter
	JZERO  Div16s_sign  ; if finished looping, finalize result
	STORE  d16sT
	LOAD   dres16sR
	SHIFT  1            ; shift remainder
	OR     d16sC2       ; with carry from other shift
	SUB    d16sD        ; subtract denominator from remainder
	JNEG   Div16s_add   ; if negative, need to add it back
	STORE  dres16sR
	LOADI  1
	STORE  d16sC1       ; set carry
	JUMP   Div16s_loop
Div16s_add:
	ADD    d16sD        ; add denominator back in
	STORE  dres16sR
	LOADI  0
	STORE  d16sC1       ; clear carry
	JUMP   Div16s_loop
Div16s_sign:
	LOAD   d16sN
	STORE  dres16sQ     ; numerator was used to hold quotient result
	LOAD   d16sS        ; check the sign indicator
	JNEG   Div16s_neg
	RETURN
Div16s_neg:
	LOAD   dres16sQ     ; need to negate the result
	CALL   Negate
	STORE  dres16sQ
	RETURN	
d16sN: DW 0 ; numerator
d16sD: DW 0 ; denominator
d16sS: DW 0 ; sign value
d16sT: DW 0 ; temp counter
d16sC1: DW 0 ; carry value
d16sC2: DW 0 ; carry value
dres16sQ: DW 0 ; quotient result
dres16sR: DW 0 ; remainder result

L2A:  DW 0
L2B:  DW 0
L2T1: DW 0
L2T2: DW 0
L2T3: DW 0


;*******************************************************************************


; Variables
Temp:      DW 0
Pattern:   DW 0
Score:     DW 0
ScreenWidth: DW 32
ScreenHeight: DW 6
XYToIndexX:   DW 0
XYToIndexY:   DW 0
PrevKey1:     DW 0
ApplePosCounter: DW 0
Background:  DW &B0000000000011111 ; blue
SnakeColor:  DW &B1111111111100000 ; yellow
LoseColor:   DW &B1111100000000000 ; red
WinColor:    DW &B0000011111100000 ; green
FruitColor:  DW &B1111100000000000 ; red
ReadYAbsTemp: DW 0

CurReadX: DW 0
CurReadY: DW 0
NextX:    DW 0
NextY:    DW 0
CurDir:   DW 0
NewDir:   DW 0
AppleX:   DW 0
AppleY:   DW 0
EatingApple: DW 0
; x and y are 0 at bottom left of screen, pixels start at bottom right and snake
; we need to hardcode memory locations for Body1X, Body1Y, Body1Exists, etc. ...
MaxBodySize: DW 5 ; constant value    board is 32 wide, 6 tall
CurBodySize:   DW 1
Body1X:        DW 16 ; this is head
Body1Y:        DW 3
Body2X:        DW 0
Body2Y:        DW 0
Body3X:        DW 0
Body3Y:        DW 0
Body4X:        DW 0
Body4Y:        DW 0
Body5X:        DW 0
Body5Y:        DW 0

; Useful values
Zero:      DW 0
NegOne:    DW -1
One:       DW 1
Bit0:      DW &B0000000001
Bit1:      DW &B0000000010
Bit2:      DW &B0000000100
Bit3:      DW &B0000001000
Bit4:      DW &B0000010000
Bit5:      DW &B0000100000
Bit6:      DW &B0001000000
Bit7:      DW &B0010000000
Bit8:      DW &B0100000000
Bit9:      DW &B1000000000
LoByte:    DW &H00FF
HiByte:    DW &HFF00
EightBits: DW &HFF
LowThreeBits: DW &B111
LowFiveBits: DW &B11111

; I2C Constants
I2CWCmd:  DW &H203A    ; write two i2c bytes, addr 0x3A
I2CRCmd:  DW &H123A    ; write one byte, read two bytes, addr 0x3A
AccXAddr: DW &H32      ; X acceleration register address.
AccYAddr: DW &H34      ; X acceleration register address.
AccCfg: ; List of commands to send the ADXL345 at startup
	DW 6           ; Number of commands to send
	DW &H3100      ; Dummy transaction to sync I2C bus if needed	
	DW &H3100      ; Dummy transaction to sync I2C bus if needed	
	DW &H3100      ; Right-justified 10-bit data, +/-2 G
	DW &H3800      ; No FIFO
	DW &H2C07      ; 12.5 samples per second
	DW &H2D08      ; No sleep


; IO address constants
Switches:  EQU &H000
LEDs:      EQU &H001
Timer:     EQU &H002
Hex0:      EQU &H004
Hex1:      EQU &H005
I2C_cmd:   EQU &H090
I2C_data:  EQU &H091
I2C_rdy:   EQU &H092
DPs:       EQU &H0E0

Neo_All16:			EQU &H0A0
Neo_Addr:			EQU &H0A1
Neo_Single16:		EQU &H0A2
Neo_Single24_R:		EQU &H0A3
Neo_Single24_GB:	EQU &H0A4
Key1:				EQU &H0AF
