-----------------------------------------------------
-- Title: FullyConnect.vhdl
-- Author: Johan Nilsson/NN-1
-- DAT096 - spring 2021
-----------------------------------------------------
-- Description:
-- The full connection (dense) layer are the last
-- layers of the CNN where the input vector is reduced
-- into just a few elements in a vector
-----------------------------------------------------
-- ToDo
-- Implement quant so that the output is convertet from
-- int32 back to int8
-----------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY FullyConnect_TB IS
	GENERIC
	(
		INPUT_NUM     : INTEGER := 9;
		NEURON_NUM    : INTEGER := 1;
		IO_SIZE       : INTEGER := 8;
		INTERNAL_SIZE : INTEGER := 32
	);

END FullyConnect_TB;

ARCHITECTURE FullyConnect_TB_arch OF FullyConnect_TB IS

	SIGNAL clk_tb           : STD_LOGIC := '0';
	SIGNAL reset_p_tb       : STD_LOGIC;
	SIGNAL start_tb         : STD_LOGIC;
	SIGNAL input_tb         : STD_LOGIC_VECTOR((INPUT_NUM * IO_SIZE) - 1 DOWNTO 0);
	SIGNAL weight_values_tb : STD_LOGIC_VECTOR((INPUT_NUM * NEURON_NUM * IO_SIZE) - 1 DOWNTO 0);
	SIGNAL bias_values_tb   : STD_LOGIC_VECTOR(NEURON_NUM * INTERNAL_SIZE - 1 DOWNTO 0);
	SIGNAL busy_tb          : STD_LOGIC;
	SIGNAL done_tb          : STD_LOGIC;
	SIGNAL output_tb        : STD_LOGIC_VECTOR(NEURON_NUM * IO_SIZE - 1 DOWNTO 0);

	COMPONENT FullyConnect
		GENERIC
		(
			INPUT_NUM     : INTEGER := 9;
			NEURON_NUM    : INTEGER := 1;
			IO_SIZE       : INTEGER := 8;
			INTERNAL_SIZE : INTEGER := 32
		);
		PORT
		(
			clk           : IN  STD_LOGIC;
			reset_p       : IN  STD_LOGIC;
			start         : IN  STD_LOGIC;
			input         : IN  STD_LOGIC_VECTOR((INPUT_NUM * IO_SIZE) - 1 DOWNTO 0);
			weight_values : IN  STD_LOGIC_VECTOR((INPUT_NUM * NEURON_NUM * IO_SIZE) - 1 DOWNTO 0);
			bias_values   : IN  STD_LOGIC_VECTOR(NEURON_NUM * INTERNAL_SIZE - 1 DOWNTO 0);
			busy          : OUT STD_LOGIC;
			done          : OUT STD_LOGIC;
			output        : OUT STD_LOGIC_VECTOR(NEURON_NUM * IO_SIZE - 1 DOWNTO 0)
		);
	END COMPONENT FullyConnect;

BEGIN

	FullyConnect_comp : FullyConnect
	GENERIC
	MAP(
	INPUT_NUM     => INPUT_NUM,
	NEURON_NUM    => NEURON_NUM,
	IO_SIZE       => IO_SIZE,
	INTERNAL_SIZE => INTERNAL_SIZE
	)
	PORT MAP
	(
		clk           => clk_tb,
		reset_p       => reset_p_tb,
		start         => start_tb,
		input         => input_tb,
		weight_values => weight_values_tb,
		bias_values   => bias_values_tb,
		busy          => busy_tb,
		done          => done_tb,
		output        => output_tb
	);

	reset_p_tb <= '0',
		'1' AFTER 20 ns,
		'0' AFTER 50 ns;

	clock_process :
	PROCESS
	BEGIN
		clk_tb <= NOT(clk_tb);
		WAIT FOR 5 ns;
	END PROCESS;

	testprocess : PROCESS
	BEGIN
		start_tb         <= '1';
		input_tb         <= x"010203040506070809";
		weight_values_tb <= x"020202020202020202";
		bias_values_tb   <= x"00000001";

		WAIT UNTIL done_tb = '1';
		ASSERT output_tb = x"5b"
		REPORT "Wrong value"
			SEVERITY WARNING;
		WAIT FOR 20ns;
		REPORT "Simulation Finished." SEVERITY FAILURE;
	END PROCESS;

END FullyConnect_TB_arch;
