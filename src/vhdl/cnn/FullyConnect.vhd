-----------------------------------------------------
-- Title: FullyConnect.vhdl
-- Author: Johan Nilsson/NN-1
--         Sebastian Bengtsson/NN-1
--         Rafael Romon/NN-1
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

ENTITY FullyConnect IS
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
		scale_values  : IN  STD_LOGIC_VECTOR(NEURON_NUM * INTERNAL_SIZE - 1 DOWNTO 0);
		busy          : OUT STD_LOGIC;
		done          : OUT STD_LOGIC;
		output        : OUT STD_LOGIC_VECTOR(NEURON_NUM * IO_SIZE - 1 DOWNTO 0)
	);
END FullyConnect;

ARCHITECTURE FullyConnect_arch OF FullyConnect IS

	TYPE states IS (Idle, Working, Finished);
	SIGNAL state_machine : states := Idle;
	TYPE IO_ARRAY IS ARRAY (0 TO NEURON_NUM - 1) OF STD_LOGIC_VECTOR(IO_SIZE - 1 DOWNTO 0);
	TYPE FILTER_ARRAY IS ARRAY (0 TO NEURON_NUM - 1) OF STD_LOGIC_VECTOR(INPUT_NUM * IO_SIZE - 1 DOWNTO 0);
	TYPE INTERNAL_ARRAY IS ARRAY (0 TO NEURON_NUM - 1) OF STD_LOGIC_VECTOR(INTERNAL_SIZE - 1 DOWNTO 0);

	-----
	-- Neuron component and signals
	-----

	SIGNAL weight_array : FILTER_ARRAY;
	SIGNAL bias_array   : INTERNAL_ARRAY;
	SIGNAL scale_array  : INTERNAL_ARRAY;

	SIGNAL neuron_start        : STD_LOGIC;
	SIGNAL neuron_busy_vector  : STD_LOGIC_VECTOR(NEURON_NUM - 1 DOWNTO 0);
	SIGNAL neuron_done_vector  : STD_LOGIC_VECTOR(NEURON_NUM - 1 DOWNTO 0);
	SIGNAL neuron_output_array : IO_ARRAY;

	COMPONENT Neuron
		GENERIC
		(
			KERNEL_HEIGHT : INTEGER := 9;
			KERNEL_WIDTH  : INTEGER := 1;
			KERNEL_DEPTH  : INTEGER := 1;
			IO_SIZE       : INTEGER := 8; -- integer sizes for input and output
			INTERNAL_SIZE : INTEGER := 32 -- integer size for internal operations
		);
		PORT
		(
			clk           : IN  STD_LOGIC;
			reset_p       : IN  STD_LOGIC;
			start         : IN  STD_LOGIC;
			input         : IN  STD_LOGIC_VECTOR((KERNEL_HEIGHT * KERNEL_WIDTH * KERNEL_DEPTH * IO_SIZE) - 1 DOWNTO 0);
			filter_values : IN  STD_LOGIC_VECTOR ((KERNEL_HEIGHT * KERNEL_WIDTH * KERNEL_DEPTH * IO_SIZE) - 1 DOWNTO 0);
			bias          : IN  STD_LOGIC_VECTOR(INTERNAL_SIZE - 1 DOWNTO 0);
			scale         : IN  STD_LOGIC_VECTOR(INTERNAL_SIZE - 1 DOWNTO 0);
			busy          : OUT STD_LOGIC;
			done          : OUT STD_LOGIC;
			output        : OUT STD_LOGIC_VECTOR(IO_SIZE - 1 DOWNTO 0)
		);
	END COMPONENT Neuron;

	-----
	-- Reg component and signals
	-----

	SIGNAL output_enable : STD_LOGIC;
	SIGNAL output_signal : STD_LOGIC_VECTOR(NEURON_NUM * IO_SIZE - 1 DOWNTO 0);

	COMPONENT Reg
		GENERIC
		(
			SIG_WIDTH : INTEGER := 8
		);
		PORT
		(
			clk     : IN  STD_LOGIC;
			reset_p : IN  STD_LOGIC;
			enable  : IN  STD_LOGIC;
			input   : IN  STD_LOGIC_VECTOR(SIG_WIDTH - 1 DOWNTO 0);
			output  : OUT STD_LOGIC_VECTOR(SIG_WIDTH - 1 DOWNTO 0)
		);
	END COMPONENT Reg;

BEGIN

	Neuron_operation : FOR i IN 0 TO NEURON_NUM - 1 GENERATE
		weight_array(i) <= weight_values(((i + 1) * IO_SIZE * INPUT_NUM - 1) DOWNTO (i * IO_SIZE * INPUT_NUM));
		bias_array(i)   <= bias_values(((i + 1) * INTERNAL_SIZE - 1) DOWNTO (i * INTERNAL_SIZE));
		scale_array(i)   <= scale_values(((i + 1) * INTERNAL_SIZE - 1) DOWNTO (i * INTERNAL_SIZE));

		neuron_comp : Neuron
		GENERIC
		MAP (
		KERNEL_HEIGHT => 1,
		KERNEL_WIDTH  => 1,
		KERNEL_DEPTH  => 9, -- This needs to be 9 as to not mess with the data width of the registers in Neuron.vhdl
		IO_SIZE       => IO_SIZE,
		INTERNAL_SIZE => INTERNAL_SIZE
		)
		PORT MAP
		(
			clk           => clk,
			reset_p       => reset_p,
			start         => neuron_start,
			input         => input,
			filter_values => weight_array(i),
			bias          => bias_array(i),
			scale         => scale_array(i),
			busy          => neuron_busy_vector(i),
			done          => neuron_done_vector(i),
			output        => neuron_output_array(i)
		);

	END GENERATE;

	output_reg : reg
	GENERIC
	MAP(
	SIG_WIDTH => IO_SIZE
	)
	PORT
	MAP(
	clk     => clk,
	reset_p => reset_p,
	enable  => output_enable,
	input   => output_signal,
	output  => output
	);

	PROCESS (clk)
	BEGIN
		IF reset_p = '1' THEN
			busy          <= '0';
			done          <= '0';
			neuron_start  <= '0';
			output_enable <= '0';
			output_signal <= (OTHERS => '0');

		ELSIF RISING_EDGE(clk) THEN

			CASE state_machine IS
				WHEN Idle =>
					IF start = '1' THEN
						busy          <= '1';
						done          <= '0';
						output_enable <= '0';
						neuron_start  <= '1';
						state_machine <= Working;
					END IF;

				WHEN Working =>
					neuron_start <= '0';

					IF neuron_done_vector(0) = '1' THEN

						FOR i IN 0 TO NEURON_NUM - 1 LOOP
							output_signal((i + 1) * IO_SIZE - 1 DOWNTO i * IO_SIZE) <= neuron_output_array(i);
						END LOOP;

						state_machine <= Finished;
						output_enable <= '1';
					END IF;

				WHEN Finished =>
					busy <= '0';
					done <= '1';

					IF start = '0' THEN
						state_machine <= Idle;
					END IF;

			END CASE;
		END IF;
	END PROCESS;

END FullyConnect_arch;
