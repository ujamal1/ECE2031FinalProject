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
	JUMP	Game			; Else, jump to game

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
	
	LOADI	0
	STORE	GameAddress
	
	GameLoop:
		; First, do game logic and checks
		LOAD	GameAddress			; If the current address to be set is out of bounds, then the player failed
		JNEG	GameFail			; To be in bounds, the address must be: 0 ≤ address < NumNeos which is the same as 0 ≤ address ≤ NumNeos - 1
		SUB		NumNeos
		ADDI	-1
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
		JZERO	GameCheckButton_Pressed
		; This is logic for when the button is NOT pressed
		; First let's check if it was pressed before
		LOAD	KeyPressed
		; If it wasn't, then there's nothing left to do
		JZERO	ExitFunc
		; If it was, then we should change direction
		LOAD	GameDir
		JPOS	SubDir			; If the GameDir is currently 1, then we should subtract 2 from it to make it -1 by going to SubDir
		ADDI	2				; Otherwise, add 2 to go from -1 -> 1
		STORE	GameDir
		RETURN
		SubDir:
		ADDI	-2
		STORE	GameDir
		RETURN
		
		GameCheckButton_Pressed:
		STORE	KeyPressed
		RETURN
		
		ExitFunc:
		RETURN

Delay:
	OUT    Timer
WaitingLoop:
	CALL	GameCheckButton
	IN		Timer
	ADDI	-2
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


; Variables
Mode:			DW 0
Color16:		DW 0
Color24_R:		DW 0
Color24_GB:		DW 0
AutoAddress:	DW 0
GameAddress:	DW 0
GameDir:		DW 0 ; Game Direction
NumNeos:		DW 0
KeyPressed:		DW 0

; Constants
FiveBits:	DW	31
SixBits:	DW	63
EightBits:	DW	255
Green16:	DW	&B11111100000;
Red16:		DW	&B1111100000000000;

; IO address constants
Switches:	EQU &H000
LEDs:		EQU &H001
Timer:		EQU &H002
Hex0:		EQU &H004
Hex1:		EQU &H005
I2C_cmd:	EQU &H090
I2C_data:	EQU &H091
I2C_rdy:	EQU &H092


Neo_All16:			EQU &H0A0
Neo_Addr:			EQU &H0A1
Neo_Single16:		EQU &H0A2
Neo_Single24_R:		EQU &H0A3
Neo_Single24_GB:	EQU &H0A4
Key1:				EQU &H0AF