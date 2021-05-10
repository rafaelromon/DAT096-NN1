-----------------------------------------------------
-- Title: Register component                       -- 
-- Author: Johan Nilsson	                       --
-- DAT096 - spring 2021
-----------------------------------------------------
-- Description:                                    --
-- Register that stores a new value on rising      --
-- edge and reset is active high                   --
-----------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;


ENTITY Reg IS 
  GENERIC(SIG_WIDTH : INTEGER :=8); -- set signal wordlength
  PORT( 
	clk     : IN STD_LOGIC;
	reset_p : IN STD_LOGIC;
	enable  : IN STD_LOGIC;
	input   : IN STD_LOGIC_VECTOR(SIG_WIDTH-1 DOWNTO 0);
	output  : OUT STD_LOGIC_VECTOR(SIG_WIDTH-1 DOWNTO 0) );
END Reg;


ARCHITECTURE Reg_arch OF Reg IS
BEGIN 

PROCESS(Clk, reset_p)
BEGIN
	IF reset_p = '1' THEN
		output <= (OTHERS => '0');
	ELSIF rising_edge(Clk) and enable = '1' THEN
		output <= input;
	END IF;
END PROCESS;

END Reg_arch;
