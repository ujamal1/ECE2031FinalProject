ORG 0
Start:
	LOADI	0
	STORE	Mode ; Reset the mode on reset

ChooseMode:
	CALL	WaitForButton
	IN		Switches		; Get the values of the switches after
	JZERO	SetSingle16		; the confirmation button is pressed
	ADDI	-1
	JZERO	SetSingle24
	ADDI	-1
	JZERO	SetAll16
	ADDI	-1
	JZERO	AutoIncrement

SetSingle16:
	CALL	OutAddress
	CALL	GetColors16
	LOAD	Color16
	OUT		Neo_Single16
	JUMP	SetSingle16
	

SetSingle24:
	CALL	OutAddress
	CALL	GetColors24
	LOAD	Color24_R
	OUT		Neo_Single24_R
	LOAD	Color24_GB
	OUT		Neo_Single24_GB
	JUMP	SetSingle24

SetAll16:
	CALL	GetColors16
	LOAD	Color16
	OUT		Neo_All16
	JUMP	SetAll16

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
		

WaitForButton:
	IN		Key0
	JPOS	WaitForButton	; Button is not pressed, check again
	WaitForRelease:
		IN		Key0		; Button was just pressed, wait for it to be released
		JZERO	WaitForRelease
	RETURN

; Gets the Neopixel address from the switches and writes it to the address peripheral
OutAddress:
	CALL	WaitForButton
	IN		Switches
	AND		EightBits		; Mask off the rightmost eight bits to fit the
	OUT		Neo_Addr		; address length and store them in the peripheral
	RETURN

; Gets the values for a 16 bit color and stores the value in the Color16 variable
GetColors16:
	; Read in the red color
	CALL	WaitForButton
	IN		Switches
	AND		FiveBits
	SHIFT	7
	STORE	Color16
	
	; Read in the green color
	CALL	WaitForButton
	IN		Switches
	AND		SixBits
	SHIFT	4
	OR		Color16
	STORE	Color16
	
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
	
	; Read in the red color
	CALL	WaitForButton
	IN		Switches
	AND		EightBits
	STORE	Color24_R
	
	; Read in the green color
	CALL	WaitForButton
	IN		Switches
	AND		EightBits
	SHIFT	8
	STORE	Color24_GB
	
	; Read in the blue color
	CALL	WaitForButton
	IN		Switches
	AND		EightBits
	OR		Color24_GB
	STORE	Color24_GB
	
	RETURN


; Variables
Mode:		 DW	0
Color16:	 DW	0
Color24_R:	 DW	0
Color24_GB:	 DW	0
AutoAddress: DW  0

; Constants
FiveBits:	DW	31
SixBits:	DW	63
EightBits:	DW	255

; IO address constants
Switches:	EQU &H000
LEDs:		EQU &H001
Timer:		EQU &H002
Hex0:		EQU &H004
Hex1:		EQU &H005
I2C_cmd:	EQU &H090
I2C_data:	EQU &H091
I2C_rdy:	EQU &H092


Neo_All16:		EQU &H0A0
Neo_Addr:		EQU &H0A1
Neo_Single16:	EQU &H0A2
Neo_Single24_R:	EQU &H0A3
Neo_Single24_GB:EQU &H0A4