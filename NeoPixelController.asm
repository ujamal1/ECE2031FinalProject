ORG 0
Start:
	LOADI	0
	STORE	Mode ; Reset the mode on reset
	LOADI	8
	OUT		Neo_All16

ChooseMode:
	LOADI	0
	OUT		Hex0
	LOADI	255
	OUT		Hex1

	LOADI	1
	OUT		LEDs
	CALL	WaitForButton
	IN		Switches		; Get the values of the switches after
	OUT		Hex1
	JZERO	SetSingle16		; the confirmation button is pressed	0
	ADDI	-1
	JZERO	SetSingle24		; 1
	ADDI	-1
	JZERO	SetAll16		; 2
	ADDI	-1
	JZERO	AutoIncrement	; 3
	ADDI	-1
	JZERO	Game			; 4
	ADDI	-1
	JZERO	Gradient		; 5
	ADDI	-1
	JZERO	SnakeGame		; 6
	ADDI	-1
	JZERO	SaveData		; 7
	ADDI	-1
	JZERO	LoadData		; 8
	JUMP    Reset       ; Else, jump to Reset
	
Reset:
	LOADI	0
	OUT		Neo_All16
	JUMP	ChooseMode

SaveData:
	LOADI	14
	OUT		Hex1
	OUT		SAVE_EN
	JUMP	ChooseMode


LoadData:
	LOADI 	15
	OUT 	Hex1
	OUT		LOAD_EN
	JUMP	ChooseMode

SetSingle16:
	LOADI	22
	SHIFT	8
	ADDI	1
	OUT		Hex0

	CALL	OutAddress
	CALL	GetColors16
	LOAD	Color16
	OUT		Neo_Single16
	JUMP	ChooseMode
	

SetSingle24:
	LOADI	36
	SHIFT	8
	ADDI	1
	OUT		Hex0
	
	CALL	OutAddress
	CALL	GetColors24
	LOAD	Color24_R
	OUT		Neo_Single24_R
	LOAD	Color24_GB
	OUT		Neo_Single24_GB
	JUMP	ChooseMode

SetAll16:
	LOADI	22
	SHIFT	8
	ADDI	10
	OUT		Hex0
	
	CALL	GetColors16
	LOAD	Color16
	OUT		Neo_All16
	JUMP	ChooseMode

AutoIncrement:
	Call OutAddress
	IncLoop:

		CALL	GetColors16
		IN		Switches
		ADDI	-512
		JPOS	ChooseMode
		LOAD	Color16
		OUT		Neo_Auto_Inc		
		JUMP 	IncLoop
		
Game:
	LOADI	32
	OUT		LEDs
	CALL	WaitForButton
	IN		Switches
	STORE	NumNeos				; The value from the switches will be our number of Neopixels to work with for the game
	
	LOADI	1
	STORE	GameDir
	
	LOADI	2
	STORE	GameSpeed
	
	LOADI	0
	STORE	GameAddress
	
	LOADI	0
	OUT		Neo_All16
	
	GameLoop:
		; First, do game logic and checks
		LOAD	GameAddress			; If the current address to be set is out of bounds, then the player failed
		JNEG	GameFail			; To be in bounds, the address must be: 0 ≤ address < NumNeos which is the same as 0 ≤ address ≤ NumNeos - 1
		SUB		NumNeos
		ADDI	1
		JPOS	GameFail
		
		; Next, check if the user has changed direction
		CALL	GameCheckButton
		
		MoveGameLED:
			; Erase the old green game marker
			LOAD	GameAddress
			OUT		Neo_Addr
			LOADI	0
			OUT		Neo_Single16
			
			; And light up the new one in the direction of GameDir
			LOAD	GameAddress
			ADD		GameDir
			STORE	GameAddress
			OUT		Neo_Addr
			LOAD	Green16
			OUT		Neo_Single16
			
			CALL	Delay			; Wait for a fifth of a second before running the loop again
			
			JUMP	GameLoop
	
	GameFail:
		; Set all the Neopixels to red to indicate the failure, then go and wait the game to start again
		LOAD	Red16
		OUT		Neo_All16
		JUMP	Game
	
	GameCheckButton:
		IN		Key1
		JZERO	ExitFunc
		; This is logic for when the button is NOT pressed
		; First let's check if it was pressed before
		LOAD	KeyPressed
		; If it wasn't, then there's nothing left to do
		JPOS	ExitFunc
		; If it was, then we should change direction
		LOAD	GameDir
		JPOS	SubDir			; If the GameDir is currently 1, then we should subtract 2 from it to make it -1 by going to SubDir
		ADD		GameSpeed		; Otherwise, add 2 to go from -1 -> 1
		STORE	GameDir
		JUMP	IncSpeed
		SubDir:
		SUB		GameSpeed
		STORE	GameDir
		
		IncSpeed:
		LOAD	GameSpeed
		ADDI	1
		STORE	GameSpeed
		ExitFunc:
		IN		Key1
		STORE	KeyPressed
		RETURN

Gradient:
	LOADI	64
	OUT		LEDs
	
	; First let's clear all the LEDs
	LOADI	0
	OUT		Neo_All16
	
	; First, let's set the first 32 to green
	LOADI	31
	STORE	GradCounter
	Grad16:
		LOAD	GradCounter
		JNEG	ResetGradCounter
		OUT		Neo_Addr
		; Create the color based on the address
		LOAD	GradCounter
		SHIFT	11
		STORE	GradColor
		LOAD	GradCounter
		SHIFT	5
		OR		GradColor
		STORE	GradColor
		LOAD	GradCounter
		OR		GradColor
		OUT		Neo_Single16
		
		LOADI	1
		CALL	DelayAC
		
		LOAD	GradCounter
		ADDI	-1
		STORE	GradCounter
		JUMP	Grad16
	ResetGradCounter:
		LOADI	63
		STORE	GradCounter
	Grad24:
		LOAD	GradCounter
		ADDI	-32
		JNEG	ChooseMode
		
		LOAD	GradCounter
		OUT		Neo_Addr
		; Color is 63 - address so that it increases in the same direction as the first row
		LOADI	63
		SUB		GradCounter
		STORE	GradColor
		
		LOAD	GradColor
		OUT		Neo_Single24_R
		LOAD	GradColor
		SHIFT	8
		OR		GradColor
		OUT		Neo_Single24_GB
		
		LOADI	1
		CALL	DelayAC
		
		LOAD	GradCounter
		ADDI	-1
		STORE	GradCounter
		JUMP	Grad24
		

SnakeGame:
	LOADI	64
	OUT		LEDs
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

SnakeGameLoop:
	LOADI 3
	CALL DELAYAC ; wait 0.1 seconds
	; DIRECTION HANDLING - Updates CurDir
    ; first determine if readx or ready is more extreme
        ; then, look at that direction and see which way its tilted more towards
    
	; move in direction of tilt, unless its the opposite of CurDir, then keep going in CurDir
    CALL ReadY
    STORE CurReadY
    CALL Abs
    STORE ReadYAbsTemp
    
    CALL ReadX
    STORE CurReadX
    CALL Abs

    SUB ReadYAbsTemp ; ACC = abs(readX) - abs(readY)
    JPOS MoreX ; if readx > ready: go to moreX
	JUMP MoreY ; if ready > go to moreY

    MoreX:
        LOAD CurReadX
		JPOS MoreLeft
		JUMP MoreRight

        MoreLeft:
			LOADI -1
			STORE NewDir
            JUMP DirOutput
        
        MoreRight:
			LOADI 1
			Store NewDir
            JUMP DirOutput

    MoreY:
        LOAD CurReadY
		JPOS MoreDown
		JUMP MoreUp

        MoreDown:
			LOADI -2
			Store NewDir
            JUMP DirOutput
        
        MoreUp:
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

	; AT THIS POINT CurDir has our current direction we will move in ============

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

	; ; check if snake's NextX, NextY is touching any of its current body parts, including the last one if EatingApple
	; ; only check body1 if curLength > 2 or (curLength == 2 and eatingapple == 1)
	; LOAD CurBodySize
	; ADDI -1
	; JNEG EndAllBodyChecks
	; JZERO CheckEatingApple1
	; JUMP StartBodyCheck1
	; CheckEatingApple1:
	; 	LOAD EatingApple
	; 	JZERO EndAllBodyChecks
	; StartBodyCheck1:
	; LOAD NextX
	; SUB Body1X
	; JNEG EndBodyCheck1
	; JPOS EndBodyCheck1
	; LOAD NextY
	; SUB Body1Y
	; JNEG EndBodyCheck1
	; JPOS EndBodyCheck1
	; JUMP SnakeLose
	; EndBodyCheck1:
	; ; only check body2 if curLength > 2 or (curLength == 2 and eatingapple == 1)
	; LOAD CurBodySize
	; ADDI -2
	; JNEG EndAllBodyChecks
	; JZERO CheckEatingApple2
	; JUMP StartBodyCheck2
	; CheckEatingApple2:
	; 	LOAD EatingApple
	; 	JZERO EndAllBodyChecks
	; StartBodyCheck2:
	; LOAD NextX
	; SUB Body2X
	; JNEG EndBodyCheck2
	; JPOS EndBodyCheck2
	; LOAD NextY
	; SUB Body2Y
	; JNEG EndBodyCheck2
	; JPOS EndBodyCheck2
	; JUMP SnakeLose
	; EndBodyCheck2:
	; ; only check body3 if curLength > 2 or (curLength == 2 and eatingapple == 1)
	; LOAD CurBodySize
	; ADDI -3
	; JNEG EndAllBodyChecks
	; JZERO CheckEatingApple3
	; JUMP StartBodyCheck3
	; CheckEatingApple3:
	; 	LOAD EatingApple
	; 	JZERO EndAllBodyChecks
	; StartBodyCheck3:
	; LOAD NextX
	; SUB Body3X
	; JNEG EndBodyCheck3
	; JPOS EndBodyCheck3
	; LOAD NextY
	; SUB Body3Y
	; JNEG EndBodyCheck3
	; JPOS EndBodyCheck3
	; JUMP SnakeLose
	; EndBodyCheck3:
	; ; only check body2 if curLength > 2 or (curLength == 2 and eatingapple == 1)
	; LOAD CurBodySize
	; ADDI -4
	; JNEG EndAllBodyChecks
	; JZERO CheckEatingApple4
	; JUMP StartBodyCheck4
	; CheckEatingApple4:
	; 	LOAD EatingApple
	; 	JZERO EndAllBodyChecks
	; StartBodyCheck4:
	; LOAD NextX
	; SUB Body4X
	; JNEG EndBodyCheck4
	; JPOS EndBodyCheck4
	; LOAD NextY
	; SUB Body4Y
	; JNEG EndBodyCheck4
	; JPOS EndBodyCheck4
	; JUMP SnakeLose
	; EndBodyCheck4:
	
	; ; LOAD EatingApple
	; ; JPOS BodyCheck5 ; if eating apple, check last body part
	; ; JUMP EndBodyCheck5
	; ; BodyCheck5:

	; ; only check body2 if curLength > 2 or (curLength == 2 and eatingapple == 1)
	; LOAD CurBodySize
	; ADDI -5
	; JNEG EndAllBodyChecks
	; JZERO CheckEatingApple5
	; JUMP StartBodyCheck5
	; CheckEatingApple5:
	; 	LOAD EatingApple
	; 	JZERO EndAllBodyChecks
	; StartBodyCheck5:
	; LOAD NextX
	; SUB Body5X
	; JNEG EndBodyCheck5
	; JPOS EndBodyCheck5
	; LOAD NextY
	; SUB Body5Y
	; JNEG EndBodyCheck5
	; JPOS EndBodyCheck5
	; JUMP SnakeLose
	; EndBodyCheck5:

	; EndAllBodyChecks:

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
	EndEraseTail:

	LOAD EatingApple
	JPOS GetNewApplePosLabel
	JUMP EndGetNewApplePosLabel

	GetNewApplePosLabel:
		; if EatingApple = 1: CALL GetNewApplePos to generate a new apple pos
		CALL GetNewApplePos
		JUMP EndGetNewApplePosLabel
	EndGetNewApplePosLabel:

	; draw apple position regardless of EatingApple
	CALL DrawNewApplePos

	LOAD CurBodySize
	OUT Hex0
	JUMP SnakeGameLoop

SnakeLose:
	; set screen to all red, maybe put snake length on hex display
	LOAD	LoseColor
	OUT		Neo_All16
	LOAD CurBodySize
	OUT Hex0
	CALL	WaitForButton
	JUMP 	SnakeGame

SnakeWin:
	; set screen to all green, maybe put snake length of hex display also
    LOAD	WinColor
	OUT		Neo_All16
	LOAD CurBodySize
	OUT Hex0
	CALL	WaitForButton
	JUMP    SnakeGame

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
		STORE PrevKey1Temp
		IN		Key1
		STORE PrevKey1
		JZERO	GetNewApplePosLoop ; user is pressing key1, loop until they let go
		; if we get here they aren't pressing key1, check if they used to be
		LOAD PrevKey1Temp
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

Delay:
	OUT    Timer
GameWaitingLoop:
	CALL	GameCheckButton
	IN		Timer
	ADDI	-1
	JNEG	GameWaitingLoop
	RETURN
	

WaitForButton:
	IN		Key1
	JPOS	WaitForButton	; Button is not pressed, check again
	WaitForRelease:
		IN		Key1		; Button was just pressed, wait for it to be released
		JZERO	WaitForRelease
	RETURN

; Gets the Neopixel address from the switches and writes it to the address peripheral
OutAddress:
	LOADI	2
	OUT		LEDs
	CALL	WaitForButton
	IN		Switches
	AND		EightBits		; Mask off the rightmost eight bits to fit the
	OUT		Neo_Addr		; address length and store them in the peripheral
	RETURN

; Gets the values for a 16 bit color and stores the value in the Color16 variable
GetColors16:
	; Color Format:
	; Red   Green  Blue
	; 00000 000000 00000

	LOADI	4
	OUT		LEDs
	; Read in the red color
	CALL	WaitForButton
	IN		Switches
	AND		FiveBits
	SHIFT	11
	STORE	Color16
	
	LOADI	8
	OUT		LEDs
	; Read in the green color
	CALL	WaitForButton
	IN		Switches
	AND		SixBits
	SHIFT	5
	OR		Color16
	STORE	Color16
	
	LOADI	16
	OUT		LEDs
	; Read in the blue color
	CALL	WaitForButton
	IN		Switches
	AND		FiveBits
	OR		Color16
	STORE	Color16
	
	RETURN
	
; Gets the values for a 24 bit color and stores the value in the Color24_1 and Color24_2 variables
GetColors24:
	; Color Format:
	; Color24_R         Color24_GB
	; Zeros    Red      Green    Blue
	; 00000000 00000000 00000000 00000000
	
	LOADI	4
	OUT		LEDs
	; Read in the red color
	CALL	WaitForButton
	IN		Switches
	AND		EightBits
	STORE	Color24_R
	
	LOADI	8
	OUT		LEDs
	; Read in the green color
	CALL	WaitForButton
	IN		Switches
	AND		EightBits
	SHIFT	8
	STORE	Color24_GB
	
	LOADI	16
	OUT		LEDs
	; Read in the blue color
	CALL	WaitForButton
	IN		Switches
	AND		EightBits
	OR		Color24_GB
	STORE	Color24_GB
	
	RETURN

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
	STORE  I2CTemp        ; Used to check for timeout
BI2CL:
	LOAD   I2CTemp
	ADDI   1           ; this will result in ~0.1s timeout
	STORE  I2CTemp
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


; Variables
Mode:			DW 0
Color16:		DW 0
Color24_R:		DW 0
Color24_GB:		DW 0
AutoAddress:	DW 0
GameAddress:	DW 0
GameDir:		DW 0 ; Game Direction
GameSpeed:		DW 0
NumNeos:		DW 0
KeyPressed:		DW 0
GradColor:		DW 0
GradCounter:	DW 0

; SnakeGame variables
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
ScreenWidth: DW 32
ScreenHeight: DW 6
XYToIndexX:   DW 0
XYToIndexY:   DW 0
PrevKey1:     DW 0
ApplePosCounter: DW 0
Background:  DW &B0001100001100011 ; dim white
SnakeColor:  DW &B1111111111100000 ; yellow
LoseColor:   DW &B1111100000000000 ; red
WinColor:    DW &B0000011111100000 ; green
FruitColor:  DW &B1111100000000000 ; red
ReadYAbsTemp: DW 0
PrevKey1Temp: DW 0

; Constants
FiveBits:	DW	31
SixBits:	DW	63
EightBits:	DW	255
Green16:	DW	&B11111100000;
Red16:		DW	&B1111100000000000;
Bit0:      DW &B0000000001
LowThreeBits: DW &B111
LowFiveBits: DW &B11111
LoByte:    DW &H00FF
HiByte:    DW &HFF00
Zero:      DW 0
NegOne:    DW -1

; IO address constants
Switches:	EQU &H000
LEDs:		EQU &H001
Timer:		EQU &H002
Hex0:		EQU &H004
Hex1:		EQU &H005
I2C_cmd:	EQU &H090
I2C_data:	EQU &H091
I2C_rdy:	EQU &H092

; I2C Constants
I2CWCmd:  DW &H203A    ; write two i2c bytes, addr 0x3A
I2CRCmd:  DW &H123A    ; write one byte, read two bytes, addr 0x3A
AccXAddr: DW &H32      ; X acceleration register address.
AccYAddr: DW &H34      ; X acceleration register address.
I2CTemp:  DW 0


Neo_All16:			EQU &H0A0
Neo_Addr:			EQU &H0A1
Neo_Single16:		EQU &H0A2
Neo_Single24_R:		EQU &H0A3
Neo_Single24_GB:	EQU &H0A4
Neo_Auto_Inc:		EQU &H0A7
Key1:				EQU &H0AF
SAVE_EN:				EQU &H0A5
LOAD_EN:				EQU &H0A6