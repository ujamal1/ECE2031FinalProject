-- DIG_IN.VHD (a peripheral module for SCOMP)
-- This module reads digital inputs directly

LIBRARY IEEE;
LIBRARY LPM;

USE IEEE.STD_LOGIC_1164.ALL;
USE LPM.LPM_COMPONENTS.ALL;

ENTITY KEY1_IN IS
  PORT(
	 CS_KEY      : IN		STD_LOGIC;
	 KEY_DI      : IN    STD_LOGIC_VECTOR(15 DOWNTO 0);
    IO_DATA     : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
END KEY1_IN;

ARCHITECTURE a OF KEY1_IN IS
  SIGNAL B_DI : STD_LOGIC_VECTOR(15 DOWNTO 0);

  BEGIN
    -- Use LPM function to create bidirectional I/O data bus
    IO_BUS: lpm_bustri
    GENERIC MAP (
      lpm_width => 16
    )
    PORT MAP (
      data     => B_DI,
      enabledt => CS_KEY,
      tridata  => IO_DATA
    );

    PROCESS (CS_KEY)
    BEGIN
      if (RISING_EDGE(CS_KEY)) then
			B_DI <= KEY_DI; -- sample the input on the rising edge of CS
		end if;
    END PROCESS;

END a;
