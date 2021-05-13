-----------------------------------------------------
-- Title: ReLu_tb.vhdl
-- Author: Rafael Romon/NN-1
-- DAT096 - spring 2021
-----------------------------------------------------
-- Description:
-- Testbench for the Relu entity.
-----------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY ReLu_tb IS
	GENERIC
	(
		INT_SIZE : INTEGER := 32
	);
END ReLu_tb;

ARCHITECTURE ReLu_tb_arch OF ReLu_tb IS

	SIGNAL clk_tb     : STD_LOGIC := '1';
	SIGNAL enable_tb  : STD_LOGIC;
	SIGNAL reset_p_tb : STD_LOGIC;
	SIGNAL input_tb   : STD_LOGIC_VECTOR(INT_SIZE - 1 DOWNTO 0);
	SIGNAL output_tb  : STD_LOGIC_VECTOR(INT_SIZE - 1 DOWNTO 0);

	COMPONENT ReLu
		GENERIC
		(
			INT_SIZE : INTEGER := 32
		);
		PORT
		(
			clk     : IN  STD_LOGIC;
			enable  : IN  STD_LOGIC;
			reset_p : IN  STD_LOGIC;
			input   : IN  STD_LOGIC_VECTOR(INT_SIZE - 1 DOWNTO 0);
			output  : OUT STD_LOGIC_VECTOR(INT_SIZE - 1 DOWNTO 0)
		);
	END COMPONENT ReLu;

BEGIN

	ReLu_comp : ReLu
	GENERIC
	MAP (
	INT_SIZE => INT_SIZE
	)
	PORT MAP
	(
		clk     => clk_tb,
		enable  => enable_tb,
		reset_p => reset_p_tb,
		input   => input_tb,
		output  => output_tb
	);

	clk_tb <= NOT clk_tb AFTER 10 ns;

	PROCESS IS
	BEGIN

		reset_p_tb <= '1';
		WAIT FOR 20ns;
		reset_p_tb <= '0';
		WAIT FOR 20ns;

    enable_tb  <= '1';

    input_tb <= std_logic_vector(to_signed(-95, INT_SIZE));
		WAIT FOR 45ns;
		ASSERT (output_tb = std_logic_vector(to_signed(0, INT_SIZE)))
		REPORT "output doesn't match expectations"
			SEVERITY warning;

		input_tb <= std_logic_vector(to_signed(40, INT_SIZE));
		WAIT FOR 45ns; -- wait 2 clocks and a bit more for output
		ASSERT (output_tb = std_logic_vector(to_signed(40, INT_SIZE)))
		REPORT "output doesn't match expectations"
			SEVERITY warning;

    input_tb <= std_logic_vector(to_signed(0, INT_SIZE));
		WAIT FOR 45ns;
		ASSERT (output_tb = std_logic_vector(to_signed(0, INT_SIZE)))
		REPORT "output doesn't match expectations"
			SEVERITY warning;

		input_tb <= std_logic_vector(to_signed(125, INT_SIZE));
		WAIT FOR 45ns;
		ASSERT (output_tb = std_logic_vector(to_signed(125, INT_SIZE)))
		REPORT "output doesn't match expectations"
			SEVERITY warning;

		input_tb <= std_logic_vector(to_signed(-81, INT_SIZE));
		WAIT FOR 45ns;
		ASSERT (output_tb = std_logic_vector(to_signed(0, INT_SIZE)))
		REPORT "output doesn't match expectations"
			SEVERITY warning;

		input_tb <= std_logic_vector(to_signed(-452, INT_SIZE));
		WAIT FOR 45ns;
		ASSERT (output_tb = std_logic_vector(to_signed(0, INT_SIZE)))
		REPORT "output doesn't match expectations"
			SEVERITY warning;

		REPORT "simulation finished." SEVERITY FAILURE;

	END PROCESS;
END ReLu_tb_arch;
