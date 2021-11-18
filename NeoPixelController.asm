ORG 0
Start:
	LOADI	0
	STORE	Mode ; Reset the mode on reset

ChooseMode:
	LOADI	1
	OUT		LEDs
	CALL	WaitForButton
	IN		Switches		; Get the values of the switches after
	JZERO	SetSingle16		; the confirmation button is pressed
	ADDI	-1
	JZERO	SetSingle24
	ADDI	-1
	JZERO	SetAll16
	ADDI	-1
	JZERO	AutoIncrement
	ADDI	-1
	JZERO	Game
	JUMP    SnakeGame       ; Else, jump to SnakeGame

SetSingle16:
	CALL	OutAddress
	CALL	GetColors16
	LOAD	Color16
	OUT		Neo_Single16
	JUMP	ChooseMode
	

SetSingle24:
	CALL	OutAddress
	CALL	GetColors24
	LOAD	Color24_R
	OUT		Neo_Single24_R
	LOAD	Color24_GB
	OUT		Neo_Single24_GB
	JUMP	ChooseMode

SetAll16:
	CALL	GetColors16
	LOAD	Color16
	OUT		Neo_All16
	JUMP	ChooseMode

AutoIncrement:
	LOADI 0
	STORE AutoAddress
	
	IncLoop:
		LOAD	AutoAddress
		OUT		Neo_Addr
		CALL	GetColors16
		OUT		Neo_Single16
		
		LOAD	AutoAddress
		ADDI	1
		STORE	AutoAddress
		
		JUMP IncLoop
		
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

	; check if snake's NextX, NextY is touching any of its current body parts, including the last one if EatingApple
	; CODE GEN 1
    LOAD NextX
    SUB Body1X
    JNEG EndBodyCheck1
    JPOS EndBodyCheck1
    LOAD NextY
    SUB Body1Y
    JZERO SnakeLose
    EndBodyCheck1:
    LOAD NextX
    SUB Body2X
    JNEG EndBodyCheck2
    JPOS EndBodyCheck2
    LOAD NextY
    SUB Body2Y
    JZERO SnakeLose
    EndBodyCheck2:
    LOAD NextX
    SUB Body3X
    JNEG EndBodyCheck3
    JPOS EndBodyCheck3
    LOAD NextY
    SUB Body3Y
    JZERO SnakeLose
    EndBodyCheck3:
    LOAD NextX
    SUB Body4X
    JNEG EndBodyCheck4
    JPOS EndBodyCheck4
    LOAD NextY
    SUB Body4Y
    JZERO SnakeLose
    EndBodyCheck4:
    LOAD NextX
    SUB Body5X
    JNEG EndBodyCheck5
    JPOS EndBodyCheck5
    LOAD NextY
    SUB Body5Y
    JZERO SnakeLose
    EndBodyCheck5:
    LOAD NextX
    SUB Body6X
    JNEG EndBodyCheck6
    JPOS EndBodyCheck6
    LOAD NextY
    SUB Body6Y
    JZERO SnakeLose
    EndBodyCheck6:
    LOAD NextX
    SUB Body7X
    JNEG EndBodyCheck7
    JPOS EndBodyCheck7
    LOAD NextY
    SUB Body7Y
    JZERO SnakeLose
    EndBodyCheck7:
    LOAD NextX
    SUB Body8X
    JNEG EndBodyCheck8
    JPOS EndBodyCheck8
    LOAD NextY
    SUB Body8Y
    JZERO SnakeLose
    EndBodyCheck8:
    LOAD NextX
    SUB Body9X
    JNEG EndBodyCheck9
    JPOS EndBodyCheck9
    LOAD NextY
    SUB Body9Y
    JZERO SnakeLose
    EndBodyCheck9:
    LOAD NextX
    SUB Body10X
    JNEG EndBodyCheck10
    JPOS EndBodyCheck10
    LOAD NextY
    SUB Body10Y
    JZERO SnakeLose
    EndBodyCheck10:
    LOAD NextX
    SUB Body11X
    JNEG EndBodyCheck11
    JPOS EndBodyCheck11
    LOAD NextY
    SUB Body11Y
    JZERO SnakeLose
    EndBodyCheck11:
    LOAD NextX
    SUB Body12X
    JNEG EndBodyCheck12
    JPOS EndBodyCheck12
    LOAD NextY
    SUB Body12Y
    JZERO SnakeLose
    EndBodyCheck12:
    LOAD NextX
    SUB Body13X
    JNEG EndBodyCheck13
    JPOS EndBodyCheck13
    LOAD NextY
    SUB Body13Y
    JZERO SnakeLose
    EndBodyCheck13:
    LOAD NextX
    SUB Body14X
    JNEG EndBodyCheck14
    JPOS EndBodyCheck14
    LOAD NextY
    SUB Body14Y
    JZERO SnakeLose
    EndBodyCheck14:
    LOAD NextX
    SUB Body15X
    JNEG EndBodyCheck15
    JPOS EndBodyCheck15
    LOAD NextY
    SUB Body15Y
    JZERO SnakeLose
    EndBodyCheck15:
    LOAD NextX
    SUB Body16X
    JNEG EndBodyCheck16
    JPOS EndBodyCheck16
    LOAD NextY
    SUB Body16Y
    JZERO SnakeLose
    EndBodyCheck16:
    LOAD NextX
    SUB Body17X
    JNEG EndBodyCheck17
    JPOS EndBodyCheck17
    LOAD NextY
    SUB Body17Y
    JZERO SnakeLose
    EndBodyCheck17:
    LOAD NextX
    SUB Body18X
    JNEG EndBodyCheck18
    JPOS EndBodyCheck18
    LOAD NextY
    SUB Body18Y
    JZERO SnakeLose
    EndBodyCheck18:
    LOAD NextX
    SUB Body19X
    JNEG EndBodyCheck19
    JPOS EndBodyCheck19
    LOAD NextY
    SUB Body19Y
    JZERO SnakeLose
    EndBodyCheck19:
    LOAD NextX
    SUB Body20X
    JNEG EndBodyCheck20
    JPOS EndBodyCheck20
    LOAD NextY
    SUB Body20Y
    JZERO SnakeLose
    EndBodyCheck20:
    LOAD NextX
    SUB Body21X
    JNEG EndBodyCheck21
    JPOS EndBodyCheck21
    LOAD NextY
    SUB Body21Y
    JZERO SnakeLose
    EndBodyCheck21:
    LOAD NextX
    SUB Body22X
    JNEG EndBodyCheck22
    JPOS EndBodyCheck22
    LOAD NextY
    SUB Body22Y
    JZERO SnakeLose
    EndBodyCheck22:
    LOAD NextX
    SUB Body23X
    JNEG EndBodyCheck23
    JPOS EndBodyCheck23
    LOAD NextY
    SUB Body23Y
    JZERO SnakeLose
    EndBodyCheck23:
    LOAD NextX
    SUB Body24X
    JNEG EndBodyCheck24
    JPOS EndBodyCheck24
    LOAD NextY
    SUB Body24Y
    JZERO SnakeLose
    EndBodyCheck24:
    LOAD NextX
    SUB Body25X
    JNEG EndBodyCheck25
    JPOS EndBodyCheck25
    LOAD NextY
    SUB Body25Y
    JZERO SnakeLose
    EndBodyCheck25:
    LOAD NextX
    SUB Body26X
    JNEG EndBodyCheck26
    JPOS EndBodyCheck26
    LOAD NextY
    SUB Body26Y
    JZERO SnakeLose
    EndBodyCheck26:
    LOAD NextX
    SUB Body27X
    JNEG EndBodyCheck27
    JPOS EndBodyCheck27
    LOAD NextY
    SUB Body27Y
    JZERO SnakeLose
    EndBodyCheck27:
    LOAD NextX
    SUB Body28X
    JNEG EndBodyCheck28
    JPOS EndBodyCheck28
    LOAD NextY
    SUB Body28Y
    JZERO SnakeLose
    EndBodyCheck28:
    LOAD NextX
    SUB Body29X
    JNEG EndBodyCheck29
    JPOS EndBodyCheck29
    LOAD NextY
    SUB Body29Y
    JZERO SnakeLose
    EndBodyCheck29:
    LOAD NextX
    SUB Body30X
    JNEG EndBodyCheck30
    JPOS EndBodyCheck30
    LOAD NextY
    SUB Body30Y
    JZERO SnakeLose
    EndBodyCheck30:
    LOAD NextX
    SUB Body31X
    JNEG EndBodyCheck31
    JPOS EndBodyCheck31
    LOAD NextY
    SUB Body31Y
    JZERO SnakeLose
    EndBodyCheck31:
    LOAD NextX
    SUB Body32X
    JNEG EndBodyCheck32
    JPOS EndBodyCheck32
    LOAD NextY
    SUB Body32Y
    JZERO SnakeLose
    EndBodyCheck32:
    LOAD NextX
    SUB Body33X
    JNEG EndBodyCheck33
    JPOS EndBodyCheck33
    LOAD NextY
    SUB Body33Y
    JZERO SnakeLose
    EndBodyCheck33:
    LOAD NextX
    SUB Body34X
    JNEG EndBodyCheck34
    JPOS EndBodyCheck34
    LOAD NextY
    SUB Body34Y
    JZERO SnakeLose
    EndBodyCheck34:
    LOAD NextX
    SUB Body35X
    JNEG EndBodyCheck35
    JPOS EndBodyCheck35
    LOAD NextY
    SUB Body35Y
    JZERO SnakeLose
    EndBodyCheck35:
    LOAD NextX
    SUB Body36X
    JNEG EndBodyCheck36
    JPOS EndBodyCheck36
    LOAD NextY
    SUB Body36Y
    JZERO SnakeLose
    EndBodyCheck36:
    LOAD NextX
    SUB Body37X
    JNEG EndBodyCheck37
    JPOS EndBodyCheck37
    LOAD NextY
    SUB Body37Y
    JZERO SnakeLose
    EndBodyCheck37:
    LOAD NextX
    SUB Body38X
    JNEG EndBodyCheck38
    JPOS EndBodyCheck38
    LOAD NextY
    SUB Body38Y
    JZERO SnakeLose
    EndBodyCheck38:
    LOAD NextX
    SUB Body39X
    JNEG EndBodyCheck39
    JPOS EndBodyCheck39
    LOAD NextY
    SUB Body39Y
    JZERO SnakeLose
    EndBodyCheck39:
    LOAD NextX
    SUB Body40X
    JNEG EndBodyCheck40
    JPOS EndBodyCheck40
    LOAD NextY
    SUB Body40Y
    JZERO SnakeLose
    EndBodyCheck40:
    LOAD NextX
    SUB Body41X
    JNEG EndBodyCheck41
    JPOS EndBodyCheck41
    LOAD NextY
    SUB Body41Y
    JZERO SnakeLose
    EndBodyCheck41:
    LOAD NextX
    SUB Body42X
    JNEG EndBodyCheck42
    JPOS EndBodyCheck42
    LOAD NextY
    SUB Body42Y
    JZERO SnakeLose
    EndBodyCheck42:
    LOAD NextX
    SUB Body43X
    JNEG EndBodyCheck43
    JPOS EndBodyCheck43
    LOAD NextY
    SUB Body43Y
    JZERO SnakeLose
    EndBodyCheck43:
    LOAD NextX
    SUB Body44X
    JNEG EndBodyCheck44
    JPOS EndBodyCheck44
    LOAD NextY
    SUB Body44Y
    JZERO SnakeLose
    EndBodyCheck44:
    LOAD NextX
    SUB Body45X
    JNEG EndBodyCheck45
    JPOS EndBodyCheck45
    LOAD NextY
    SUB Body45Y
    JZERO SnakeLose
    EndBodyCheck45:
    LOAD NextX
    SUB Body46X
    JNEG EndBodyCheck46
    JPOS EndBodyCheck46
    LOAD NextY
    SUB Body46Y
    JZERO SnakeLose
    EndBodyCheck46:
    LOAD NextX
    SUB Body47X
    JNEG EndBodyCheck47
    JPOS EndBodyCheck47
    LOAD NextY
    SUB Body47Y
    JZERO SnakeLose
    EndBodyCheck47:
    LOAD NextX
    SUB Body48X
    JNEG EndBodyCheck48
    JPOS EndBodyCheck48
    LOAD NextY
    SUB Body48Y
    JZERO SnakeLose
    EndBodyCheck48:
    LOAD NextX
    SUB Body49X
    JNEG EndBodyCheck49
    JPOS EndBodyCheck49
    LOAD NextY
    SUB Body49Y
    JZERO SnakeLose
    EndBodyCheck49:
    LOAD NextX
    SUB Body50X
    JNEG EndBodyCheck50
    JPOS EndBodyCheck50
    LOAD NextY
    SUB Body50Y
    JZERO SnakeLose
    EndBodyCheck50:
    LOAD NextX
    SUB Body51X
    JNEG EndBodyCheck51
    JPOS EndBodyCheck51
    LOAD NextY
    SUB Body51Y
    JZERO SnakeLose
    EndBodyCheck51:
    LOAD NextX
    SUB Body52X
    JNEG EndBodyCheck52
    JPOS EndBodyCheck52
    LOAD NextY
    SUB Body52Y
    JZERO SnakeLose
    EndBodyCheck52:
    LOAD NextX
    SUB Body53X
    JNEG EndBodyCheck53
    JPOS EndBodyCheck53
    LOAD NextY
    SUB Body53Y
    JZERO SnakeLose
    EndBodyCheck53:
    LOAD NextX
    SUB Body54X
    JNEG EndBodyCheck54
    JPOS EndBodyCheck54
    LOAD NextY
    SUB Body54Y
    JZERO SnakeLose
    EndBodyCheck54:
    LOAD NextX
    SUB Body55X
    JNEG EndBodyCheck55
    JPOS EndBodyCheck55
    LOAD NextY
    SUB Body55Y
    JZERO SnakeLose
    EndBodyCheck55:
    LOAD NextX
    SUB Body56X
    JNEG EndBodyCheck56
    JPOS EndBodyCheck56
    LOAD NextY
    SUB Body56Y
    JZERO SnakeLose
    EndBodyCheck56:
    LOAD NextX
    SUB Body57X
    JNEG EndBodyCheck57
    JPOS EndBodyCheck57
    LOAD NextY
    SUB Body57Y
    JZERO SnakeLose
    EndBodyCheck57:
    LOAD NextX
    SUB Body58X
    JNEG EndBodyCheck58
    JPOS EndBodyCheck58
    LOAD NextY
    SUB Body58Y
    JZERO SnakeLose
    EndBodyCheck58:
    LOAD NextX
    SUB Body59X
    JNEG EndBodyCheck59
    JPOS EndBodyCheck59
    LOAD NextY
    SUB Body59Y
    JZERO SnakeLose
    EndBodyCheck59:
    LOAD NextX
    SUB Body60X
    JNEG EndBodyCheck60
    JPOS EndBodyCheck60
    LOAD NextY
    SUB Body60Y
    JZERO SnakeLose
    EndBodyCheck60:
    LOAD NextX
    SUB Body61X
    JNEG EndBodyCheck61
    JPOS EndBodyCheck61
    LOAD NextY
    SUB Body61Y
    JZERO SnakeLose
    EndBodyCheck61:
    LOAD NextX
    SUB Body62X
    JNEG EndBodyCheck62
    JPOS EndBodyCheck62
    LOAD NextY
    SUB Body62Y
    JZERO SnakeLose
    EndBodyCheck62:
    LOAD NextX
    SUB Body63X
    JNEG EndBodyCheck63
    JPOS EndBodyCheck63
    LOAD NextY
    SUB Body63Y
    JZERO SnakeLose
    EndBodyCheck63:
    LOAD NextX
    SUB Body64X
    JNEG EndBodyCheck64
    JPOS EndBodyCheck64
    LOAD NextY
    SUB Body64Y
    JZERO SnakeLose
    EndBodyCheck64:
    LOAD NextX
    SUB Body65X
    JNEG EndBodyCheck65
    JPOS EndBodyCheck65
    LOAD NextY
    SUB Body65Y
    JZERO SnakeLose
    EndBodyCheck65:
    LOAD NextX
    SUB Body66X
    JNEG EndBodyCheck66
    JPOS EndBodyCheck66
    LOAD NextY
    SUB Body66Y
    JZERO SnakeLose
    EndBodyCheck66:
    LOAD NextX
    SUB Body67X
    JNEG EndBodyCheck67
    JPOS EndBodyCheck67
    LOAD NextY
    SUB Body67Y
    JZERO SnakeLose
    EndBodyCheck67:
    LOAD NextX
    SUB Body68X
    JNEG EndBodyCheck68
    JPOS EndBodyCheck68
    LOAD NextY
    SUB Body68Y
    JZERO SnakeLose
    EndBodyCheck68:
    LOAD NextX
    SUB Body69X
    JNEG EndBodyCheck69
    JPOS EndBodyCheck69
    LOAD NextY
    SUB Body69Y
    JZERO SnakeLose
    EndBodyCheck69:
    LOAD NextX
    SUB Body70X
    JNEG EndBodyCheck70
    JPOS EndBodyCheck70
    LOAD NextY
    SUB Body70Y
    JZERO SnakeLose
    EndBodyCheck70:
    LOAD NextX
    SUB Body71X
    JNEG EndBodyCheck71
    JPOS EndBodyCheck71
    LOAD NextY
    SUB Body71Y
    JZERO SnakeLose
    EndBodyCheck71:
    LOAD NextX
    SUB Body72X
    JNEG EndBodyCheck72
    JPOS EndBodyCheck72
    LOAD NextY
    SUB Body72Y
    JZERO SnakeLose
    EndBodyCheck72:
    LOAD NextX
    SUB Body73X
    JNEG EndBodyCheck73
    JPOS EndBodyCheck73
    LOAD NextY
    SUB Body73Y
    JZERO SnakeLose
    EndBodyCheck73:
    LOAD NextX
    SUB Body74X
    JNEG EndBodyCheck74
    JPOS EndBodyCheck74
    LOAD NextY
    SUB Body74Y
    JZERO SnakeLose
    EndBodyCheck74:
    LOAD NextX
    SUB Body75X
    JNEG EndBodyCheck75
    JPOS EndBodyCheck75
    LOAD NextY
    SUB Body75Y
    JZERO SnakeLose
    EndBodyCheck75:
    LOAD NextX
    SUB Body76X
    JNEG EndBodyCheck76
    JPOS EndBodyCheck76
    LOAD NextY
    SUB Body76Y
    JZERO SnakeLose
    EndBodyCheck76:
    LOAD NextX
    SUB Body77X
    JNEG EndBodyCheck77
    JPOS EndBodyCheck77
    LOAD NextY
    SUB Body77Y
    JZERO SnakeLose
    EndBodyCheck77:
    LOAD NextX
    SUB Body78X
    JNEG EndBodyCheck78
    JPOS EndBodyCheck78
    LOAD NextY
    SUB Body78Y
    JZERO SnakeLose
    EndBodyCheck78:
    LOAD NextX
    SUB Body79X
    JNEG EndBodyCheck79
    JPOS EndBodyCheck79
    LOAD NextY
    SUB Body79Y
    JZERO SnakeLose
    EndBodyCheck79:
    LOAD NextX
    SUB Body80X
    JNEG EndBodyCheck80
    JPOS EndBodyCheck80
    LOAD NextY
    SUB Body80Y
    JZERO SnakeLose
    EndBodyCheck80:
    LOAD NextX
    SUB Body81X
    JNEG EndBodyCheck81
    JPOS EndBodyCheck81
    LOAD NextY
    SUB Body81Y
    JZERO SnakeLose
    EndBodyCheck81:
    LOAD NextX
    SUB Body82X
    JNEG EndBodyCheck82
    JPOS EndBodyCheck82
    LOAD NextY
    SUB Body82Y
    JZERO SnakeLose
    EndBodyCheck82:
    LOAD NextX
    SUB Body83X
    JNEG EndBodyCheck83
    JPOS EndBodyCheck83
    LOAD NextY
    SUB Body83Y
    JZERO SnakeLose
    EndBodyCheck83:
    LOAD NextX
    SUB Body84X
    JNEG EndBodyCheck84
    JPOS EndBodyCheck84
    LOAD NextY
    SUB Body84Y
    JZERO SnakeLose
    EndBodyCheck84:
    LOAD NextX
    SUB Body85X
    JNEG EndBodyCheck85
    JPOS EndBodyCheck85
    LOAD NextY
    SUB Body85Y
    JZERO SnakeLose
    EndBodyCheck85:
    LOAD NextX
    SUB Body86X
    JNEG EndBodyCheck86
    JPOS EndBodyCheck86
    LOAD NextY
    SUB Body86Y
    JZERO SnakeLose
    EndBodyCheck86:
    LOAD NextX
    SUB Body87X
    JNEG EndBodyCheck87
    JPOS EndBodyCheck87
    LOAD NextY
    SUB Body87Y
    JZERO SnakeLose
    EndBodyCheck87:
    LOAD NextX
    SUB Body88X
    JNEG EndBodyCheck88
    JPOS EndBodyCheck88
    LOAD NextY
    SUB Body88Y
    JZERO SnakeLose
    EndBodyCheck88:
    LOAD NextX
    SUB Body89X
    JNEG EndBodyCheck89
    JPOS EndBodyCheck89
    LOAD NextY
    SUB Body89Y
    JZERO SnakeLose
    EndBodyCheck89:
    LOAD NextX
    SUB Body90X
    JNEG EndBodyCheck90
    JPOS EndBodyCheck90
    LOAD NextY
    SUB Body90Y
    JZERO SnakeLose
    EndBodyCheck90:
    LOAD NextX
    SUB Body91X
    JNEG EndBodyCheck91
    JPOS EndBodyCheck91
    LOAD NextY
    SUB Body91Y
    JZERO SnakeLose
    EndBodyCheck91:
    LOAD NextX
    SUB Body92X
    JNEG EndBodyCheck92
    JPOS EndBodyCheck92
    LOAD NextY
    SUB Body92Y
    JZERO SnakeLose
    EndBodyCheck92:
    LOAD NextX
    SUB Body93X
    JNEG EndBodyCheck93
    JPOS EndBodyCheck93
    LOAD NextY
    SUB Body93Y
    JZERO SnakeLose
    EndBodyCheck93:
    LOAD NextX
    SUB Body94X
    JNEG EndBodyCheck94
    JPOS EndBodyCheck94
    LOAD NextY
    SUB Body94Y
    JZERO SnakeLose
    EndBodyCheck94:
    LOAD NextX
    SUB Body95X
    JNEG EndBodyCheck95
    JPOS EndBodyCheck95
    LOAD NextY
    SUB Body95Y
    JZERO SnakeLose
    EndBodyCheck95:
    LOAD NextX
    SUB Body96X
    JNEG EndBodyCheck96
    JPOS EndBodyCheck96
    LOAD NextY
    SUB Body96Y
    JZERO SnakeLose
    EndBodyCheck96:
    LOAD NextX
    SUB Body97X
    JNEG EndBodyCheck97
    JPOS EndBodyCheck97
    LOAD NextY
    SUB Body97Y
    JZERO SnakeLose
    EndBodyCheck97:
    LOAD NextX
    SUB Body98X
    JNEG EndBodyCheck98
    JPOS EndBodyCheck98
    LOAD NextY
    SUB Body98Y
    JZERO SnakeLose
    EndBodyCheck98:
    LOAD NextX
    SUB Body99X
    JNEG EndBodyCheck99
    JPOS EndBodyCheck99
    LOAD NextY
    SUB Body99Y
    JZERO SnakeLose
    EndBodyCheck99:
    LOAD NextX
    SUB Body100X
    JNEG EndBodyCheck100
    JPOS EndBodyCheck100
    LOAD NextY
    SUB Body100Y
    JZERO SnakeLose
    EndBodyCheck100:
    LOAD NextX
    SUB Body101X
    JNEG EndBodyCheck101
    JPOS EndBodyCheck101
    LOAD NextY
    SUB Body101Y
    JZERO SnakeLose
    EndBodyCheck101:
    LOAD NextX
    SUB Body102X
    JNEG EndBodyCheck102
    JPOS EndBodyCheck102
    LOAD NextY
    SUB Body102Y
    JZERO SnakeLose
    EndBodyCheck102:
    LOAD NextX
    SUB Body103X
    JNEG EndBodyCheck103
    JPOS EndBodyCheck103
    LOAD NextY
    SUB Body103Y
    JZERO SnakeLose
    EndBodyCheck103:
    LOAD NextX
    SUB Body104X
    JNEG EndBodyCheck104
    JPOS EndBodyCheck104
    LOAD NextY
    SUB Body104Y
    JZERO SnakeLose
    EndBodyCheck104:
    LOAD NextX
    SUB Body105X
    JNEG EndBodyCheck105
    JPOS EndBodyCheck105
    LOAD NextY
    SUB Body105Y
    JZERO SnakeLose
    EndBodyCheck105:
    LOAD NextX
    SUB Body106X
    JNEG EndBodyCheck106
    JPOS EndBodyCheck106
    LOAD NextY
    SUB Body106Y
    JZERO SnakeLose
    EndBodyCheck106:
    LOAD NextX
    SUB Body107X
    JNEG EndBodyCheck107
    JPOS EndBodyCheck107
    LOAD NextY
    SUB Body107Y
    JZERO SnakeLose
    EndBodyCheck107:
    LOAD NextX
    SUB Body108X
    JNEG EndBodyCheck108
    JPOS EndBodyCheck108
    LOAD NextY
    SUB Body108Y
    JZERO SnakeLose
    EndBodyCheck108:
    LOAD NextX
    SUB Body109X
    JNEG EndBodyCheck109
    JPOS EndBodyCheck109
    LOAD NextY
    SUB Body109Y
    JZERO SnakeLose
    EndBodyCheck109:
    LOAD NextX
    SUB Body110X
    JNEG EndBodyCheck110
    JPOS EndBodyCheck110
    LOAD NextY
    SUB Body110Y
    JZERO SnakeLose
    EndBodyCheck110:
    LOAD NextX
    SUB Body111X
    JNEG EndBodyCheck111
    JPOS EndBodyCheck111
    LOAD NextY
    SUB Body111Y
    JZERO SnakeLose
    EndBodyCheck111:
    LOAD NextX
    SUB Body112X
    JNEG EndBodyCheck112
    JPOS EndBodyCheck112
    LOAD NextY
    SUB Body112Y
    JZERO SnakeLose
    EndBodyCheck112:
    LOAD NextX
    SUB Body113X
    JNEG EndBodyCheck113
    JPOS EndBodyCheck113
    LOAD NextY
    SUB Body113Y
    JZERO SnakeLose
    EndBodyCheck113:
    LOAD NextX
    SUB Body114X
    JNEG EndBodyCheck114
    JPOS EndBodyCheck114
    LOAD NextY
    SUB Body114Y
    JZERO SnakeLose
    EndBodyCheck114:
    LOAD NextX
    SUB Body115X
    JNEG EndBodyCheck115
    JPOS EndBodyCheck115
    LOAD NextY
    SUB Body115Y
    JZERO SnakeLose
    EndBodyCheck115:
    LOAD NextX
    SUB Body116X
    JNEG EndBodyCheck116
    JPOS EndBodyCheck116
    LOAD NextY
    SUB Body116Y
    JZERO SnakeLose
    EndBodyCheck116:
    LOAD NextX
    SUB Body117X
    JNEG EndBodyCheck117
    JPOS EndBodyCheck117
    LOAD NextY
    SUB Body117Y
    JZERO SnakeLose
    EndBodyCheck117:
    LOAD NextX
    SUB Body118X
    JNEG EndBodyCheck118
    JPOS EndBodyCheck118
    LOAD NextY
    SUB Body118Y
    JZERO SnakeLose
    EndBodyCheck118:
    LOAD NextX
    SUB Body119X
    JNEG EndBodyCheck119
    JPOS EndBodyCheck119
    LOAD NextY
    SUB Body119Y
    JZERO SnakeLose
    EndBodyCheck119:
    LOAD NextX
    SUB Body120X
    JNEG EndBodyCheck120
    JPOS EndBodyCheck120
    LOAD NextY
    SUB Body120Y
    JZERO SnakeLose
    EndBodyCheck120:
    LOAD NextX
    SUB Body121X
    JNEG EndBodyCheck121
    JPOS EndBodyCheck121
    LOAD NextY
    SUB Body121Y
    JZERO SnakeLose
    EndBodyCheck121:
    LOAD NextX
    SUB Body122X
    JNEG EndBodyCheck122
    JPOS EndBodyCheck122
    LOAD NextY
    SUB Body122Y
    JZERO SnakeLose
    EndBodyCheck122:
    LOAD NextX
    SUB Body123X
    JNEG EndBodyCheck123
    JPOS EndBodyCheck123
    LOAD NextY
    SUB Body123Y
    JZERO SnakeLose
    EndBodyCheck123:
    LOAD NextX
    SUB Body124X
    JNEG EndBodyCheck124
    JPOS EndBodyCheck124
    LOAD NextY
    SUB Body124Y
    JZERO SnakeLose
    EndBodyCheck124:
    LOAD NextX
    SUB Body125X
    JNEG EndBodyCheck125
    JPOS EndBodyCheck125
    LOAD NextY
    SUB Body125Y
    JZERO SnakeLose
    EndBodyCheck125:
    LOAD NextX
    SUB Body126X
    JNEG EndBodyCheck126
    JPOS EndBodyCheck126
    LOAD NextY
    SUB Body126Y
    JZERO SnakeLose
    EndBodyCheck126:
    LOAD NextX
    SUB Body127X
    JNEG EndBodyCheck127
    JPOS EndBodyCheck127
    LOAD NextY
    SUB Body127Y
    JZERO SnakeLose
    EndBodyCheck127:
    LOAD NextX
    SUB Body128X
    JNEG EndBodyCheck128
    JPOS EndBodyCheck128
    LOAD NextY
    SUB Body128Y
    JZERO SnakeLose
    EndBodyCheck128:
    LOAD NextX
    SUB Body129X
    JNEG EndBodyCheck129
    JPOS EndBodyCheck129
    LOAD NextY
    SUB Body129Y
    JZERO SnakeLose
    EndBodyCheck129:
    LOAD NextX
    SUB Body130X
    JNEG EndBodyCheck130
    JPOS EndBodyCheck130
    LOAD NextY
    SUB Body130Y
    JZERO SnakeLose
    EndBodyCheck130:
    LOAD NextX
    SUB Body131X
    JNEG EndBodyCheck131
    JPOS EndBodyCheck131
    LOAD NextY
    SUB Body131Y
    JZERO SnakeLose
    EndBodyCheck131:
    LOAD NextX
    SUB Body132X
    JNEG EndBodyCheck132
    JPOS EndBodyCheck132
    LOAD NextY
    SUB Body132Y
    JZERO SnakeLose
    EndBodyCheck132:
    LOAD NextX
    SUB Body133X
    JNEG EndBodyCheck133
    JPOS EndBodyCheck133
    LOAD NextY
    SUB Body133Y
    JZERO SnakeLose
    EndBodyCheck133:
    LOAD NextX
    SUB Body134X
    JNEG EndBodyCheck134
    JPOS EndBodyCheck134
    LOAD NextY
    SUB Body134Y
    JZERO SnakeLose
    EndBodyCheck134:
    LOAD NextX
    SUB Body135X
    JNEG EndBodyCheck135
    JPOS EndBodyCheck135
    LOAD NextY
    SUB Body135Y
    JZERO SnakeLose
    EndBodyCheck135:
    LOAD NextX
    SUB Body136X
    JNEG EndBodyCheck136
    JPOS EndBodyCheck136
    LOAD NextY
    SUB Body136Y
    JZERO SnakeLose
    EndBodyCheck136:
    LOAD NextX
    SUB Body137X
    JNEG EndBodyCheck137
    JPOS EndBodyCheck137
    LOAD NextY
    SUB Body137Y
    JZERO SnakeLose
    EndBodyCheck137:
    LOAD NextX
    SUB Body138X
    JNEG EndBodyCheck138
    JPOS EndBodyCheck138
    LOAD NextY
    SUB Body138Y
    JZERO SnakeLose
    EndBodyCheck138:
    LOAD NextX
    SUB Body139X
    JNEG EndBodyCheck139
    JPOS EndBodyCheck139
    LOAD NextY
    SUB Body139Y
    JZERO SnakeLose
    EndBodyCheck139:
    LOAD NextX
    SUB Body140X
    JNEG EndBodyCheck140
    JPOS EndBodyCheck140
    LOAD NextY
    SUB Body140Y
    JZERO SnakeLose
    EndBodyCheck140:
    LOAD NextX
    SUB Body141X
    JNEG EndBodyCheck141
    JPOS EndBodyCheck141
    LOAD NextY
    SUB Body141Y
    JZERO SnakeLose
    EndBodyCheck141:
    LOAD NextX
    SUB Body142X
    JNEG EndBodyCheck142
    JPOS EndBodyCheck142
    LOAD NextY
    SUB Body142Y
    JZERO SnakeLose
    EndBodyCheck142:
    LOAD NextX
    SUB Body143X
    JNEG EndBodyCheck143
    JPOS EndBodyCheck143
    LOAD NextY
    SUB Body143Y
    JZERO SnakeLose
    EndBodyCheck143:
    LOAD NextX
    SUB Body144X
    JNEG EndBodyCheck144
    JPOS EndBodyCheck144
    LOAD NextY
    SUB Body144Y
    JZERO SnakeLose
    EndBodyCheck144:
    LOAD NextX
    SUB Body145X
    JNEG EndBodyCheck145
    JPOS EndBodyCheck145
    LOAD NextY
    SUB Body145Y
    JZERO SnakeLose
    EndBodyCheck145:
    LOAD NextX
    SUB Body146X
    JNEG EndBodyCheck146
    JPOS EndBodyCheck146
    LOAD NextY
    SUB Body146Y
    JZERO SnakeLose
    EndBodyCheck146:
    LOAD NextX
    SUB Body147X
    JNEG EndBodyCheck147
    JPOS EndBodyCheck147
    LOAD NextY
    SUB Body147Y
    JZERO SnakeLose
    EndBodyCheck147:
    LOAD NextX
    SUB Body148X
    JNEG EndBodyCheck148
    JPOS EndBodyCheck148
    LOAD NextY
    SUB Body148Y
    JZERO SnakeLose
    EndBodyCheck148:
    LOAD NextX
    SUB Body149X
    JNEG EndBodyCheck149
    JPOS EndBodyCheck149
    LOAD NextY
    SUB Body149Y
    JZERO SnakeLose
    EndBodyCheck149:
    LOAD NextX
    SUB Body150X
    JNEG EndBodyCheck150
    JPOS EndBodyCheck150
    LOAD NextY
    SUB Body150Y
    JZERO SnakeLose
    EndBodyCheck150:
    LOAD NextX
    SUB Body151X
    JNEG EndBodyCheck151
    JPOS EndBodyCheck151
    LOAD NextY
    SUB Body151Y
    JZERO SnakeLose
    EndBodyCheck151:
    LOAD NextX
    SUB Body152X
    JNEG EndBodyCheck152
    JPOS EndBodyCheck152
    LOAD NextY
    SUB Body152Y
    JZERO SnakeLose
    EndBodyCheck152:
    LOAD NextX
    SUB Body153X
    JNEG EndBodyCheck153
    JPOS EndBodyCheck153
    LOAD NextY
    SUB Body153Y
    JZERO SnakeLose
    EndBodyCheck153:
    LOAD NextX
    SUB Body154X
    JNEG EndBodyCheck154
    JPOS EndBodyCheck154
    LOAD NextY
    SUB Body154Y
    JZERO SnakeLose
    EndBodyCheck154:
    LOAD NextX
    SUB Body155X
    JNEG EndBodyCheck155
    JPOS EndBodyCheck155
    LOAD NextY
    SUB Body155Y
    JZERO SnakeLose
    EndBodyCheck155:
    LOAD NextX
    SUB Body156X
    JNEG EndBodyCheck156
    JPOS EndBodyCheck156
    LOAD NextY
    SUB Body156Y
    JZERO SnakeLose
    EndBodyCheck156:
    LOAD NextX
    SUB Body157X
    JNEG EndBodyCheck157
    JPOS EndBodyCheck157
    LOAD NextY
    SUB Body157Y
    JZERO SnakeLose
    EndBodyCheck157:
    LOAD NextX
    SUB Body158X
    JNEG EndBodyCheck158
    JPOS EndBodyCheck158
    LOAD NextY
    SUB Body158Y
    JZERO SnakeLose
    EndBodyCheck158:
    LOAD NextX
    SUB Body159X
    JNEG EndBodyCheck159
    JPOS EndBodyCheck159
    LOAD NextY
    SUB Body159Y
    JZERO SnakeLose
    EndBodyCheck159:
    LOAD NextX
    SUB Body160X
    JNEG EndBodyCheck160
    JPOS EndBodyCheck160
    LOAD NextY
    SUB Body160Y
    JZERO SnakeLose
    EndBodyCheck160:
    LOAD NextX
    SUB Body161X
    JNEG EndBodyCheck161
    JPOS EndBodyCheck161
    LOAD NextY
    SUB Body161Y
    JZERO SnakeLose
    EndBodyCheck161:
    LOAD NextX
    SUB Body162X
    JNEG EndBodyCheck162
    JPOS EndBodyCheck162
    LOAD NextY
    SUB Body162Y
    JZERO SnakeLose
    EndBodyCheck162:
    LOAD NextX
    SUB Body163X
    JNEG EndBodyCheck163
    JPOS EndBodyCheck163
    LOAD NextY
    SUB Body163Y
    JZERO SnakeLose
    EndBodyCheck163:
    LOAD NextX
    SUB Body164X
    JNEG EndBodyCheck164
    JPOS EndBodyCheck164
    LOAD NextY
    SUB Body164Y
    JZERO SnakeLose
    EndBodyCheck164:
    LOAD NextX
    SUB Body165X
    JNEG EndBodyCheck165
    JPOS EndBodyCheck165
    LOAD NextY
    SUB Body165Y
    JZERO SnakeLose
    EndBodyCheck165:
    LOAD NextX
    SUB Body166X
    JNEG EndBodyCheck166
    JPOS EndBodyCheck166
    LOAD NextY
    SUB Body166Y
    JZERO SnakeLose
    EndBodyCheck166:
    LOAD NextX
    SUB Body167X
    JNEG EndBodyCheck167
    JPOS EndBodyCheck167
    LOAD NextY
    SUB Body167Y
    JZERO SnakeLose
    EndBodyCheck167:
    LOAD NextX
    SUB Body168X
    JNEG EndBodyCheck168
    JPOS EndBodyCheck168
    LOAD NextY
    SUB Body168Y
    JZERO SnakeLose
    EndBodyCheck168:
    LOAD NextX
    SUB Body169X
    JNEG EndBodyCheck169
    JPOS EndBodyCheck169
    LOAD NextY
    SUB Body169Y
    JZERO SnakeLose
    EndBodyCheck169:
    LOAD NextX
    SUB Body170X
    JNEG EndBodyCheck170
    JPOS EndBodyCheck170
    LOAD NextY
    SUB Body170Y
    JZERO SnakeLose
    EndBodyCheck170:
    LOAD NextX
    SUB Body171X
    JNEG EndBodyCheck171
    JPOS EndBodyCheck171
    LOAD NextY
    SUB Body171Y
    JZERO SnakeLose
    EndBodyCheck171:
    LOAD NextX
    SUB Body172X
    JNEG EndBodyCheck172
    JPOS EndBodyCheck172
    LOAD NextY
    SUB Body172Y
    JZERO SnakeLose
    EndBodyCheck172:
    LOAD NextX
    SUB Body173X
    JNEG EndBodyCheck173
    JPOS EndBodyCheck173
    LOAD NextY
    SUB Body173Y
    JZERO SnakeLose
    EndBodyCheck173:
    LOAD NextX
    SUB Body174X
    JNEG EndBodyCheck174
    JPOS EndBodyCheck174
    LOAD NextY
    SUB Body174Y
    JZERO SnakeLose
    EndBodyCheck174:
    LOAD NextX
    SUB Body175X
    JNEG EndBodyCheck175
    JPOS EndBodyCheck175
    LOAD NextY
    SUB Body175Y
    JZERO SnakeLose
    EndBodyCheck175:
    LOAD NextX
    SUB Body176X
    JNEG EndBodyCheck176
    JPOS EndBodyCheck176
    LOAD NextY
    SUB Body176Y
    JZERO SnakeLose
    EndBodyCheck176:
    LOAD NextX
    SUB Body177X
    JNEG EndBodyCheck177
    JPOS EndBodyCheck177
    LOAD NextY
    SUB Body177Y
    JZERO SnakeLose
    EndBodyCheck177:
    LOAD NextX
    SUB Body178X
    JNEG EndBodyCheck178
    JPOS EndBodyCheck178
    LOAD NextY
    SUB Body178Y
    JZERO SnakeLose
    EndBodyCheck178:
    LOAD NextX
    SUB Body179X
    JNEG EndBodyCheck179
    JPOS EndBodyCheck179
    LOAD NextY
    SUB Body179Y
    JZERO SnakeLose
    EndBodyCheck179:
    LOAD NextX
    SUB Body180X
    JNEG EndBodyCheck180
    JPOS EndBodyCheck180
    LOAD NextY
    SUB Body180Y
    JZERO SnakeLose
    EndBodyCheck180:
    LOAD NextX
    SUB Body181X
    JNEG EndBodyCheck181
    JPOS EndBodyCheck181
    LOAD NextY
    SUB Body181Y
    JZERO SnakeLose
    EndBodyCheck181:
    LOAD NextX
    SUB Body182X
    JNEG EndBodyCheck182
    JPOS EndBodyCheck182
    LOAD NextY
    SUB Body182Y
    JZERO SnakeLose
    EndBodyCheck182:
    LOAD NextX
    SUB Body183X
    JNEG EndBodyCheck183
    JPOS EndBodyCheck183
    LOAD NextY
    SUB Body183Y
    JZERO SnakeLose
    EndBodyCheck183:
    LOAD NextX
    SUB Body184X
    JNEG EndBodyCheck184
    JPOS EndBodyCheck184
    LOAD NextY
    SUB Body184Y
    JZERO SnakeLose
    EndBodyCheck184:
    LOAD NextX
    SUB Body185X
    JNEG EndBodyCheck185
    JPOS EndBodyCheck185
    LOAD NextY
    SUB Body185Y
    JZERO SnakeLose
    EndBodyCheck185:
    LOAD NextX
    SUB Body186X
    JNEG EndBodyCheck186
    JPOS EndBodyCheck186
    LOAD NextY
    SUB Body186Y
    JZERO SnakeLose
    EndBodyCheck186:
    LOAD NextX
    SUB Body187X
    JNEG EndBodyCheck187
    JPOS EndBodyCheck187
    LOAD NextY
    SUB Body187Y
    JZERO SnakeLose
    EndBodyCheck187:
    LOAD NextX
    SUB Body188X
    JNEG EndBodyCheck188
    JPOS EndBodyCheck188
    LOAD NextY
    SUB Body188Y
    JZERO SnakeLose
    EndBodyCheck188:
    LOAD NextX
    SUB Body189X
    JNEG EndBodyCheck189
    JPOS EndBodyCheck189
    LOAD NextY
    SUB Body189Y
    JZERO SnakeLose
    EndBodyCheck189:
    LOAD NextX
    SUB Body190X
    JNEG EndBodyCheck190
    JPOS EndBodyCheck190
    LOAD NextY
    SUB Body190Y
    JZERO SnakeLose
    EndBodyCheck190:
    LOAD NextX
    SUB Body191X
    JNEG EndBodyCheck191
    JPOS EndBodyCheck191
    LOAD NextY
    SUB Body191Y
    JZERO SnakeLose
    EndBodyCheck191:
    LOAD EatingApple
    JPOS BodyCheck192 ; if eating apple, check last body part
    JUMP EndBodyCheck192
    BodyCheck192:
    LOAD NextX
    SUB Body192X
    JNEG EndBodyCheck192
    JPOS EndBodyCheck192
    LOAD NextY
    SUB Body192Y
    JNEG EndBodyCheck192
    JPOS EndBodyCheck192
    JUMP SnakeLose
    EndBodyCheck192:

	; Now we must shift all body parts back and add our new node to the front
	; must shift back from back to front
	; CODE GEN 2
    LOAD Body191X
    STORE Body192X
    LOAD Body191Y
    STORE Body192Y
    LOAD Body190X
    STORE Body191X
    LOAD Body190Y
    STORE Body191Y
    LOAD Body189X
    STORE Body190X
    LOAD Body189Y
    STORE Body190Y
    LOAD Body188X
    STORE Body189X
    LOAD Body188Y
    STORE Body189Y
    LOAD Body187X
    STORE Body188X
    LOAD Body187Y
    STORE Body188Y
    LOAD Body186X
    STORE Body187X
    LOAD Body186Y
    STORE Body187Y
    LOAD Body185X
    STORE Body186X
    LOAD Body185Y
    STORE Body186Y
    LOAD Body184X
    STORE Body185X
    LOAD Body184Y
    STORE Body185Y
    LOAD Body183X
    STORE Body184X
    LOAD Body183Y
    STORE Body184Y
    LOAD Body182X
    STORE Body183X
    LOAD Body182Y
    STORE Body183Y
    LOAD Body181X
    STORE Body182X
    LOAD Body181Y
    STORE Body182Y
    LOAD Body180X
    STORE Body181X
    LOAD Body180Y
    STORE Body181Y
    LOAD Body179X
    STORE Body180X
    LOAD Body179Y
    STORE Body180Y
    LOAD Body178X
    STORE Body179X
    LOAD Body178Y
    STORE Body179Y
    LOAD Body177X
    STORE Body178X
    LOAD Body177Y
    STORE Body178Y
    LOAD Body176X
    STORE Body177X
    LOAD Body176Y
    STORE Body177Y
    LOAD Body175X
    STORE Body176X
    LOAD Body175Y
    STORE Body176Y
    LOAD Body174X
    STORE Body175X
    LOAD Body174Y
    STORE Body175Y
    LOAD Body173X
    STORE Body174X
    LOAD Body173Y
    STORE Body174Y
    LOAD Body172X
    STORE Body173X
    LOAD Body172Y
    STORE Body173Y
    LOAD Body171X
    STORE Body172X
    LOAD Body171Y
    STORE Body172Y
    LOAD Body170X
    STORE Body171X
    LOAD Body170Y
    STORE Body171Y
    LOAD Body169X
    STORE Body170X
    LOAD Body169Y
    STORE Body170Y
    LOAD Body168X
    STORE Body169X
    LOAD Body168Y
    STORE Body169Y
    LOAD Body167X
    STORE Body168X
    LOAD Body167Y
    STORE Body168Y
    LOAD Body166X
    STORE Body167X
    LOAD Body166Y
    STORE Body167Y
    LOAD Body165X
    STORE Body166X
    LOAD Body165Y
    STORE Body166Y
    LOAD Body164X
    STORE Body165X
    LOAD Body164Y
    STORE Body165Y
    LOAD Body163X
    STORE Body164X
    LOAD Body163Y
    STORE Body164Y
    LOAD Body162X
    STORE Body163X
    LOAD Body162Y
    STORE Body163Y
    LOAD Body161X
    STORE Body162X
    LOAD Body161Y
    STORE Body162Y
    LOAD Body160X
    STORE Body161X
    LOAD Body160Y
    STORE Body161Y
    LOAD Body159X
    STORE Body160X
    LOAD Body159Y
    STORE Body160Y
    LOAD Body158X
    STORE Body159X
    LOAD Body158Y
    STORE Body159Y
    LOAD Body157X
    STORE Body158X
    LOAD Body157Y
    STORE Body158Y
    LOAD Body156X
    STORE Body157X
    LOAD Body156Y
    STORE Body157Y
    LOAD Body155X
    STORE Body156X
    LOAD Body155Y
    STORE Body156Y
    LOAD Body154X
    STORE Body155X
    LOAD Body154Y
    STORE Body155Y
    LOAD Body153X
    STORE Body154X
    LOAD Body153Y
    STORE Body154Y
    LOAD Body152X
    STORE Body153X
    LOAD Body152Y
    STORE Body153Y
    LOAD Body151X
    STORE Body152X
    LOAD Body151Y
    STORE Body152Y
    LOAD Body150X
    STORE Body151X
    LOAD Body150Y
    STORE Body151Y
    LOAD Body149X
    STORE Body150X
    LOAD Body149Y
    STORE Body150Y
    LOAD Body148X
    STORE Body149X
    LOAD Body148Y
    STORE Body149Y
    LOAD Body147X
    STORE Body148X
    LOAD Body147Y
    STORE Body148Y
    LOAD Body146X
    STORE Body147X
    LOAD Body146Y
    STORE Body147Y
    LOAD Body145X
    STORE Body146X
    LOAD Body145Y
    STORE Body146Y
    LOAD Body144X
    STORE Body145X
    LOAD Body144Y
    STORE Body145Y
    LOAD Body143X
    STORE Body144X
    LOAD Body143Y
    STORE Body144Y
    LOAD Body142X
    STORE Body143X
    LOAD Body142Y
    STORE Body143Y
    LOAD Body141X
    STORE Body142X
    LOAD Body141Y
    STORE Body142Y
    LOAD Body140X
    STORE Body141X
    LOAD Body140Y
    STORE Body141Y
    LOAD Body139X
    STORE Body140X
    LOAD Body139Y
    STORE Body140Y
    LOAD Body138X
    STORE Body139X
    LOAD Body138Y
    STORE Body139Y
    LOAD Body137X
    STORE Body138X
    LOAD Body137Y
    STORE Body138Y
    LOAD Body136X
    STORE Body137X
    LOAD Body136Y
    STORE Body137Y
    LOAD Body135X
    STORE Body136X
    LOAD Body135Y
    STORE Body136Y
    LOAD Body134X
    STORE Body135X
    LOAD Body134Y
    STORE Body135Y
    LOAD Body133X
    STORE Body134X
    LOAD Body133Y
    STORE Body134Y
    LOAD Body132X
    STORE Body133X
    LOAD Body132Y
    STORE Body133Y
    LOAD Body131X
    STORE Body132X
    LOAD Body131Y
    STORE Body132Y
    LOAD Body130X
    STORE Body131X
    LOAD Body130Y
    STORE Body131Y
    LOAD Body129X
    STORE Body130X
    LOAD Body129Y
    STORE Body130Y
    LOAD Body128X
    STORE Body129X
    LOAD Body128Y
    STORE Body129Y
    LOAD Body127X
    STORE Body128X
    LOAD Body127Y
    STORE Body128Y
    LOAD Body126X
    STORE Body127X
    LOAD Body126Y
    STORE Body127Y
    LOAD Body125X
    STORE Body126X
    LOAD Body125Y
    STORE Body126Y
    LOAD Body124X
    STORE Body125X
    LOAD Body124Y
    STORE Body125Y
    LOAD Body123X
    STORE Body124X
    LOAD Body123Y
    STORE Body124Y
    LOAD Body122X
    STORE Body123X
    LOAD Body122Y
    STORE Body123Y
    LOAD Body121X
    STORE Body122X
    LOAD Body121Y
    STORE Body122Y
    LOAD Body120X
    STORE Body121X
    LOAD Body120Y
    STORE Body121Y
    LOAD Body119X
    STORE Body120X
    LOAD Body119Y
    STORE Body120Y
    LOAD Body118X
    STORE Body119X
    LOAD Body118Y
    STORE Body119Y
    LOAD Body117X
    STORE Body118X
    LOAD Body117Y
    STORE Body118Y
    LOAD Body116X
    STORE Body117X
    LOAD Body116Y
    STORE Body117Y
    LOAD Body115X
    STORE Body116X
    LOAD Body115Y
    STORE Body116Y
    LOAD Body114X
    STORE Body115X
    LOAD Body114Y
    STORE Body115Y
    LOAD Body113X
    STORE Body114X
    LOAD Body113Y
    STORE Body114Y
    LOAD Body112X
    STORE Body113X
    LOAD Body112Y
    STORE Body113Y
    LOAD Body111X
    STORE Body112X
    LOAD Body111Y
    STORE Body112Y
    LOAD Body110X
    STORE Body111X
    LOAD Body110Y
    STORE Body111Y
    LOAD Body109X
    STORE Body110X
    LOAD Body109Y
    STORE Body110Y
    LOAD Body108X
    STORE Body109X
    LOAD Body108Y
    STORE Body109Y
    LOAD Body107X
    STORE Body108X
    LOAD Body107Y
    STORE Body108Y
    LOAD Body106X
    STORE Body107X
    LOAD Body106Y
    STORE Body107Y
    LOAD Body105X
    STORE Body106X
    LOAD Body105Y
    STORE Body106Y
    LOAD Body104X
    STORE Body105X
    LOAD Body104Y
    STORE Body105Y
    LOAD Body103X
    STORE Body104X
    LOAD Body103Y
    STORE Body104Y
    LOAD Body102X
    STORE Body103X
    LOAD Body102Y
    STORE Body103Y
    LOAD Body101X
    STORE Body102X
    LOAD Body101Y
    STORE Body102Y
    LOAD Body100X
    STORE Body101X
    LOAD Body100Y
    STORE Body101Y
    LOAD Body99X
    STORE Body100X
    LOAD Body99Y
    STORE Body100Y
    LOAD Body98X
    STORE Body99X
    LOAD Body98Y
    STORE Body99Y
    LOAD Body97X
    STORE Body98X
    LOAD Body97Y
    STORE Body98Y
    LOAD Body96X
    STORE Body97X
    LOAD Body96Y
    STORE Body97Y
    LOAD Body95X
    STORE Body96X
    LOAD Body95Y
    STORE Body96Y
    LOAD Body94X
    STORE Body95X
    LOAD Body94Y
    STORE Body95Y
    LOAD Body93X
    STORE Body94X
    LOAD Body93Y
    STORE Body94Y
    LOAD Body92X
    STORE Body93X
    LOAD Body92Y
    STORE Body93Y
    LOAD Body91X
    STORE Body92X
    LOAD Body91Y
    STORE Body92Y
    LOAD Body90X
    STORE Body91X
    LOAD Body90Y
    STORE Body91Y
    LOAD Body89X
    STORE Body90X
    LOAD Body89Y
    STORE Body90Y
    LOAD Body88X
    STORE Body89X
    LOAD Body88Y
    STORE Body89Y
    LOAD Body87X
    STORE Body88X
    LOAD Body87Y
    STORE Body88Y
    LOAD Body86X
    STORE Body87X
    LOAD Body86Y
    STORE Body87Y
    LOAD Body85X
    STORE Body86X
    LOAD Body85Y
    STORE Body86Y
    LOAD Body84X
    STORE Body85X
    LOAD Body84Y
    STORE Body85Y
    LOAD Body83X
    STORE Body84X
    LOAD Body83Y
    STORE Body84Y
    LOAD Body82X
    STORE Body83X
    LOAD Body82Y
    STORE Body83Y
    LOAD Body81X
    STORE Body82X
    LOAD Body81Y
    STORE Body82Y
    LOAD Body80X
    STORE Body81X
    LOAD Body80Y
    STORE Body81Y
    LOAD Body79X
    STORE Body80X
    LOAD Body79Y
    STORE Body80Y
    LOAD Body78X
    STORE Body79X
    LOAD Body78Y
    STORE Body79Y
    LOAD Body77X
    STORE Body78X
    LOAD Body77Y
    STORE Body78Y
    LOAD Body76X
    STORE Body77X
    LOAD Body76Y
    STORE Body77Y
    LOAD Body75X
    STORE Body76X
    LOAD Body75Y
    STORE Body76Y
    LOAD Body74X
    STORE Body75X
    LOAD Body74Y
    STORE Body75Y
    LOAD Body73X
    STORE Body74X
    LOAD Body73Y
    STORE Body74Y
    LOAD Body72X
    STORE Body73X
    LOAD Body72Y
    STORE Body73Y
    LOAD Body71X
    STORE Body72X
    LOAD Body71Y
    STORE Body72Y
    LOAD Body70X
    STORE Body71X
    LOAD Body70Y
    STORE Body71Y
    LOAD Body69X
    STORE Body70X
    LOAD Body69Y
    STORE Body70Y
    LOAD Body68X
    STORE Body69X
    LOAD Body68Y
    STORE Body69Y
    LOAD Body67X
    STORE Body68X
    LOAD Body67Y
    STORE Body68Y
    LOAD Body66X
    STORE Body67X
    LOAD Body66Y
    STORE Body67Y
    LOAD Body65X
    STORE Body66X
    LOAD Body65Y
    STORE Body66Y
    LOAD Body64X
    STORE Body65X
    LOAD Body64Y
    STORE Body65Y
    LOAD Body63X
    STORE Body64X
    LOAD Body63Y
    STORE Body64Y
    LOAD Body62X
    STORE Body63X
    LOAD Body62Y
    STORE Body63Y
    LOAD Body61X
    STORE Body62X
    LOAD Body61Y
    STORE Body62Y
    LOAD Body60X
    STORE Body61X
    LOAD Body60Y
    STORE Body61Y
    LOAD Body59X
    STORE Body60X
    LOAD Body59Y
    STORE Body60Y
    LOAD Body58X
    STORE Body59X
    LOAD Body58Y
    STORE Body59Y
    LOAD Body57X
    STORE Body58X
    LOAD Body57Y
    STORE Body58Y
    LOAD Body56X
    STORE Body57X
    LOAD Body56Y
    STORE Body57Y
    LOAD Body55X
    STORE Body56X
    LOAD Body55Y
    STORE Body56Y
    LOAD Body54X
    STORE Body55X
    LOAD Body54Y
    STORE Body55Y
    LOAD Body53X
    STORE Body54X
    LOAD Body53Y
    STORE Body54Y
    LOAD Body52X
    STORE Body53X
    LOAD Body52Y
    STORE Body53Y
    LOAD Body51X
    STORE Body52X
    LOAD Body51Y
    STORE Body52Y
    LOAD Body50X
    STORE Body51X
    LOAD Body50Y
    STORE Body51Y
    LOAD Body49X
    STORE Body50X
    LOAD Body49Y
    STORE Body50Y
    LOAD Body48X
    STORE Body49X
    LOAD Body48Y
    STORE Body49Y
    LOAD Body47X
    STORE Body48X
    LOAD Body47Y
    STORE Body48Y
    LOAD Body46X
    STORE Body47X
    LOAD Body46Y
    STORE Body47Y
    LOAD Body45X
    STORE Body46X
    LOAD Body45Y
    STORE Body46Y
    LOAD Body44X
    STORE Body45X
    LOAD Body44Y
    STORE Body45Y
    LOAD Body43X
    STORE Body44X
    LOAD Body43Y
    STORE Body44Y
    LOAD Body42X
    STORE Body43X
    LOAD Body42Y
    STORE Body43Y
    LOAD Body41X
    STORE Body42X
    LOAD Body41Y
    STORE Body42Y
    LOAD Body40X
    STORE Body41X
    LOAD Body40Y
    STORE Body41Y
    LOAD Body39X
    STORE Body40X
    LOAD Body39Y
    STORE Body40Y
    LOAD Body38X
    STORE Body39X
    LOAD Body38Y
    STORE Body39Y
    LOAD Body37X
    STORE Body38X
    LOAD Body37Y
    STORE Body38Y
    LOAD Body36X
    STORE Body37X
    LOAD Body36Y
    STORE Body37Y
    LOAD Body35X
    STORE Body36X
    LOAD Body35Y
    STORE Body36Y
    LOAD Body34X
    STORE Body35X
    LOAD Body34Y
    STORE Body35Y
    LOAD Body33X
    STORE Body34X
    LOAD Body33Y
    STORE Body34Y
    LOAD Body32X
    STORE Body33X
    LOAD Body32Y
    STORE Body33Y
    LOAD Body31X
    STORE Body32X
    LOAD Body31Y
    STORE Body32Y
    LOAD Body30X
    STORE Body31X
    LOAD Body30Y
    STORE Body31Y
    LOAD Body29X
    STORE Body30X
    LOAD Body29Y
    STORE Body30Y
    LOAD Body28X
    STORE Body29X
    LOAD Body28Y
    STORE Body29Y
    LOAD Body27X
    STORE Body28X
    LOAD Body27Y
    STORE Body28Y
    LOAD Body26X
    STORE Body27X
    LOAD Body26Y
    STORE Body27Y
    LOAD Body25X
    STORE Body26X
    LOAD Body25Y
    STORE Body26Y
    LOAD Body24X
    STORE Body25X
    LOAD Body24Y
    STORE Body25Y
    LOAD Body23X
    STORE Body24X
    LOAD Body23Y
    STORE Body24Y
    LOAD Body22X
    STORE Body23X
    LOAD Body22Y
    STORE Body23Y
    LOAD Body21X
    STORE Body22X
    LOAD Body21Y
    STORE Body22Y
    LOAD Body20X
    STORE Body21X
    LOAD Body20Y
    STORE Body21Y
    LOAD Body19X
    STORE Body20X
    LOAD Body19Y
    STORE Body20Y
    LOAD Body18X
    STORE Body19X
    LOAD Body18Y
    STORE Body19Y
    LOAD Body17X
    STORE Body18X
    LOAD Body17Y
    STORE Body18Y
    LOAD Body16X
    STORE Body17X
    LOAD Body16Y
    STORE Body17Y
    LOAD Body15X
    STORE Body16X
    LOAD Body15Y
    STORE Body16Y
    LOAD Body14X
    STORE Body15X
    LOAD Body14Y
    STORE Body15Y
    LOAD Body13X
    STORE Body14X
    LOAD Body13Y
    STORE Body14Y
    LOAD Body12X
    STORE Body13X
    LOAD Body12Y
    STORE Body13Y
    LOAD Body11X
    STORE Body12X
    LOAD Body11Y
    STORE Body12Y
    LOAD Body10X
    STORE Body11X
    LOAD Body10Y
    STORE Body11Y
    LOAD Body9X
    STORE Body10X
    LOAD Body9Y
    STORE Body10Y
    LOAD Body8X
    STORE Body9X
    LOAD Body8Y
    STORE Body9Y
    LOAD Body7X
    STORE Body8X
    LOAD Body7Y
    STORE Body8Y
    LOAD Body6X
    STORE Body7X
    LOAD Body6Y
    STORE Body7Y
    LOAD Body5X
    STORE Body6X
    LOAD Body5Y
    STORE Body6Y
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

	; CODE GEN 3
	EraseTail: ; only erase tail if we didnt eat an apple!
    ; erase tail - tail will be the (CurBodySize + 1)th body
    LOAD CurBodySize
    ADDI -1
    JZERO EraseBody2
    ADDI -1
    JZERO EraseBody3
    ADDI -1
    JZERO EraseBody4
    ADDI -1
    JZERO EraseBody5
    ADDI -1
    JZERO EraseBody6
    ADDI -1
    JZERO EraseBody7
    ADDI -1
    JZERO EraseBody8
    ADDI -1
    JZERO EraseBody9
    ADDI -1
    JZERO EraseBody10
    ADDI -1
    JZERO EraseBody11
    ADDI -1
    JZERO EraseBody12
    ADDI -1
    JZERO EraseBody13
    ADDI -1
    JZERO EraseBody14
    ADDI -1
    JZERO EraseBody15
    ADDI -1
    JZERO EraseBody16
    ADDI -1
    JZERO EraseBody17
    ADDI -1
    JZERO EraseBody18
    ADDI -1
    JZERO EraseBody19
    ADDI -1
    JZERO EraseBody20
    ADDI -1
    JZERO EraseBody21
    ADDI -1
    JZERO EraseBody22
    ADDI -1
    JZERO EraseBody23
    ADDI -1
    JZERO EraseBody24
    ADDI -1
    JZERO EraseBody25
    ADDI -1
    JZERO EraseBody26
    ADDI -1
    JZERO EraseBody27
    ADDI -1
    JZERO EraseBody28
    ADDI -1
    JZERO EraseBody29
    ADDI -1
    JZERO EraseBody30
    ADDI -1
    JZERO EraseBody31
    ADDI -1
    JZERO EraseBody32
    ADDI -1
    JZERO EraseBody33
    ADDI -1
    JZERO EraseBody34
    ADDI -1
    JZERO EraseBody35
    ADDI -1
    JZERO EraseBody36
    ADDI -1
    JZERO EraseBody37
    ADDI -1
    JZERO EraseBody38
    ADDI -1
    JZERO EraseBody39
    ADDI -1
    JZERO EraseBody40
    ADDI -1
    JZERO EraseBody41
    ADDI -1
    JZERO EraseBody42
    ADDI -1
    JZERO EraseBody43
    ADDI -1
    JZERO EraseBody44
    ADDI -1
    JZERO EraseBody45
    ADDI -1
    JZERO EraseBody46
    ADDI -1
    JZERO EraseBody47
    ADDI -1
    JZERO EraseBody48
    ADDI -1
    JZERO EraseBody49
    ADDI -1
    JZERO EraseBody50
    ADDI -1
    JZERO EraseBody51
    ADDI -1
    JZERO EraseBody52
    ADDI -1
    JZERO EraseBody53
    ADDI -1
    JZERO EraseBody54
    ADDI -1
    JZERO EraseBody55
    ADDI -1
    JZERO EraseBody56
    ADDI -1
    JZERO EraseBody57
    ADDI -1
    JZERO EraseBody58
    ADDI -1
    JZERO EraseBody59
    ADDI -1
    JZERO EraseBody60
    ADDI -1
    JZERO EraseBody61
    ADDI -1
    JZERO EraseBody62
    ADDI -1
    JZERO EraseBody63
    ADDI -1
    JZERO EraseBody64
    ADDI -1
    JZERO EraseBody65
    ADDI -1
    JZERO EraseBody66
    ADDI -1
    JZERO EraseBody67
    ADDI -1
    JZERO EraseBody68
    ADDI -1
    JZERO EraseBody69
    ADDI -1
    JZERO EraseBody70
    ADDI -1
    JZERO EraseBody71
    ADDI -1
    JZERO EraseBody72
    ADDI -1
    JZERO EraseBody73
    ADDI -1
    JZERO EraseBody74
    ADDI -1
    JZERO EraseBody75
    ADDI -1
    JZERO EraseBody76
    ADDI -1
    JZERO EraseBody77
    ADDI -1
    JZERO EraseBody78
    ADDI -1
    JZERO EraseBody79
    ADDI -1
    JZERO EraseBody80
    ADDI -1
    JZERO EraseBody81
    ADDI -1
    JZERO EraseBody82
    ADDI -1
    JZERO EraseBody83
    ADDI -1
    JZERO EraseBody84
    ADDI -1
    JZERO EraseBody85
    ADDI -1
    JZERO EraseBody86
    ADDI -1
    JZERO EraseBody87
    ADDI -1
    JZERO EraseBody88
    ADDI -1
    JZERO EraseBody89
    ADDI -1
    JZERO EraseBody90
    ADDI -1
    JZERO EraseBody91
    ADDI -1
    JZERO EraseBody92
    ADDI -1
    JZERO EraseBody93
    ADDI -1
    JZERO EraseBody94
    ADDI -1
    JZERO EraseBody95
    ADDI -1
    JZERO EraseBody96
    ADDI -1
    JZERO EraseBody97
    ADDI -1
    JZERO EraseBody98
    ADDI -1
    JZERO EraseBody99
    ADDI -1
    JZERO EraseBody100
    ADDI -1
    JZERO EraseBody101
    ADDI -1
    JZERO EraseBody102
    ADDI -1
    JZERO EraseBody103
    ADDI -1
    JZERO EraseBody104
    ADDI -1
    JZERO EraseBody105
    ADDI -1
    JZERO EraseBody106
    ADDI -1
    JZERO EraseBody107
    ADDI -1
    JZERO EraseBody108
    ADDI -1
    JZERO EraseBody109
    ADDI -1
    JZERO EraseBody110
    ADDI -1
    JZERO EraseBody111
    ADDI -1
    JZERO EraseBody112
    ADDI -1
    JZERO EraseBody113
    ADDI -1
    JZERO EraseBody114
    ADDI -1
    JZERO EraseBody115
    ADDI -1
    JZERO EraseBody116
    ADDI -1
    JZERO EraseBody117
    ADDI -1
    JZERO EraseBody118
    ADDI -1
    JZERO EraseBody119
    ADDI -1
    JZERO EraseBody120
    ADDI -1
    JZERO EraseBody121
    ADDI -1
    JZERO EraseBody122
    ADDI -1
    JZERO EraseBody123
    ADDI -1
    JZERO EraseBody124
    ADDI -1
    JZERO EraseBody125
    ADDI -1
    JZERO EraseBody126
    ADDI -1
    JZERO EraseBody127
    ADDI -1
    JZERO EraseBody128
    ADDI -1
    JZERO EraseBody129
    ADDI -1
    JZERO EraseBody130
    ADDI -1
    JZERO EraseBody131
    ADDI -1
    JZERO EraseBody132
    ADDI -1
    JZERO EraseBody133
    ADDI -1
    JZERO EraseBody134
    ADDI -1
    JZERO EraseBody135
    ADDI -1
    JZERO EraseBody136
    ADDI -1
    JZERO EraseBody137
    ADDI -1
    JZERO EraseBody138
    ADDI -1
    JZERO EraseBody139
    ADDI -1
    JZERO EraseBody140
    ADDI -1
    JZERO EraseBody141
    ADDI -1
    JZERO EraseBody142
    ADDI -1
    JZERO EraseBody143
    ADDI -1
    JZERO EraseBody144
    ADDI -1
    JZERO EraseBody145
    ADDI -1
    JZERO EraseBody146
    ADDI -1
    JZERO EraseBody147
    ADDI -1
    JZERO EraseBody148
    ADDI -1
    JZERO EraseBody149
    ADDI -1
    JZERO EraseBody150
    ADDI -1
    JZERO EraseBody151
    ADDI -1
    JZERO EraseBody152
    ADDI -1
    JZERO EraseBody153
    ADDI -1
    JZERO EraseBody154
    ADDI -1
    JZERO EraseBody155
    ADDI -1
    JZERO EraseBody156
    ADDI -1
    JZERO EraseBody157
    ADDI -1
    JZERO EraseBody158
    ADDI -1
    JZERO EraseBody159
    ADDI -1
    JZERO EraseBody160
    ADDI -1
    JZERO EraseBody161
    ADDI -1
    JZERO EraseBody162
    ADDI -1
    JZERO EraseBody163
    ADDI -1
    JZERO EraseBody164
    ADDI -1
    JZERO EraseBody165
    ADDI -1
    JZERO EraseBody166
    ADDI -1
    JZERO EraseBody167
    ADDI -1
    JZERO EraseBody168
    ADDI -1
    JZERO EraseBody169
    ADDI -1
    JZERO EraseBody170
    ADDI -1
    JZERO EraseBody171
    ADDI -1
    JZERO EraseBody172
    ADDI -1
    JZERO EraseBody173
    ADDI -1
    JZERO EraseBody174
    ADDI -1
    JZERO EraseBody175
    ADDI -1
    JZERO EraseBody176
    ADDI -1
    JZERO EraseBody177
    ADDI -1
    JZERO EraseBody178
    ADDI -1
    JZERO EraseBody179
    ADDI -1
    JZERO EraseBody180
    ADDI -1
    JZERO EraseBody181
    ADDI -1
    JZERO EraseBody182
    ADDI -1
    JZERO EraseBody183
    ADDI -1
    JZERO EraseBody184
    ADDI -1
    JZERO EraseBody185
    ADDI -1
    JZERO EraseBody186
    ADDI -1
    JZERO EraseBody187
    ADDI -1
    JZERO EraseBody188
    ADDI -1
    JZERO EraseBody189
    ADDI -1
    JZERO EraseBody190
    ADDI -1
    JZERO EraseBody191
    ADDI -1
    JZERO EraseBody192

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
    EraseBody6:
        LOAD Body6X
        STORE   XYToIndexX
        LOAD Body6Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody7:
        LOAD Body7X
        STORE   XYToIndexX
        LOAD Body7Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody8:
        LOAD Body8X
        STORE   XYToIndexX
        LOAD Body8Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody9:
        LOAD Body9X
        STORE   XYToIndexX
        LOAD Body9Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody10:
        LOAD Body10X
        STORE   XYToIndexX
        LOAD Body10Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody11:
        LOAD Body11X
        STORE   XYToIndexX
        LOAD Body11Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody12:
        LOAD Body12X
        STORE   XYToIndexX
        LOAD Body12Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody13:
        LOAD Body13X
        STORE   XYToIndexX
        LOAD Body13Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody14:
        LOAD Body14X
        STORE   XYToIndexX
        LOAD Body14Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody15:
        LOAD Body15X
        STORE   XYToIndexX
        LOAD Body15Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody16:
        LOAD Body16X
        STORE   XYToIndexX
        LOAD Body16Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody17:
        LOAD Body17X
        STORE   XYToIndexX
        LOAD Body17Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody18:
        LOAD Body18X
        STORE   XYToIndexX
        LOAD Body18Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody19:
        LOAD Body19X
        STORE   XYToIndexX
        LOAD Body19Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody20:
        LOAD Body20X
        STORE   XYToIndexX
        LOAD Body20Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody21:
        LOAD Body21X
        STORE   XYToIndexX
        LOAD Body21Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody22:
        LOAD Body22X
        STORE   XYToIndexX
        LOAD Body22Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody23:
        LOAD Body23X
        STORE   XYToIndexX
        LOAD Body23Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody24:
        LOAD Body24X
        STORE   XYToIndexX
        LOAD Body24Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody25:
        LOAD Body25X
        STORE   XYToIndexX
        LOAD Body25Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody26:
        LOAD Body26X
        STORE   XYToIndexX
        LOAD Body26Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody27:
        LOAD Body27X
        STORE   XYToIndexX
        LOAD Body27Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody28:
        LOAD Body28X
        STORE   XYToIndexX
        LOAD Body28Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody29:
        LOAD Body29X
        STORE   XYToIndexX
        LOAD Body29Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody30:
        LOAD Body30X
        STORE   XYToIndexX
        LOAD Body30Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody31:
        LOAD Body31X
        STORE   XYToIndexX
        LOAD Body31Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody32:
        LOAD Body32X
        STORE   XYToIndexX
        LOAD Body32Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody33:
        LOAD Body33X
        STORE   XYToIndexX
        LOAD Body33Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody34:
        LOAD Body34X
        STORE   XYToIndexX
        LOAD Body34Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody35:
        LOAD Body35X
        STORE   XYToIndexX
        LOAD Body35Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody36:
        LOAD Body36X
        STORE   XYToIndexX
        LOAD Body36Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody37:
        LOAD Body37X
        STORE   XYToIndexX
        LOAD Body37Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody38:
        LOAD Body38X
        STORE   XYToIndexX
        LOAD Body38Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody39:
        LOAD Body39X
        STORE   XYToIndexX
        LOAD Body39Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody40:
        LOAD Body40X
        STORE   XYToIndexX
        LOAD Body40Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody41:
        LOAD Body41X
        STORE   XYToIndexX
        LOAD Body41Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody42:
        LOAD Body42X
        STORE   XYToIndexX
        LOAD Body42Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody43:
        LOAD Body43X
        STORE   XYToIndexX
        LOAD Body43Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody44:
        LOAD Body44X
        STORE   XYToIndexX
        LOAD Body44Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody45:
        LOAD Body45X
        STORE   XYToIndexX
        LOAD Body45Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody46:
        LOAD Body46X
        STORE   XYToIndexX
        LOAD Body46Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody47:
        LOAD Body47X
        STORE   XYToIndexX
        LOAD Body47Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody48:
        LOAD Body48X
        STORE   XYToIndexX
        LOAD Body48Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody49:
        LOAD Body49X
        STORE   XYToIndexX
        LOAD Body49Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody50:
        LOAD Body50X
        STORE   XYToIndexX
        LOAD Body50Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody51:
        LOAD Body51X
        STORE   XYToIndexX
        LOAD Body51Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody52:
        LOAD Body52X
        STORE   XYToIndexX
        LOAD Body52Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody53:
        LOAD Body53X
        STORE   XYToIndexX
        LOAD Body53Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody54:
        LOAD Body54X
        STORE   XYToIndexX
        LOAD Body54Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody55:
        LOAD Body55X
        STORE   XYToIndexX
        LOAD Body55Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody56:
        LOAD Body56X
        STORE   XYToIndexX
        LOAD Body56Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody57:
        LOAD Body57X
        STORE   XYToIndexX
        LOAD Body57Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody58:
        LOAD Body58X
        STORE   XYToIndexX
        LOAD Body58Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody59:
        LOAD Body59X
        STORE   XYToIndexX
        LOAD Body59Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody60:
        LOAD Body60X
        STORE   XYToIndexX
        LOAD Body60Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody61:
        LOAD Body61X
        STORE   XYToIndexX
        LOAD Body61Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody62:
        LOAD Body62X
        STORE   XYToIndexX
        LOAD Body62Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody63:
        LOAD Body63X
        STORE   XYToIndexX
        LOAD Body63Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody64:
        LOAD Body64X
        STORE   XYToIndexX
        LOAD Body64Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody65:
        LOAD Body65X
        STORE   XYToIndexX
        LOAD Body65Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody66:
        LOAD Body66X
        STORE   XYToIndexX
        LOAD Body66Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody67:
        LOAD Body67X
        STORE   XYToIndexX
        LOAD Body67Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody68:
        LOAD Body68X
        STORE   XYToIndexX
        LOAD Body68Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody69:
        LOAD Body69X
        STORE   XYToIndexX
        LOAD Body69Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody70:
        LOAD Body70X
        STORE   XYToIndexX
        LOAD Body70Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody71:
        LOAD Body71X
        STORE   XYToIndexX
        LOAD Body71Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody72:
        LOAD Body72X
        STORE   XYToIndexX
        LOAD Body72Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody73:
        LOAD Body73X
        STORE   XYToIndexX
        LOAD Body73Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody74:
        LOAD Body74X
        STORE   XYToIndexX
        LOAD Body74Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody75:
        LOAD Body75X
        STORE   XYToIndexX
        LOAD Body75Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody76:
        LOAD Body76X
        STORE   XYToIndexX
        LOAD Body76Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody77:
        LOAD Body77X
        STORE   XYToIndexX
        LOAD Body77Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody78:
        LOAD Body78X
        STORE   XYToIndexX
        LOAD Body78Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody79:
        LOAD Body79X
        STORE   XYToIndexX
        LOAD Body79Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody80:
        LOAD Body80X
        STORE   XYToIndexX
        LOAD Body80Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody81:
        LOAD Body81X
        STORE   XYToIndexX
        LOAD Body81Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody82:
        LOAD Body82X
        STORE   XYToIndexX
        LOAD Body82Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody83:
        LOAD Body83X
        STORE   XYToIndexX
        LOAD Body83Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody84:
        LOAD Body84X
        STORE   XYToIndexX
        LOAD Body84Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody85:
        LOAD Body85X
        STORE   XYToIndexX
        LOAD Body85Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody86:
        LOAD Body86X
        STORE   XYToIndexX
        LOAD Body86Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody87:
        LOAD Body87X
        STORE   XYToIndexX
        LOAD Body87Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody88:
        LOAD Body88X
        STORE   XYToIndexX
        LOAD Body88Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody89:
        LOAD Body89X
        STORE   XYToIndexX
        LOAD Body89Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody90:
        LOAD Body90X
        STORE   XYToIndexX
        LOAD Body90Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody91:
        LOAD Body91X
        STORE   XYToIndexX
        LOAD Body91Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody92:
        LOAD Body92X
        STORE   XYToIndexX
        LOAD Body92Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody93:
        LOAD Body93X
        STORE   XYToIndexX
        LOAD Body93Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody94:
        LOAD Body94X
        STORE   XYToIndexX
        LOAD Body94Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody95:
        LOAD Body95X
        STORE   XYToIndexX
        LOAD Body95Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody96:
        LOAD Body96X
        STORE   XYToIndexX
        LOAD Body96Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody97:
        LOAD Body97X
        STORE   XYToIndexX
        LOAD Body97Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody98:
        LOAD Body98X
        STORE   XYToIndexX
        LOAD Body98Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody99:
        LOAD Body99X
        STORE   XYToIndexX
        LOAD Body99Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody100:
        LOAD Body100X
        STORE   XYToIndexX
        LOAD Body100Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody101:
        LOAD Body101X
        STORE   XYToIndexX
        LOAD Body101Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody102:
        LOAD Body102X
        STORE   XYToIndexX
        LOAD Body102Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody103:
        LOAD Body103X
        STORE   XYToIndexX
        LOAD Body103Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody104:
        LOAD Body104X
        STORE   XYToIndexX
        LOAD Body104Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody105:
        LOAD Body105X
        STORE   XYToIndexX
        LOAD Body105Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody106:
        LOAD Body106X
        STORE   XYToIndexX
        LOAD Body106Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody107:
        LOAD Body107X
        STORE   XYToIndexX
        LOAD Body107Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody108:
        LOAD Body108X
        STORE   XYToIndexX
        LOAD Body108Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody109:
        LOAD Body109X
        STORE   XYToIndexX
        LOAD Body109Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody110:
        LOAD Body110X
        STORE   XYToIndexX
        LOAD Body110Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody111:
        LOAD Body111X
        STORE   XYToIndexX
        LOAD Body111Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody112:
        LOAD Body112X
        STORE   XYToIndexX
        LOAD Body112Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody113:
        LOAD Body113X
        STORE   XYToIndexX
        LOAD Body113Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody114:
        LOAD Body114X
        STORE   XYToIndexX
        LOAD Body114Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody115:
        LOAD Body115X
        STORE   XYToIndexX
        LOAD Body115Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody116:
        LOAD Body116X
        STORE   XYToIndexX
        LOAD Body116Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody117:
        LOAD Body117X
        STORE   XYToIndexX
        LOAD Body117Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody118:
        LOAD Body118X
        STORE   XYToIndexX
        LOAD Body118Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody119:
        LOAD Body119X
        STORE   XYToIndexX
        LOAD Body119Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody120:
        LOAD Body120X
        STORE   XYToIndexX
        LOAD Body120Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody121:
        LOAD Body121X
        STORE   XYToIndexX
        LOAD Body121Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody122:
        LOAD Body122X
        STORE   XYToIndexX
        LOAD Body122Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody123:
        LOAD Body123X
        STORE   XYToIndexX
        LOAD Body123Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody124:
        LOAD Body124X
        STORE   XYToIndexX
        LOAD Body124Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody125:
        LOAD Body125X
        STORE   XYToIndexX
        LOAD Body125Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody126:
        LOAD Body126X
        STORE   XYToIndexX
        LOAD Body126Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody127:
        LOAD Body127X
        STORE   XYToIndexX
        LOAD Body127Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody128:
        LOAD Body128X
        STORE   XYToIndexX
        LOAD Body128Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody129:
        LOAD Body129X
        STORE   XYToIndexX
        LOAD Body129Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody130:
        LOAD Body130X
        STORE   XYToIndexX
        LOAD Body130Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody131:
        LOAD Body131X
        STORE   XYToIndexX
        LOAD Body131Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody132:
        LOAD Body132X
        STORE   XYToIndexX
        LOAD Body132Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody133:
        LOAD Body133X
        STORE   XYToIndexX
        LOAD Body133Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody134:
        LOAD Body134X
        STORE   XYToIndexX
        LOAD Body134Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody135:
        LOAD Body135X
        STORE   XYToIndexX
        LOAD Body135Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody136:
        LOAD Body136X
        STORE   XYToIndexX
        LOAD Body136Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody137:
        LOAD Body137X
        STORE   XYToIndexX
        LOAD Body137Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody138:
        LOAD Body138X
        STORE   XYToIndexX
        LOAD Body138Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody139:
        LOAD Body139X
        STORE   XYToIndexX
        LOAD Body139Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody140:
        LOAD Body140X
        STORE   XYToIndexX
        LOAD Body140Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody141:
        LOAD Body141X
        STORE   XYToIndexX
        LOAD Body141Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody142:
        LOAD Body142X
        STORE   XYToIndexX
        LOAD Body142Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody143:
        LOAD Body143X
        STORE   XYToIndexX
        LOAD Body143Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody144:
        LOAD Body144X
        STORE   XYToIndexX
        LOAD Body144Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody145:
        LOAD Body145X
        STORE   XYToIndexX
        LOAD Body145Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody146:
        LOAD Body146X
        STORE   XYToIndexX
        LOAD Body146Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody147:
        LOAD Body147X
        STORE   XYToIndexX
        LOAD Body147Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody148:
        LOAD Body148X
        STORE   XYToIndexX
        LOAD Body148Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody149:
        LOAD Body149X
        STORE   XYToIndexX
        LOAD Body149Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody150:
        LOAD Body150X
        STORE   XYToIndexX
        LOAD Body150Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody151:
        LOAD Body151X
        STORE   XYToIndexX
        LOAD Body151Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody152:
        LOAD Body152X
        STORE   XYToIndexX
        LOAD Body152Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody153:
        LOAD Body153X
        STORE   XYToIndexX
        LOAD Body153Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody154:
        LOAD Body154X
        STORE   XYToIndexX
        LOAD Body154Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody155:
        LOAD Body155X
        STORE   XYToIndexX
        LOAD Body155Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody156:
        LOAD Body156X
        STORE   XYToIndexX
        LOAD Body156Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody157:
        LOAD Body157X
        STORE   XYToIndexX
        LOAD Body157Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody158:
        LOAD Body158X
        STORE   XYToIndexX
        LOAD Body158Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody159:
        LOAD Body159X
        STORE   XYToIndexX
        LOAD Body159Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody160:
        LOAD Body160X
        STORE   XYToIndexX
        LOAD Body160Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody161:
        LOAD Body161X
        STORE   XYToIndexX
        LOAD Body161Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody162:
        LOAD Body162X
        STORE   XYToIndexX
        LOAD Body162Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody163:
        LOAD Body163X
        STORE   XYToIndexX
        LOAD Body163Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody164:
        LOAD Body164X
        STORE   XYToIndexX
        LOAD Body164Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody165:
        LOAD Body165X
        STORE   XYToIndexX
        LOAD Body165Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody166:
        LOAD Body166X
        STORE   XYToIndexX
        LOAD Body166Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody167:
        LOAD Body167X
        STORE   XYToIndexX
        LOAD Body167Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody168:
        LOAD Body168X
        STORE   XYToIndexX
        LOAD Body168Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody169:
        LOAD Body169X
        STORE   XYToIndexX
        LOAD Body169Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody170:
        LOAD Body170X
        STORE   XYToIndexX
        LOAD Body170Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody171:
        LOAD Body171X
        STORE   XYToIndexX
        LOAD Body171Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody172:
        LOAD Body172X
        STORE   XYToIndexX
        LOAD Body172Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody173:
        LOAD Body173X
        STORE   XYToIndexX
        LOAD Body173Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody174:
        LOAD Body174X
        STORE   XYToIndexX
        LOAD Body174Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody175:
        LOAD Body175X
        STORE   XYToIndexX
        LOAD Body175Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody176:
        LOAD Body176X
        STORE   XYToIndexX
        LOAD Body176Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody177:
        LOAD Body177X
        STORE   XYToIndexX
        LOAD Body177Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody178:
        LOAD Body178X
        STORE   XYToIndexX
        LOAD Body178Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody179:
        LOAD Body179X
        STORE   XYToIndexX
        LOAD Body179Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody180:
        LOAD Body180X
        STORE   XYToIndexX
        LOAD Body180Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody181:
        LOAD Body181X
        STORE   XYToIndexX
        LOAD Body181Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody182:
        LOAD Body182X
        STORE   XYToIndexX
        LOAD Body182Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody183:
        LOAD Body183X
        STORE   XYToIndexX
        LOAD Body183Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody184:
        LOAD Body184X
        STORE   XYToIndexX
        LOAD Body184Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody185:
        LOAD Body185X
        STORE   XYToIndexX
        LOAD Body185Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody186:
        LOAD Body186X
        STORE   XYToIndexX
        LOAD Body186Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody187:
        LOAD Body187X
        STORE   XYToIndexX
        LOAD Body187Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody188:
        LOAD Body188X
        STORE   XYToIndexX
        LOAD Body188Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody189:
        LOAD Body189X
        STORE   XYToIndexX
        LOAD Body189Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody190:
        LOAD Body190X
        STORE   XYToIndexX
        LOAD Body190Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody191:
        LOAD Body191X
        STORE   XYToIndexX
        LOAD Body191Y
        STORE   XYToIndexY
        JUMP EndEraseBody
    EraseBody192:
        LOAD Body192X
        STORE   XYToIndexX
        LOAD Body192Y
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
WaitingLoop:
	CALL	GameCheckButton
	IN		Timer
	ADDI	-1
	JNEG	WaitingLoop
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
MaxBodySize: DW 192 ; constant value    board is 32 wide, 6 tall
CurBodySize:   DW 1
; CODE GEN 4
Body1X:        DW 0
Body1Y:        DW 0
Body2X:        DW 0
Body2Y:        DW 0
Body3X:        DW 0
Body3Y:        DW 0
Body4X:        DW 0
Body4Y:        DW 0
Body5X:        DW 0
Body5Y:        DW 0
Body6X:        DW 0
Body6Y:        DW 0
Body7X:        DW 0
Body7Y:        DW 0
Body8X:        DW 0
Body8Y:        DW 0
Body9X:        DW 0
Body9Y:        DW 0
Body10X:        DW 0
Body10Y:        DW 0
Body11X:        DW 0
Body11Y:        DW 0
Body12X:        DW 0
Body12Y:        DW 0
Body13X:        DW 0
Body13Y:        DW 0
Body14X:        DW 0
Body14Y:        DW 0
Body15X:        DW 0
Body15Y:        DW 0
Body16X:        DW 0
Body16Y:        DW 0
Body17X:        DW 0
Body17Y:        DW 0
Body18X:        DW 0
Body18Y:        DW 0
Body19X:        DW 0
Body19Y:        DW 0
Body20X:        DW 0
Body20Y:        DW 0
Body21X:        DW 0
Body21Y:        DW 0
Body22X:        DW 0
Body22Y:        DW 0
Body23X:        DW 0
Body23Y:        DW 0
Body24X:        DW 0
Body24Y:        DW 0
Body25X:        DW 0
Body25Y:        DW 0
Body26X:        DW 0
Body26Y:        DW 0
Body27X:        DW 0
Body27Y:        DW 0
Body28X:        DW 0
Body28Y:        DW 0
Body29X:        DW 0
Body29Y:        DW 0
Body30X:        DW 0
Body30Y:        DW 0
Body31X:        DW 0
Body31Y:        DW 0
Body32X:        DW 0
Body32Y:        DW 0
Body33X:        DW 0
Body33Y:        DW 0
Body34X:        DW 0
Body34Y:        DW 0
Body35X:        DW 0
Body35Y:        DW 0
Body36X:        DW 0
Body36Y:        DW 0
Body37X:        DW 0
Body37Y:        DW 0
Body38X:        DW 0
Body38Y:        DW 0
Body39X:        DW 0
Body39Y:        DW 0
Body40X:        DW 0
Body40Y:        DW 0
Body41X:        DW 0
Body41Y:        DW 0
Body42X:        DW 0
Body42Y:        DW 0
Body43X:        DW 0
Body43Y:        DW 0
Body44X:        DW 0
Body44Y:        DW 0
Body45X:        DW 0
Body45Y:        DW 0
Body46X:        DW 0
Body46Y:        DW 0
Body47X:        DW 0
Body47Y:        DW 0
Body48X:        DW 0
Body48Y:        DW 0
Body49X:        DW 0
Body49Y:        DW 0
Body50X:        DW 0
Body50Y:        DW 0
Body51X:        DW 0
Body51Y:        DW 0
Body52X:        DW 0
Body52Y:        DW 0
Body53X:        DW 0
Body53Y:        DW 0
Body54X:        DW 0
Body54Y:        DW 0
Body55X:        DW 0
Body55Y:        DW 0
Body56X:        DW 0
Body56Y:        DW 0
Body57X:        DW 0
Body57Y:        DW 0
Body58X:        DW 0
Body58Y:        DW 0
Body59X:        DW 0
Body59Y:        DW 0
Body60X:        DW 0
Body60Y:        DW 0
Body61X:        DW 0
Body61Y:        DW 0
Body62X:        DW 0
Body62Y:        DW 0
Body63X:        DW 0
Body63Y:        DW 0
Body64X:        DW 0
Body64Y:        DW 0
Body65X:        DW 0
Body65Y:        DW 0
Body66X:        DW 0
Body66Y:        DW 0
Body67X:        DW 0
Body67Y:        DW 0
Body68X:        DW 0
Body68Y:        DW 0
Body69X:        DW 0
Body69Y:        DW 0
Body70X:        DW 0
Body70Y:        DW 0
Body71X:        DW 0
Body71Y:        DW 0
Body72X:        DW 0
Body72Y:        DW 0
Body73X:        DW 0
Body73Y:        DW 0
Body74X:        DW 0
Body74Y:        DW 0
Body75X:        DW 0
Body75Y:        DW 0
Body76X:        DW 0
Body76Y:        DW 0
Body77X:        DW 0
Body77Y:        DW 0
Body78X:        DW 0
Body78Y:        DW 0
Body79X:        DW 0
Body79Y:        DW 0
Body80X:        DW 0
Body80Y:        DW 0
Body81X:        DW 0
Body81Y:        DW 0
Body82X:        DW 0
Body82Y:        DW 0
Body83X:        DW 0
Body83Y:        DW 0
Body84X:        DW 0
Body84Y:        DW 0
Body85X:        DW 0
Body85Y:        DW 0
Body86X:        DW 0
Body86Y:        DW 0
Body87X:        DW 0
Body87Y:        DW 0
Body88X:        DW 0
Body88Y:        DW 0
Body89X:        DW 0
Body89Y:        DW 0
Body90X:        DW 0
Body90Y:        DW 0
Body91X:        DW 0
Body91Y:        DW 0
Body92X:        DW 0
Body92Y:        DW 0
Body93X:        DW 0
Body93Y:        DW 0
Body94X:        DW 0
Body94Y:        DW 0
Body95X:        DW 0
Body95Y:        DW 0
Body96X:        DW 0
Body96Y:        DW 0
Body97X:        DW 0
Body97Y:        DW 0
Body98X:        DW 0
Body98Y:        DW 0
Body99X:        DW 0
Body99Y:        DW 0
Body100X:        DW 0
Body100Y:        DW 0
Body101X:        DW 0
Body101Y:        DW 0
Body102X:        DW 0
Body102Y:        DW 0
Body103X:        DW 0
Body103Y:        DW 0
Body104X:        DW 0
Body104Y:        DW 0
Body105X:        DW 0
Body105Y:        DW 0
Body106X:        DW 0
Body106Y:        DW 0
Body107X:        DW 0
Body107Y:        DW 0
Body108X:        DW 0
Body108Y:        DW 0
Body109X:        DW 0
Body109Y:        DW 0
Body110X:        DW 0
Body110Y:        DW 0
Body111X:        DW 0
Body111Y:        DW 0
Body112X:        DW 0
Body112Y:        DW 0
Body113X:        DW 0
Body113Y:        DW 0
Body114X:        DW 0
Body114Y:        DW 0
Body115X:        DW 0
Body115Y:        DW 0
Body116X:        DW 0
Body116Y:        DW 0
Body117X:        DW 0
Body117Y:        DW 0
Body118X:        DW 0
Body118Y:        DW 0
Body119X:        DW 0
Body119Y:        DW 0
Body120X:        DW 0
Body120Y:        DW 0
Body121X:        DW 0
Body121Y:        DW 0
Body122X:        DW 0
Body122Y:        DW 0
Body123X:        DW 0
Body123Y:        DW 0
Body124X:        DW 0
Body124Y:        DW 0
Body125X:        DW 0
Body125Y:        DW 0
Body126X:        DW 0
Body126Y:        DW 0
Body127X:        DW 0
Body127Y:        DW 0
Body128X:        DW 0
Body128Y:        DW 0
Body129X:        DW 0
Body129Y:        DW 0
Body130X:        DW 0
Body130Y:        DW 0
Body131X:        DW 0
Body131Y:        DW 0
Body132X:        DW 0
Body132Y:        DW 0
Body133X:        DW 0
Body133Y:        DW 0
Body134X:        DW 0
Body134Y:        DW 0
Body135X:        DW 0
Body135Y:        DW 0
Body136X:        DW 0
Body136Y:        DW 0
Body137X:        DW 0
Body137Y:        DW 0
Body138X:        DW 0
Body138Y:        DW 0
Body139X:        DW 0
Body139Y:        DW 0
Body140X:        DW 0
Body140Y:        DW 0
Body141X:        DW 0
Body141Y:        DW 0
Body142X:        DW 0
Body142Y:        DW 0
Body143X:        DW 0
Body143Y:        DW 0
Body144X:        DW 0
Body144Y:        DW 0
Body145X:        DW 0
Body145Y:        DW 0
Body146X:        DW 0
Body146Y:        DW 0
Body147X:        DW 0
Body147Y:        DW 0
Body148X:        DW 0
Body148Y:        DW 0
Body149X:        DW 0
Body149Y:        DW 0
Body150X:        DW 0
Body150Y:        DW 0
Body151X:        DW 0
Body151Y:        DW 0
Body152X:        DW 0
Body152Y:        DW 0
Body153X:        DW 0
Body153Y:        DW 0
Body154X:        DW 0
Body154Y:        DW 0
Body155X:        DW 0
Body155Y:        DW 0
Body156X:        DW 0
Body156Y:        DW 0
Body157X:        DW 0
Body157Y:        DW 0
Body158X:        DW 0
Body158Y:        DW 0
Body159X:        DW 0
Body159Y:        DW 0
Body160X:        DW 0
Body160Y:        DW 0
Body161X:        DW 0
Body161Y:        DW 0
Body162X:        DW 0
Body162Y:        DW 0
Body163X:        DW 0
Body163Y:        DW 0
Body164X:        DW 0
Body164Y:        DW 0
Body165X:        DW 0
Body165Y:        DW 0
Body166X:        DW 0
Body166Y:        DW 0
Body167X:        DW 0
Body167Y:        DW 0
Body168X:        DW 0
Body168Y:        DW 0
Body169X:        DW 0
Body169Y:        DW 0
Body170X:        DW 0
Body170Y:        DW 0
Body171X:        DW 0
Body171Y:        DW 0
Body172X:        DW 0
Body172Y:        DW 0
Body173X:        DW 0
Body173Y:        DW 0
Body174X:        DW 0
Body174Y:        DW 0
Body175X:        DW 0
Body175Y:        DW 0
Body176X:        DW 0
Body176Y:        DW 0
Body177X:        DW 0
Body177Y:        DW 0
Body178X:        DW 0
Body178Y:        DW 0
Body179X:        DW 0
Body179Y:        DW 0
Body180X:        DW 0
Body180Y:        DW 0
Body181X:        DW 0
Body181Y:        DW 0
Body182X:        DW 0
Body182Y:        DW 0
Body183X:        DW 0
Body183Y:        DW 0
Body184X:        DW 0
Body184Y:        DW 0
Body185X:        DW 0
Body185Y:        DW 0
Body186X:        DW 0
Body186Y:        DW 0
Body187X:        DW 0
Body187Y:        DW 0
Body188X:        DW 0
Body188Y:        DW 0
Body189X:        DW 0
Body189Y:        DW 0
Body190X:        DW 0
Body190Y:        DW 0
Body191X:        DW 0
Body191Y:        DW 0
Body192X:        DW 0
Body192Y:        DW 0
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
Key1:				EQU &H0AF