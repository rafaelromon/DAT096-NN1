-----------------------------------------------------
-- Title: ReLu.vhdl
-- Author: Rafael Romon/NN-1
-- DAT096 - spring 2021
-----------------------------------------------------
-- Description:
-- Rectified Linear Unit or Relu activation function
-- as an entity: if input is less 0 set output to
-- 0, else set to input.
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
		enable : IN  STD_LOGIC;
		reset_p : IN  STD_LOGIC;
		input  : IN  STD_LOGIC_VECTOR(INT_SIZE - 1 DOWNTO 0);
		output : OUT STD_LOGIC_VECTOR(INT_SIZE - 1 DOWNTO 0)
	);
END ReLu;

ARCHITECTURE ReLu_arch OF ReLu IS

signal output_signal: STD_LOGIC_VECTOR(INT_SIZE - 1 DOWNTO 0);

component Reg
generic (
  SIG_WIDTH : INTEGER := 8
);
port (
  clk     : IN  STD_LOGIC;
  reset_p : IN  STD_LOGIC;
  enable  : IN  STD_LOGIC;
  input   : IN  STD_LOGIC_VECTOR(SIG_WIDTH-1 DOWNTO 0);
  output  : OUT STD_LOGIC_VECTOR(SIG_WIDTH-1 DOWNTO 0)
);
end component Reg;

BEGIN

	output_register : Reg
	generic map (
		SIG_WIDTH => INT_SIZE
	)
	port map (
		clk     => clk,
		reset_p => reset_p,
		enable  => enable,
		input   => output_signal,
		output  => output
	);

	PROCESS (clk)
	BEGIN
		IF reset_p = '1' THEN
			output_signal <= (OTHERS => '0');
		ELSIF RISING_EDGE(clk) THEN
			IF enable = '1' THEN
				IF signed(input) < 0 THEN
					output_signal <= (OTHERS => '0');
				ELSE
					output_signal <= input;
				END IF;
			END IF;
		END IF;
	END PROCESS;
END ReLu_arch;
