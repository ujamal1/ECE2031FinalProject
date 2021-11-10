-- WS2812 communication interface.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 

entity NeoPixelController is

	port(
		clk_10M  : in   std_logic;
		resetn   : in   std_logic;
		latch    : in   std_logic;
		data     : in   std_logic_vector(15 downto 0);
		sda      : out  std_logic
	); 

end entity;

architecture internals of NeoPixelController is

	-- Signal to store the pixel's color data
	signal led_buffer : std_logic_vector(23 downto 0);
	
	
begin

	process (clk_10M, resetn)
		-- protocol timing values (in 100s of ns)
		constant t1h : integer := 8;
		constant t1l : integer := 4;
		constant t0h : integer := 3;
		constant t0l : integer := 9;

		-- which bit in the 24 bits is being sent
		variable bit_count   : integer range 0 to 23;
		-- counter to count through the bit encoding
		variable enc_count   : integer range 0 to 31;
		-- counter for the reset pulse
		variable reset_count : integer range 0 to 1000;
		
		
	begin
		if resetn = '0' then
			-- reset all counters
			bit_count := 23;
			enc_count := 0;
			reset_count := 1000;
			-- set sda inactive
			sda <= '0';

		elsif (rising_edge(clk_10M)) then

			-- This IF block controls the various counters
			if reset_count > 0 then
				-- during reset period, ensure other counters are reset
				bit_count := 23;
				enc_count := 0;
				-- decrement the reset count
				reset_count := reset_count - 1;
				
			else -- not in reset period (i.e. currently sending data)
				-- handle reaching end of a bit
				if led_buffer(bit_count) = '1' then -- current bit is 1
					if enc_count = (t1h+t1l-1) then -- is end of the bit?
						enc_count := 0;
						if bit_count = 0 then -- is end of the LED's data?
							-- begin the reset period
							reset_count := 1000;
						else
							-- if not end of data, decrement count
							bit_count := bit_count - 1;
						end if;
					else
						-- within a bit, count to achieve correct pulse widths
						enc_count := enc_count + 1;
					end if;
				else -- current bit is 0
					if enc_count = (t0h+t0l-1) then -- is end of the bit?
						enc_count := 0;
						if bit_count = 0 then -- is end of the LED's data?
							-- begin the reset period
							reset_count := 1000;
						else
							bit_count := bit_count - 1;
						end if;
					else
						-- within a bit, count to achieve correct pulse widths
						enc_count := enc_count + 1;
					end if;
				end if;
			end if;
			
			-- This IF block controls sda
			if reset_count > 0 then
				-- sda is 0 during reset/latch
				sda <= '0';
			elsif 
				-- sda is 1 if it's the first part of a bit, which depends on if it's 1 or 0
				( ((led_buffer(bit_count) = '1') and (enc_count < t1h))
				or
				((led_buffer(bit_count) = '0') and (enc_count < t0h)) )
				then sda <= '1';
			else
				sda <= '0';
			end if;
			
		end if;
	end process;
	
	-- Process to handle OUTs from SCOMP
	process(latch)
	begin
		if rising_edge(latch) then
			-- Convert RGB 565 to Neopixel format,
			-- in this case just padding with 0s.
			led_buffer <= data(10 downto 5) & "00" & data(15 downto 11) & "000" & data(4 downto 0) & "000" ;
		end if;
	end process;


end internals;
