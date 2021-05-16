-----------------------------------------------------
-- Title: IMG_BUFFER_CONT.vhdl
-- Author: Rafael Romon/NN-1
-- DAT096 - spring 2021
-----------------------------------------------------
-- Description:
-- gets image from image buffer when start is high
-- busy signal indicates the controller is reading
-----------------------------------------------------
-- TODO:
-- * Allow reading specific position in buffers
-- * Allow writing to position
-----------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY IMG_BUFFER_CONTROLLER IS
	GENERIC
	(
		DATA_HEIGHT  : INTEGER := 3;
		DATA_WIDTH   : INTEGER := 3;
		INTEGER_SIZE : INTEGER := 8;
		WORD_SIZE    : INTEGER := 72;
		BUFFER_DEPTH : INTEGER := 4;
		ADDR_WIDTH   : INTEGER := 3
	);
	PORT
	(
		clk     : IN  STD_LOGIC; -- clock signal
		reset_p : IN  STD_LOGIC; -- reset signal active high
		start   : IN  STD_LOGIC; -- signal to start reading new image
		busy    : OUT STD_LOGIC; -- signal indicating controller is busy reading new image
		done    : OUT STD_LOGIC;
		output  : OUT STD_LOGIC_VECTOR((DATA_WIDTH * DATA_HEIGHT * INTEGER_SIZE) - 1 DOWNTO 0) -- output image
	);
END IMG_BUFFER_CONTROLLER;

ARCHITECTURE IMG_BUFFER_CONTROLLER_arch OF IMG_BUFFER_CONTROLLER IS
	TYPE states IS (Idle, Reading, Finished);
	SIGNAL state_machine : states := Idle;

	-----
	-- image_buffer component and signals
	-----

	SIGNAL addra : STD_LOGIC_VECTOR (ADDR_WIDTH - 1 DOWNTO 0);
	SIGNAL douta : STD_LOGIC_VECTOR (WORD_SIZE - 1 DOWNTO 0);
	SIGNAL addrb : STD_LOGIC_VECTOR (ADDR_WIDTH - 1 DOWNTO 0);
	SIGNAL doutb : STD_LOGIC_VECTOR (WORD_SIZE - 1 DOWNTO 0);

	COMPONENT image_buffer
		PORT
		(
			clka  : IN  STD_LOGIC;
			ena   : IN  STD_LOGIC;
			wea   : IN  STD_LOGIC_VECTOR (0 TO 0);
			addra : IN  STD_LOGIC_VECTOR (ADDR_WIDTH - 1 DOWNTO 0);
			dina  : IN  STD_LOGIC_VECTOR (WORD_SIZE - 1 DOWNTO 0);
			douta : OUT STD_LOGIC_VECTOR (WORD_SIZE - 1 DOWNTO 0);
			clkb  : IN  STD_LOGIC;
			enb   : IN  STD_LOGIC;
			web   : IN  STD_LOGIC_VECTOR (0 TO 0);
			addrb : IN  STD_LOGIC_VECTOR (ADDR_WIDTH - 1 DOWNTO 0);
			dinb  : IN  STD_LOGIC_VECTOR (WORD_SIZE - 1 DOWNTO 0);
			doutb : OUT STD_LOGIC_VECTOR (WORD_SIZE - 1 DOWNTO 0)
		);
	END COMPONENT image_buffer;

	-----
	-- Reg component and signals
	-----

	SIGNAL output_signal : STD_LOGIC_VECTOR(DATA_WIDTH * DATA_HEIGHT * INTEGER_SIZE - 1 DOWNTO 0);
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
	SIG_WIDTH => DATA_WIDTH * DATA_HEIGHT * INTEGER_SIZE
	)
	PORT MAP
	(
		clk     => clk,
		reset_p => reset_p,
		enable  => output_enable,
		input   => output_signal,
		output  => output
	);

	image_buffer_comp : image_buffer
	PORT
	MAP(
	clka  => clk,
	ena   => '1',
	wea   => "0",
	addra => addra,
	dina => (OTHERS => '0'),
	douta => douta,
	clkb  => clk,
	enb   => '1',
	web   => "0",
	addrb => addrb,
	dinb => (OTHERS => '0'),
	doutb => doutb
	);

	IMG_BUFFER_CONTROLLER_process : PROCESS (clk, reset_p)
		VARIABLE words_left : INTEGER;
		VARIABLE data_index : INTEGER;
		VARIABLE base_addr  : INTEGER := 1;
	BEGIN

		IF reset_p = '1' THEN
			base_addr := 1;
			busy          <= '0';
			done          <= '0';
			output_enable <= '1';
			output_signal <= (OTHERS => '0');
			addra         <= STD_LOGIC_VECTOR(to_unsigned(0, addra'length));
			addrb         <= STD_LOGIC_VECTOR(to_unsigned(1, addrb'length));

		ELSIF RISING_EDGE(clk) THEN
			CASE state_machine IS
				WHEN Idle =>

					IF start = '1' THEN
						words_left := (DATA_HEIGHT * DATA_WIDTH * INTEGER_SIZE)/WORD_SIZE;
						output_enable <= '0';
						done          <= '0';
						busy          <= '1';
						state_machine <= Reading;
					END IF;

				WHEN Reading =>

					output_signal(words_left * WORD_SIZE - 1 DOWNTO words_left * WORD_SIZE - WORD_SIZE) <= douta;

					addra <= STD_LOGIC_VECTOR(to_unsigned(base_addr, addra'length));
					addrb <= STD_LOGIC_VECTOR(to_unsigned(base_addr + 1, addrb'length));

					-- If more than one word left use second interface
					IF words_left > 1 THEN
						output_signal((words_left * WORD_SIZE - WORD_SIZE) - 1 DOWNTO (words_left * WORD_SIZE - WORD_SIZE*2)) <= doutb;
						words_left := words_left - 2;
						base_addr  := base_addr + 2;
					ELSE
						base_addr := base_addr + 1;
					END IF;

					-- if words_left is 1 or 2 then it has finished
					IF words_left < 3 THEN
						output_enable <= '1';
						state_machine <= Finished;

						IF base_addr > BUFFER_DEPTH THEN -- wrap around buffer
							base_addr := 0;
							-- preload address 1 and 2 to reduce delay
							addra <= STD_LOGIC_VECTOR(to_unsigned(0, addra'length));
							addrb <= STD_LOGIC_VECTOR(to_unsigned(1, addrb'length));
						END IF;
					END IF;
				WHEN Finished =>
					busy <= '0';
					done <= '1';

					IF start = '0' THEN
						state_machine <= Idle;
					END IF;

			END CASE;
		END IF;
	END PROCESS IMG_BUFFER_CONTROLLER_process;
END IMG_BUFFER_CONTROLLER_arch;
