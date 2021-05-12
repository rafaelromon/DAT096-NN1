-----------------------------------------------------
-- Title: LINE_BUFF.vhdl
-- Author: Rafael Romon/NN-1
-- DAT096 - spring 2021
-----------------------------------------------------
-- Description:
-- Implements line buffers controlled by a state machine that output a kernel
-- window
-- TODO:
-- Channels are not implemented
-----------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY LINE_BUFF IS
	GENERIC
	(
		INPUT_WIDTH    : INTEGER := 128;
		INPUT_HEIGHT   : INTEGER := 128;
		INPUT_CHANNELS : INTEGER := 8;
		KERNEL_WIDTH   : INTEGER := 1;
		KERNEL_HEIGHT  : INTEGER := 1;
		STRIDE         : INTEGER := 1;
		INTEGER_SIZE   : INTEGER := 8
	);
	PORT
	(
		clk     : IN  STD_LOGIC;
		reset_p : IN  STD_LOGIC;
		start   : IN  STD_LOGIC; -- start producing windows from input
		move    : IN  STD_LOGIC; -- move to next window on high
		input   : IN  STD_LOGIC_VECTOR((INPUT_WIDTH * INPUT_HEIGHT * INTEGER_SIZE) - 1 DOWNTO 0); -- layer input
		busy    : OUT STD_LOGIC; -- low when waiting for input
		done    : OUT STD_LOGIC; -- high when finished moving through entire input
		output  : OUT STD_LOGIC_VECTOR((KERNEL_HEIGHT * KERNEL_WIDTH * INTEGER_SIZE) - 1 DOWNTO 0) -- kernel input
	);
END LINE_BUFF;

ARCHITECTURE LINE_BUFF_arch OF LINE_BUFF IS

	TYPE states IS (Idle, LoadRows, WaitRegs, OutputKernel, WaitNext);
	SIGNAL state_machine : states := Idle;

	TYPE INPUT_BUFF IS ARRAY (0 TO KERNEL_HEIGHT - 1) OF STD_LOGIC_VECTOR(INTEGER_SIZE * INPUT_WIDTH - 1 DOWNTO 0);
	SIGNAL line_in_array  : INPUT_BUFF;
	SIGNAL line_out_array : INPUT_BUFF;
	SIGNAL output_signal  : STD_LOGIC_VECTOR((KERNEL_HEIGHT * KERNEL_WIDTH * INTEGER_SIZE) - 1 DOWNTO 0);

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
	SIG_WIDTH => INTEGER_SIZE * KERNEL_WIDTH * KERNEL_HEIGHT
	)
	PORT MAP
	(
		clk     => clk,
		reset_p => reset_p,
		enable  => '1',
		input   => output_signal,
		output  => output
	);

	buff : FOR i IN 0 TO KERNEL_HEIGHT - 1 GENERATE
		line_buff : Reg
		GENERIC
		MAP(
		SIG_WIDTH => INTEGER_SIZE * INPUT_WIDTH
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
			base_row    := INPUT_HEIGHT;
			base_column := INPUT_WIDTH;
			done          <= '0';
			busy          <= '0';
			output_signal <= (OTHERS => '0');
		ELSIF RISING_EDGE(clk) THEN

			CASE state_machine IS
				WHEN Idle =>
					base_row    := INPUT_HEIGHT;
					base_column := INPUT_WIDTH;

					IF start = '1' THEN
						state_machine <= LoadRows;
						done          <= '0';
					END IF;

				WHEN LoadRows =>
					busy <= '1';

					FOR row IN 0 TO KERNEL_HEIGHT - 1 LOOP
						line_in_array(row) <= input((INTEGER_SIZE * INPUT_WIDTH * (base_row - row)) - 1 DOWNTO (INTEGER_SIZE * INPUT_WIDTH * (base_row - row - 1)));
					END LOOP;

					state_machine <= WaitRegs;

				WHEN WaitRegs =>
					state_machine <= OutputKernel;

				WHEN OutputKernel =>
					busy <= '1';
					FOR row IN 0 TO KERNEL_HEIGHT - 1 LOOP
						output_signal((KERNEL_WIDTH * (KERNEL_HEIGHT - row) * INTEGER_SIZE) - 1 DOWNTO KERNEL_WIDTH * (KERNEL_HEIGHT - (row + 1)) * INTEGER_SIZE)
						<= line_out_array(row)(base_column * INTEGER_SIZE - 1 DOWNTO (base_column - KERNEL_WIDTH) * INTEGER_SIZE);
					END LOOP;
					state_machine <= WaitNext;
				WHEN WaitNext =>
					busy <= '0';

					IF base_row - (KERNEL_HEIGHT + STRIDE) >= 0 THEN
						IF move = '1' THEN
							IF base_column - (KERNEL_WIDTH + STRIDE) >= 0 THEN
								base_column := base_column - STRIDE;

								state_machine <= OutputKernel;
							ELSE
								base_column := INPUT_WIDTH;
								base_row    := base_row - STRIDE;

								state_machine <= LoadRows;
							END IF;
						END IF;
					ELSE
						done          <= '1';
						state_machine <= Idle;					
					END IF;
			END CASE;
		END IF;
	END PROCESS;
END LINE_BUFF_arch;
