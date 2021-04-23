-----------------------------------------------------
-- Title: CNN.vhdl
-- Author: Rafael Romon/NN-1
-- DAT096 - spring 2021
-----------------------------------------------------
-- Description:
-- simulates the image recognition CNN
-- TODO:
-- * actually implement the CNN
-----------------------------------------------------

LIBRARY IEEE;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY CNN IS
	PORT (
		clk : IN STD_LOGIC;
		reset_p : IN STD_LOGIC;
		start : IN STD_LOGIC;
		image : IN STD_LOGIC_VECTOR(16383 DOWNTO 0);

		finished : OUT STD_LOGIC;
		result : OUT STD_LOGIC_VECTOR(5 DOWNTO 0)
	);
END CNN;

ARCHITECTURE CNN_arch OF CNN IS
	SIGNAL enable : STD_LOGIC := '0';

BEGIN
	stupid_cnn : PROCESS (clk, reset_p)
	BEGIN
		IF reset_p = '1' THEN
			finished <= '0';
			result <= (OTHERS => '0');
		ELSIF RISING_EDGE(clk) THEN
			IF start = '1' AND enable = '0' THEN
				enable <= '1';
				finished <= '0';
			ELSIF enable = '1' THEN
				-- put image into buffers
				-- do cnn stuff
				finished <= '1';
				result <= "101010";
				enable <= '0';
			END IF;
		END IF;
	END PROCESS;

END CNN_arch;
