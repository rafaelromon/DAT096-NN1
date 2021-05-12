-----------------------------------------------------
-- Title: Conv.vhdl
-- Author: Rafael Romon/NN-1
-- DAT096 - spring 2021
-----------------------------------------------------
-- Description:
-- TODO:
-- Implement Relu
-- Multiply by Scale values
-- Truncate
-----------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
ENTITY Conv IS
	GENERIC
	(
		INPUT_WIDTH   : INTEGER := 128;
		INPUT_HEIGHT  : INTEGER := 128;
		KERNEL_HEIGHT : INTEGER := 1;
		KERNEL_WIDTH  : INTEGER := 1;
		KERNEL_DEPTH  : INTEGER := 1;
		STRIDE        : INTEGER := 1;
		IN_SIZE       : INTEGER := 8;
		OUT_SIZE      : INTEGER := 32
	);
	PORT
	(
		clk           : IN  STD_LOGIC;
		reset_p       : IN  STD_LOGIC;
		start         : IN  STD_LOGIC;
		input         : IN  STD_LOGIC_VECTOR((INPUT_WIDTH * INPUT_HEIGHT * IN_SIZE) - 1 DOWNTO 0);
		filter_values : IN  STD_LOGIC_VECTOR ((KERNEL_HEIGHT * KERNEL_WIDTH * KERNEL_DEPTH * IN_SIZE) - 1 DOWNTO 0);
		bias_values   : IN  STD_LOGIC_VECTOR(OUT_SIZE - 1 DOWNTO 0);
		busy          : OUT STD_LOGIC;
		done          : OUT STD_LOGIC;
		output        : OUT STD_LOGIC_VECTOR(((INPUT_WIDTH * INPUT_HEIGHT * OUT_SIZE)/STRIDE) - 1 DOWNTO 0)
	);
END Conv;

ARCHITECTURE Conv_arch OF Conv IS

	TYPE states IS (Idle, WaitWindow, WaitNeuron, SaveOutput);
	SIGNAL state_machine : states := Idle;

	SIGNAL output_signal : STD_LOGIC_VECTOR(((INPUT_WIDTH * INPUT_HEIGHT * OUT_SIZE)/STRIDE) - 1 DOWNTO 0);
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

	SIGNAL window_start : STD_LOGIC;
	SIGNAL window_move  : STD_LOGIC;
	SIGNAL window_busy  : STD_LOGIC;
	SIGNAL window_done  : STD_LOGIC;

	COMPONENT KernelWindow
		GENERIC
		(
			INPUT_WIDTH    : INTEGER := 128;
			INPUT_HEIGHT   : INTEGER := 128;
			INPUT_CHANNELS : INTEGER := 8;
			KERNEL_WIDTH   : INTEGER := 1;
			KERNEL_HEIGHT  : INTEGER := 1;
			KERNEL_DEPTH   : INTEGER := 1;
			STRIDE         : INTEGER := 1;
			INTEGER_SIZE   : INTEGER := 8
		);
		PORT
		(
			clk     : IN  STD_LOGIC;
			reset_p : IN  STD_LOGIC;
			start   : IN  STD_LOGIC;
			move    : IN  STD_LOGIC;
			input   : IN  STD_LOGIC_VECTOR((INPUT_WIDTH * INPUT_HEIGHT * INPUT_CHANNELS * INTEGER_SIZE) - 1 DOWNTO 0);
			busy    : OUT STD_LOGIC;
			done    : OUT STD_LOGIC;
			output  : OUT STD_LOGIC_VECTOR((KERNEL_HEIGHT * KERNEL_WIDTH * KERNEL_DEPTH * INTEGER_SIZE) - 1 DOWNTO 0)
		);
	END COMPONENT KernelWindow;

	SIGNAL neuron_start  : STD_LOGIC := '0';
	SIGNAL neuron_input  : STD_LOGIC_VECTOR(KERNEL_HEIGHT * KERNEL_WIDTH * KERNEL_DEPTH * IN_SIZE - 1 DOWNTO 0);
	SIGNAL neuron_busy   : STD_LOGIC := '0';
	SIGNAL neuron_done   : STD_LOGIC := '0';
	SIGNAL neuron_output : STD_LOGIC_VECTOR(OUT_SIZE - 1 DOWNTO 0);

	COMPONENT Neuron IS
		GENERIC
		(
			KERNEL_SIZE : INTEGER := 9;
			IN_SIZE     : INTEGER := 8;
			OUT_SIZE    : INTEGER := 32
		);
		PORT
		(
			clk           : IN  STD_LOGIC;
			reset_p       : IN  STD_LOGIC;
			enable        : IN  STD_LOGIC;
			input         : IN  STD_LOGIC_VECTOR((KERNEL_SIZE * IN_SIZE) - 1 DOWNTO 0);
			filter_values : IN  STD_LOGIC_VECTOR ((KERNEL_SIZE * IN_SIZE) - 1 DOWNTO 0);
			bias          : IN  STD_LOGIC_VECTOR(OUT_SIZE - 1 DOWNTO 0);
			busy          : OUT STD_LOGIC;
			done          : OUT STD_LOGIC;
			output        : OUT STD_LOGIC_VECTOR(OUT_SIZE - 1 DOWNTO 0)
		);
	END COMPONENT;
BEGIN

	output_buff : Reg
	GENERIC
	MAP(
	SIG_WIDTH => INPUT_WIDTH * INPUT_HEIGHT * OUT_SIZE
	)
	PORT MAP
	(
		clk     => clk,
		reset_p => reset_p,
		enable  => output_enable,
		input   => output_signal,
		output  => output
	);

	KernelWindow_i : KernelWindow
	GENERIC
	MAP (
	INPUT_WIDTH    => INPUT_WIDTH,
	INPUT_HEIGHT   => INPUT_HEIGHT,
	INPUT_CHANNELS => KERNEL_DEPTH,
	KERNEL_WIDTH   => KERNEL_WIDTH,
	KERNEL_HEIGHT  => KERNEL_HEIGHT,
	KERNEL_DEPTH   => KERNEL_DEPTH,
	STRIDE         => STRIDE,
	INTEGER_SIZE   => IN_SIZE
	)
	PORT
	MAP (
	clk     => clk,
	reset_p => reset_p,
	start   => window_start,
	move    => window_move,
	input   => input,
	busy    => window_busy,
	done    => window_done,
	output  => neuron_input
	);

	neuron_comp : Neuron
	GENERIC
	MAP(
	KERNEL_SIZE => KERNEL_HEIGHT * KERNEL_WIDTH * KERNEL_DEPTH,
	IN_SIZE     => IN_SIZE,
	OUT_SIZE    => OUT_SIZE
	)
	PORT
	MAP(
	clk           => clk,
	reset_p       => reset_p,
	enable        => neuron_start,
	input         => neuron_input,
	filter_values => filter_values,
	bias          => bias_values,
	busy          => neuron_busy,
	done          => neuron_done,
	output        => neuron_output
	);

	PROCESS (clk)
		VARIABLE output_index : INTEGER := INPUT_HEIGHT * INPUT_WIDTH;
	BEGIN
		IF reset_p = '1' THEN
			done          <= '0';
			output_enable <= '1';
			neuron_start  <= '0';
			window_start  <= '0';
			window_move   <= '0';
			output_signal <= (OTHERS => '0');

		ELSIF RISING_EDGE(clk) THEN
			CASE state_machine IS
				WHEN Idle =>
					output_index := INPUT_HEIGHT * INPUT_WIDTH;
					busy <= '0';

					IF window_done = '1' THEN
						done <= '1';
					END IF;
					IF start = '1' THEN
						window_start  <= '1';
						busy          <= '1';
						done          <= '0';
						output_enable <= '0';
						state_machine <= WaitWindow;
					END IF;
				WHEN WaitWindow =>
					window_start <= '0';
					window_move  <= '0';

					IF window_busy = '0' THEN
						neuron_start  <= '1';
						state_machine <= WaitNeuron;
					END IF;
				WHEN WaitNeuron =>
					IF neuron_done = '1' THEN -- all neurons finish at the same time
						neuron_start  <= '0';
						state_machine <= SaveOutput;
					END IF;
				WHEN SaveOutput =>

					output_signal((OUT_SIZE * output_index) - 1 DOWNTO OUT_SIZE * (output_index - 1)) <= neuron_output;

					IF window_done = '1' THEN
						output_enable <= '1';
						state_machine <= Idle;
					ELSE
						window_move <= '1';
						output_index := output_index - 1;
						state_machine <= WaitWindow;
					END IF;
			END CASE;
		END IF;
	END PROCESS;
END Conv_arch;
