-----------------------------------------------------
-- Title: KernelWindow.vhdl
-- Author: Rafael Romon/NN-1
-- DAT096 - spring 2021
-----------------------------------------------------
-- Description:
-- Implements line buffers controlled by a state machine that output a kernel
-- window
-- TODO:
-- * check that start is low before going to idle
-- * add ready signal to simplify Conv State Machine
-----------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY KernelWindow IS
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
		start   : IN  STD_LOGIC;                                                                                   -- start producing windows from input
		move    : IN  STD_LOGIC;                                                                                   -- move to next window on high
		input   : IN  STD_LOGIC_VECTOR((INPUT_WIDTH * INPUT_HEIGHT * INPUT_CHANNELS * INTEGER_SIZE) - 1 DOWNTO 0); -- layer input
		busy    : OUT STD_LOGIC;                                                                                   -- low when waiting for input
		done    : OUT STD_LOGIC;                                                                                   -- high when finished moving through entire input
		output  : OUT STD_LOGIC_VECTOR((KERNEL_HEIGHT * KERNEL_WIDTH * KERNEL_DEPTH * INTEGER_SIZE) - 1 DOWNTO 0)  -- kernel input
	);
END KernelWindow;

ARCHITECTURE KernelWindow_arch OF KernelWindow IS

	TYPE states IS (Idle, LoadRows, WaitRegs, OutputKernel, WaitNext);
	SIGNAL state_machine : states := Idle;

	-----
	-- Register component and signals
	-----

	TYPE INPUT_BUFF IS ARRAY (0 TO KERNEL_HEIGHT - 1) OF STD_LOGIC_VECTOR(INTEGER_SIZE * (INPUT_WIDTH + ZERO_PADDING * 2) * INPUT_CHANNELS - 1 DOWNTO 0);
	SIGNAL line_in_array  : INPUT_BUFF;
	SIGNAL line_out_array : INPUT_BUFF;
	SIGNAL output_signal  : STD_LOGIC_VECTOR((KERNEL_HEIGHT * KERNEL_WIDTH * KERNEL_DEPTH * INTEGER_SIZE) - 1 DOWNTO 0);

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
	SIG_WIDTH => INTEGER_SIZE * KERNEL_WIDTH * KERNEL_HEIGHT * KERNEL_DEPTH
	)
	PORT MAP
	(
		clk     => clk,
		reset_p => reset_p,
		enable  => '1',
		input   => output_signal,
		output  => output
	);

	-- creates a line buffer for each row
	row : FOR i IN 0 TO KERNEL_HEIGHT - 1 GENERATE
		KernelWindow : Reg
		GENERIC
		MAP(
		SIG_WIDTH => INTEGER_SIZE * (INPUT_WIDTH + ZERO_PADDING * 2) * KERNEL_DEPTH
		)
		PORT
		MAP
		(
		clk     => clk,
		reset_p => reset_p,
		enable  => '1',
		input   => line_in_array(i),
		output  => line_out_array(i)
		);
	END GENERATE;

	PROCESS (clk)
		VARIABLE base_row    : INTEGER := 0;
		VARIABLE base_column : INTEGER := INPUT_WIDTH;
	BEGIN
		IF reset_p = '1' THEN
			done          <= '0';
			busy          <= '0';
			output_signal <= (OTHERS => '0');

		ELSIF RISING_EDGE(clk) THEN
			CASE state_machine IS
				WHEN Idle =>
					base_row    := INPUT_HEIGHT + ZERO_PADDING * 2;
					base_column := INPUT_WIDTH + ZERO_PADDING * 2;

					IF start = '1' THEN
						busy          <= '1';
						done          <= '0';
						state_machine <= LoadRows;
					END IF;

				WHEN LoadRows =>

					FOR row IN 0 TO KERNEL_HEIGHT - 1 LOOP

						IF ZERO_PADDING > 0 THEN

							IF (base_row - row) > INPUT_HEIGHT + ZERO_PADDING OR (base_row - row) = ZERO_PADDING THEN
								line_in_array(row) <= (OTHERS => '0');
							ELSE -- TODO fix ZERO_PADDING
								line_in_array(row)(INTEGER_SIZE * (2 * ZERO_PADDING + INPUT_WIDTH) - 1 DOWNTO INTEGER_SIZE * (ZERO_PADDING + INPUT_WIDTH)) <= (OTHERS => '0');
								-- line_in_array(row)(INTEGER_SIZE*(ZERO_PADDING+INPUT_WIDTH) - 1 DOWNTO INTEGER_SIZE*ZERO_PADDING) <= (OTHERS => '1');
								line_in_array(row)(INTEGER_SIZE * (ZERO_PADDING + INPUT_WIDTH) - 1 DOWNTO INTEGER_SIZE * ZERO_PADDING) <= input((INTEGER_SIZE * INPUT_WIDTH * (base_row - row - ZERO_PADDING)) - 1 DOWNTO (INTEGER_SIZE * INPUT_WIDTH * (base_row - row - 1 - ZERO_PADDING)));
								line_in_array(row)(INTEGER_SIZE * ZERO_PADDING - 1 DOWNTO 0)                                           <= (OTHERS => '0');
							END IF;

						ELSE
							line_in_array(row) <= input((INTEGER_SIZE * INPUT_WIDTH * (base_row - row)) - 1 DOWNTO (INTEGER_SIZE * INPUT_WIDTH * (base_row - row - 1)));
						END IF;
					END LOOP;

					state_machine <= WaitRegs;

				WHEN WaitRegs => -- waits registers on line buffers to update
					state_machine <= OutputKernel;

				WHEN OutputKernel => -- slices line buffers to generate kernel window
					busy          <= '1';
					state_machine <= WaitNext;

					FOR row IN 0 TO KERNEL_HEIGHT - 1 LOOP
						output_signal((KERNEL_WIDTH * KERNEL_DEPTH * (KERNEL_HEIGHT - row) * INTEGER_SIZE) - 1 DOWNTO KERNEL_WIDTH * KERNEL_DEPTH * (KERNEL_HEIGHT - (row + 1)) * INTEGER_SIZE) <= line_out_array(row)(base_column * INTEGER_SIZE - 1 DOWNTO (base_column - KERNEL_WIDTH * KERNEL_DEPTH) * INTEGER_SIZE);
					END LOOP;

				WHEN WaitNext => -- waits to be told to move to next window
					busy <= '0';

					IF move = '1' THEN
						busy <= '1';

						-- checks to see if we can move another column
						IF base_column - (KERNEL_WIDTH * KERNEL_DEPTH + STRIDE) >= 0 THEN
							base_column := base_column - STRIDE;
							state_machine <= OutputKernel;

						ELSE
							-- checks to see if we can move another row
							IF base_row - (KERNEL_HEIGHT + STRIDE) >= 0 THEN
								base_column := INPUT_WIDTH + ZERO_PADDING * 2;
								base_row    := base_row - STRIDE;
								state_machine <= LoadRows;

							ELSE
								done          <= '1';
								state_machine <= Idle;
							END IF;
						END IF;
					END IF;
			END CASE;
		END IF;
	END PROCESS;
END KernelWindow_arch;
