-----------------------------------------------------
-- Title: ReLu.vhdl
-- Author: Rafael Romon/NN-1
-- DAT096 - spring 2021
-----------------------------------------------------
-- Description:
-- Implements a ReLu filter
-- architecture of the entire system
-----------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY ReLu IS
	GENERIC
	(
		INT_SIZE : INTEGER := 32
	);
	PORT
	(
		clk    : IN  STD_LOGIC;
		input  : IN  SIGNED(INT_SIZE - 1 DOWNTO 0);
		output : OUT UNSIGNED(INT_SIZE - 1 DOWNTO 0)
	);
END ReLu;

ARCHITECTURE ReLu_arch OF ReLu IS

BEGIN
    ReLu_process : PROCESS (clk)
    BEGIN
        IF RISING_EDGE(clk) THEN	
            IF input < 0 THEN
                output <= (OTHERS => '0');
            ELSE
                output <= unsigned(input);
            END IF;
        END IF;		
	END PROCESS ReLu_process;
END ReLu_arch;