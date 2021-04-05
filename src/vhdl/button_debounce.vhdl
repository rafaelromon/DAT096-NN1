-----------------------------------------------------
-- Title: button_debounce.vhdl
-- Author: Rafael Romón/NN-1
-- DAT096 - spring 2021
-----------------------------------------------------
-- Description:
-- This entity debounces hardware buttons
-----------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY button_debounce IS
	GENERIC
	(
		clk_freq    : INTEGER := 100; --system clock frequency in MHz
	    stable_time : INTEGER := 10); --time button must remain stable in ms
	PORT
	(
		clk     : IN STD_LOGIC;
		reset_p : IN STD_LOGIC;
		button  : IN STD_LOGIC;
	    result  : OUT STD_LOGIC);
END button_debounce;

ARCHITECTURE button_debounce_arch OF button_debounce IS
	SIGNAL registers   : STD_LOGIC_VECTOR(1 DOWNTO 0); --input flip flops
	SIGNAL counter_set : STD_LOGIC; --sync reset to zero
BEGIN
	counter_set <= registers(0) XOR registers(1); --determine if output is changing

	PROCESS (clk, reset_p)
	VARIABLE count : INTEGER RANGE 0 TO clk_freq * stable_time * 1000;
	BEGIN
		IF (reset_p = '1') THEN --reset high
			registers(1 DOWNTO 0) <= "00";
			result                <= '0';

    ELSIF RISING_EDGE(clk) THEN
			registers(0) <= button; --store button value in 1st register
			registers(1) <= registers(0); --store 1st register value in 2nd register
      
			IF (counter_set = '1') THEN --reset counter because input is changing
				count := 0; --clear the counter

      ELSIF (count <  stable_time*clk_freq*1000) THEN
				count := count + 1;

      ELSE --stable input time is met
				result <= registers(1); --output stable value

      END IF;
		END IF;
	END PROCESS;

END button_debounce_arch;
