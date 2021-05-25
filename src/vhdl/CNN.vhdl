-----------------------------------------------------
-- Title: CNN.vhdl
-- Author: Rafael Romon/NN-1
-- DAT096 - spring 2021
-----------------------------------------------------
-- Description:
-- simulates the image recognition CNN
-- TODO:
-- use memory for filter, bias, etc
-----------------------------------------------------

LIBRARY IEEE;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY CNN IS
	GENERIC
	(
		INPUT_WIDTH   : INTEGER := 3;
		INPUT_HEIGHT  : INTEGER := 3;
		IO_SIZE       : INTEGER := 8;
		INTERNAL_SIZE : INTEGER := 32
	);
	PORT
	(
		clk     : IN  STD_LOGIC;
		reset_p : IN  STD_LOGIC;
		start   : IN  STD_LOGIC;
		input   : IN  STD_LOGIC_VECTOR(INPUT_HEIGHT * INPUT_WIDTH * IO_SIZE - 1 DOWNTO 0);
		busy    : OUT STD_LOGIC;
		done    : OUT STD_LOGIC;
		output  : OUT STD_LOGIC_VECTOR(IO_SIZE - 1 DOWNTO 0)
	);
END CNN;

ARCHITECTURE CNN_arch OF CNN IS
	TYPE states IS (Idle, Layers, Dequantize, Finished);
	SIGNAL state_machine : states := Idle;

	-----
	-- DepthWise and PointWise Conv components and signals
	-----

	SIGNAL dw_start  : STD_LOGIC;
	SIGNAL dw_done   : STD_LOGIC;                                                           -- same as pw_start
	SIGNAL dw_output : STD_LOGIC_VECTOR(INPUT_WIDTH * INPUT_HEIGHT * IO_SIZE - 1 DOWNTO 0); -- same as pw_input
	SIGNAL pw_done   : STD_LOGIC;                                                           -- same as dense_start
	SIGNAL pw_output : STD_LOGIC_VECTOR(INPUT_WIDTH * INPUT_HEIGHT * IO_SIZE - 1 DOWNTO 0); -- same as dense_input

	COMPONENT Conv
		GENERIC
		(
			INPUT_WIDTH    : INTEGER := 9;
			INPUT_HEIGHT   : INTEGER := 9;
			INPUT_CHANNELS : INTEGER := 1;
			KERNEL_HEIGHT  : INTEGER := 1;
			KERNEL_WIDTH   : INTEGER := 1;
			KERNEL_DEPTH   : INTEGER := 1;
			STRIDE         : INTEGER := 1;
			ZERO_PADDING   : INTEGER := 0;
			IO_SIZE        : INTEGER := 8;
			INTERNAL_SIZE  : INTEGER := 32
		);
		PORT
		(
			clk           : IN  STD_LOGIC;
			reset_p       : IN  STD_LOGIC;
			start         : IN  STD_LOGIC;
			input         : IN  STD_LOGIC_VECTOR((INPUT_WIDTH * INPUT_HEIGHT * IO_SIZE) - 1 DOWNTO 0);
			filter_values : IN  STD_LOGIC_VECTOR ((KERNEL_HEIGHT * KERNEL_WIDTH * KERNEL_DEPTH * IO_SIZE) - 1 DOWNTO 0);
			bias          : IN  STD_LOGIC_VECTOR(INTERNAL_SIZE - 1 DOWNTO 0);
			scale         : IN  STD_LOGIC_VECTOR(INTERNAL_SIZE - 1 DOWNTO 0);
			busy          : OUT STD_LOGIC;
			done          : OUT STD_LOGIC;
			output        : OUT STD_LOGIC_VECTOR(((INPUT_WIDTH * INPUT_HEIGHT * IO_SIZE)/STRIDE) - 1 DOWNTO 0)
		);
	END COMPONENT Conv;

	-----
	-- FullyConnect components and signals
	-----

	SIGNAL dense_done   : STD_LOGIC; -- same as pw_input
	SIGNAL dense_output : STD_LOGIC_VECTOR(IO_SIZE - 1 DOWNTO 0);

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
			scale_values  : IN  STD_LOGIC_VECTOR(NEURON_NUM * INTERNAL_SIZE - 1 DOWNTO 0);
			busy          : OUT STD_LOGIC;
			done          : OUT STD_LOGIC;
			output        : OUT STD_LOGIC_VECTOR(NEURON_NUM * IO_SIZE - 1 DOWNTO 0)
		);
	END COMPONENT FullyConnect;
	-----
	-- Reg component and signals
	-----

	SIGNAL output_signal : STD_LOGIC_VECTOR(IO_SIZE - 1 DOWNTO 0);
	SIGNAL output_enable : STD_LOGIC := '0';

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

	output_buff : Reg
	GENERIC
	MAP(
	SIG_WIDTH => IO_SIZE
	)
	PORT MAP
	(
		clk     => clk,
		reset_p => reset_p,
		enable  => output_enable,
		input   => output_signal,
		output  => output
	);

	DWConv_comp : Conv
	GENERIC
	MAP (
	INPUT_WIDTH    => INPUT_WIDTH,
	INPUT_HEIGHT   => INPUT_HEIGHT,
	INPUT_CHANNELS => 1,
	KERNEL_HEIGHT  => 3,
	KERNEL_WIDTH   => 3,
	KERNEL_DEPTH   => 1,
	STRIDE         => 1,
	ZERO_PADDING   => 1,
	IO_SIZE        => IO_SIZE,
	INTERNAL_SIZE  => INTERNAL_SIZE
	)
	PORT
	MAP (
	clk           => clk,
	reset_p       => reset_p,
	start         => dw_start,
	input         => input,
	filter_values => x"010101010101010101",
	bias          => "00000000000000000000000000111000",
	scale         => "00000000000000000000000000000001",
	busy          => OPEN,
	done          => dw_done,
	output        => dw_output
	);

	PWConv : Conv
	GENERIC
	MAP (
	INPUT_WIDTH    => INPUT_WIDTH,
	INPUT_HEIGHT   => INPUT_HEIGHT,
	INPUT_CHANNELS => 1,
	KERNEL_HEIGHT  => 1,
	KERNEL_WIDTH   => 1,
	KERNEL_DEPTH   => 1,
	STRIDE         => 1,
	ZERO_PADDING   => 0,
	IO_SIZE        => IO_SIZE,
	INTERNAL_SIZE  => INTERNAL_SIZE
	)
	PORT
	MAP (
	clk           => clk,
	reset_p       => reset_p,
	start         => dw_done,
	input         => dw_output,
	filter_values => x"01",
	bias          => "00000000000000000000000000111000",
	scale         => "00000000000000000000000000000001",
	busy          => OPEN,
	done          => pw_done,
	output        => pw_output
	);

	Dense_comp : FullyConnect
	GENERIC
	MAP (
	INPUT_NUM     => INPUT_WIDTH * INPUT_HEIGHT,
	NEURON_NUM    => 1,
	IO_SIZE       => IO_SIZE,
	INTERNAL_SIZE => INTERNAL_SIZE
	)
	PORT
	MAP (
	clk           => clk,
	reset_p       => reset_p,
	start         => pw_done,
	input         => pw_output,
	weight_values => x"010101010101010101",
	bias_values   => x"01000001",
	scale_values  => x"00000001",
	busy          => OPEN,
	done          => dense_done,
	output        => dense_output
	);
	PROCESS (clk, reset_p)
	BEGIN
		IF reset_p = '1' THEN
			busy          <= '0';
			done          <= '0';
			output_enable <= '1';
			output_signal <= (OTHERS => '0');
		ELSIF RISING_EDGE(clk) THEN
			CASE state_machine IS
				WHEN Idle =>

					IF start = '1' THEN
						busy          <= '1';
						done          <= '0';
						output_enable <= '0';
						dw_start      <= '1';
						state_machine <= Layers;
					END IF;

				WHEN Layers =>
					dw_start <= '0';

					IF dense_done = '1' THEN
						state_machine <= Dequantize;
					END IF;

				WHEN Dequantize =>
					output_signal <= dense_output;
					output_enable <= '1';
					state_machine <= Finished;

				WHEN Finished =>
					busy <= '0';
					done <= '1';

					IF start = '0' THEN
						state_machine <= Idle;
					END IF;

			END CASE;
		END IF;
	END PROCESS;

END CNN_arch;
