-----------------------------------------------------
-- Title: Conv.vhdl
-- Author: Rafael Romon/NN-1
-- DAT096 - spring 2021
-----------------------------------------------------
-- Description:
-- completes a convolution for a single filter
-----------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
ENTITY Conv IS
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
END Conv;

ARCHITECTURE Conv_arch OF Conv IS

	TYPE states IS (Idle, WaitWindow, WaitNeuron, Finished);
	SIGNAL state_machine : states := Idle;

	-----
	-- Reg component and signals
	-----

	SIGNAL output_signal : STD_LOGIC_VECTOR(((INPUT_WIDTH * INPUT_HEIGHT * IO_SIZE)/STRIDE) - 1 DOWNTO 0);
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

	-----
	-- KernelWindow component and signals
	-----

	SIGNAL window_start  : STD_LOGIC;
	SIGNAL window_move  : STD_LOGIC;
	SIGNAL window_output : STD_LOGIC_VECTOR(KERNEL_HEIGHT * KERNEL_WIDTH * KERNEL_DEPTH * IO_SIZE - 1 DOWNTO 0);
	SIGNAL window_busy   : STD_LOGIC;
	SIGNAL window_done   : STD_LOGIC;

	COMPONENT KernelWindow
		GENERIC
		(
			INPUT_WIDTH    : INTEGER := 9;
			INPUT_HEIGHT   : INTEGER := 9;
			INPUT_CHANNELS : INTEGER := 1;
			KERNEL_WIDTH   : INTEGER := 1;
			KERNEL_HEIGHT  : INTEGER := 1;
			KERNEL_DEPTH   : INTEGER := 1;
			ZERO_PADDING   : INTEGER := 0;
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

	-----
	-- Neuron component and signals
	-----

	SIGNAL neuron_start  : STD_LOGIC := '0';
	SIGNAL neuron_busy   : STD_LOGIC := '0';
	SIGNAL neuron_done   : STD_LOGIC := '0';
	SIGNAL neuron_output : STD_LOGIC_VECTOR(IO_SIZE - 1 DOWNTO 0);

	COMPONENT Neuron
		GENERIC
		(
			KERNEL_HEIGHT : INTEGER := 3;
			KERNEL_WIDTH  : INTEGER := 3;
			KERNEL_DEPTH  : INTEGER := 1;
			IO_SIZE       : INTEGER := 8;
			INTERNAL_SIZE : INTEGER := 32
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
BEGIN

	output_buff : Reg
	GENERIC
	MAP(
	SIG_WIDTH => (INPUT_WIDTH * INPUT_HEIGHT * IO_SIZE)/STRIDE
	)
	PORT MAP
	(
		clk     => clk,
		reset_p => reset_p,
		enable  => output_enable,
		input   => output_signal,
		output  => output
	);

	KernelWindow_comp : KernelWindow
	GENERIC
	MAP (
	INPUT_WIDTH    => INPUT_WIDTH,
	INPUT_HEIGHT   => INPUT_HEIGHT,
	INPUT_CHANNELS => INPUT_CHANNELS,
	KERNEL_WIDTH   => KERNEL_WIDTH,
	KERNEL_HEIGHT  => KERNEL_HEIGHT,
	KERNEL_DEPTH   => KERNEL_DEPTH,
	ZERO_PADDING   => ZERO_PADDING,
	STRIDE         => STRIDE,
	INTEGER_SIZE   => IO_SIZE
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
	output  => window_output
	);
	neuron_comp : Neuron
	GENERIC
	MAP (
	KERNEL_HEIGHT => KERNEL_HEIGHT,
	KERNEL_WIDTH  => KERNEL_WIDTH,
	KERNEL_DEPTH  => KERNEL_DEPTH,
	IO_SIZE       => IO_SIZE,
	INTERNAL_SIZE => INTERNAL_SIZE
	)
	PORT
	MAP (
	clk           => clk,
	reset_p       => reset_p,
	start         => neuron_start,
	input         => window_output,
	filter_values => filter_values,
	bias          => bias,
	scale         => scale,
	busy          => neuron_busy,
	done          => neuron_done,
	output        => neuron_output
	);
	PROCESS (clk)
		VARIABLE output_index : INTEGER := (INPUT_WIDTH * INPUT_HEIGHT)/STRIDE;
	BEGIN
		IF reset_p = '1' THEN
			busy          <= '0';
			done          <= '0';
			window_start  <= '0';
			output_enable <= '1';
			output_signal <= (OTHERS => '0');

		ELSIF RISING_EDGE(clk) THEN

			CASE state_machine IS
				WHEN Idle =>
					IF start = '1' THEN
						output_index := (INPUT_WIDTH * INPUT_HEIGHT)/STRIDE;
						window_start  <= '1';
						output_enable <= '0';
						busy          <= '1';
						done          <= '0';
						state_machine <= WaitWindow;
					END IF;

				WHEN WaitWindow =>
				    window_start <= '0';
				    window_move  <= '0';
				    
                    IF window_done = '1' THEN
                        output_enable <= '1';
                        state_machine <= Finished;
				    ELSIF window_busy = '0' and window_start = '0' and window_move = '0' THEN
                        neuron_start <= '1';
                        state_machine <= WaitNeuron;
				    END IF;
				    
				WHEN WaitNeuron =>				                    
                    neuron_start <= '0';
                    
					IF neuron_done = '1' THEN
						output_signal((IO_SIZE * output_index) - 1 DOWNTO IO_SIZE * (output_index - 1)) <= neuron_output;                                               
                        output_index := output_index - 1;
                        window_move <= '1';
                        state_machine <= WaitWindow;

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
END Conv_arch;
