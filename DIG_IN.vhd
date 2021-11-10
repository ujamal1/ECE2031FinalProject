-- DIG_IN.VHD (a peripheral module for SCOMP)
-- This module reads digital inputs directly

LIBRARY IEEE;
LIBRARY LPM;

USE IEEE.STD_LOGIC_1164.ALL;
USE LPM.LPM_COMPONENTS.ALL;

ENTITY DIG_IN IS
  PORT(
    CS          : IN    STD_LOGIC;
	 KEY1_EN		 : IN		STD_LOGIC;
	 IO_WRITE    : IN    STD_LOGIC;
    DI          : IN    STD_LOGIC_VECTOR(15 DOWNTO 0);
	 KEY_DI          : IN    STD_LOGIC_VECTOR(15 DOWNTO 0);
    IO_DATA     : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
END DIG_IN;

ARCHITECTURE a OF DIG_IN IS
  SIGNAL B_DI : STD_LOGIC_VECTOR(15 DOWNTO 0);

  BEGIN
    -- Use LPM function to create bidirectional I/O data bus
    IO_BUS: lpm_bustri
    GENERIC MAP (
      lpm_width => 16
    )
    PORT MAP (
      data     => B_DI,
      enabledt => CS,
      tridata  => IO_DATA
    );

    PROCESS
    BEGIN
      WAIT UNTIL RISING_EDGE(CS);
		if KEY1_EN = '1' then
			B_DI <= DI; -- sample the input on the rising edge of CS
		else
			B_DI <= KEY_DI;
		end if;
    END PROCESS;

END a;

