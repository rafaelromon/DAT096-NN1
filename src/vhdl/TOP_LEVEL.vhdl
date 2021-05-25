-----------------------------------------------------
-- Title: TOP_LEVEL.vhdl
-- Author: Rafael Romon/NN-1
-- DAT096 - spring 2021
-----------------------------------------------------
-- Description:
-- This entity dictates the top level
-- architecture of the entire system
-- TODO:
-- * remove debouncers
-- * integrate bram controller
-- * update uart implementation
-- * implement uart receive
-----------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

LIBRARY UNISIM;
USE UNISIM.Vcomponents.ALL;

ENTITY TOP_LEVEL IS
	GENERIC
	(
		INPUT_WIDTH  : INTEGER := 3;
		INPUT_HEIGHT : INTEGER := 3;
		INTEGER_SIZE : INTEGER := 8;
		RESULT_SIZE  : INTEGER := 8
	);
	PORT
	(
		SYSCLK_P    : IN  STD_LOGIC;
		SYSCLK_N    : IN  STD_LOGIC;
		CPU_RESET   : IN  STD_LOGIC;
		GPIO_SW_N   : IN  STD_LOGIC;
		USB_UART_TX : OUT STD_LOGIC;
		GPIO_LED_0  : OUT STD_LOGIC;
		GPIO_LED_1  : OUT STD_LOGIC;
		GPIO_LED_2  : OUT STD_LOGIC;
		GPIO_LED_3  : OUT STD_LOGIC
	);
END TOP_LEVEL;

ARCHITECTURE TOP_LEVEL_arch OF TOP_LEVEL IS

	TYPE states IS (Idle, Working, SendResult, WaitUART);
	SIGNAL state_machine : states := Idle;
	SIGNAL clk           : STD_LOGIC;
	SIGNAL reset_p       : STD_LOGIC := '0';
	SIGNAL start         : STD_LOGIC := '0';

	-----
	-- image_buffer component and signals
	-----

	SIGNAL img_cont_start : STD_LOGIC;
	SIGNAL img_cont_busy  : STD_LOGIC;
	SIGNAL img_cont_done  : STD_LOGIC;

	COMPONENT IMG_BUFFER_CONTROLLER
		GENERIC
		(
			DATA_HEIGHT  : INTEGER := 3;
			DATA_WIDTH   : INTEGER := 3;
			INTEGER_SIZE : INTEGER := 8;
			WORD_SIZE    : INTEGER := 72;
			BUFFER_DEPTH : INTEGER := 3;
			ADDR_WIDTH   : INTEGER := 3
		);
		PORT
		(
			clk     : IN  STD_LOGIC;
			reset_p : IN  STD_LOGIC;
			start   : IN  STD_LOGIC;
			busy    : OUT STD_LOGIC;
			done    : OUT STD_LOGIC;
			output  : OUT STD_LOGIC_VECTOR((DATA_WIDTH * DATA_HEIGHT * INTEGER_SIZE) - 1 DOWNTO 0)
		);
	END COMPONENT IMG_BUFFER_CONTROLLER;

	SIGNAL cnn_start  : STD_LOGIC := '0';
	SIGNAL cnn_input  : STD_LOGIC_VECTOR(INPUT_HEIGHT * INPUT_WIDTH * INTEGER_SIZE - 1 DOWNTO 0);
	SIGNAL cnn_busy   : STD_LOGIC;
	SIGNAL cnn_done   : STD_LOGIC;
	SIGNAL cnn_output : STD_LOGIC_VECTOR(RESULT_SIZE - 1 DOWNTO 0);

	COMPONENT CNN
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
	END COMPONENT CNN;
	SIGNAL uart_start : STD_LOGIC                    := '0';
	SIGNAL uart_msg   : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
	SIGNAL uart_busy  : STD_LOGIC;
	SIGNAL uart_done  : STD_LOGIC;

	COMPONENT UART_TX IS
		PORT
		(
			clk       : IN  STD_LOGIC;
			TX_DV     : IN  STD_LOGIC;
			TX_Byte   : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
			TX_Active : OUT STD_LOGIC;
			TX_Serial : OUT STD_LOGIC;
			TX_Done   : OUT STD_LOGIC
		);
	END COMPONENT UART_TX;
BEGIN

	-- LVDS input to internal single
	CLK_IBUFDS : IBUFDS
	GENERIC
	MAP(
	IOSTANDARD => "DEFAULT"
	)
	PORT MAP
	(
		I  => SYSCLK_P,
		IB => SYSCLK_N,
		O  => clk
	);

	IMG_BUFFER_CONTROLLER_comp : IMG_BUFFER_CONTROLLER
	GENERIC
	MAP (
	DATA_HEIGHT  => INPUT_HEIGHT,
	DATA_WIDTH   => INPUT_WIDTH,
	INTEGER_SIZE => INTEGER_SIZE,
	WORD_SIZE    => 72,
	BUFFER_DEPTH => 3,
	ADDR_WIDTH   => 3
	)
	PORT
	MAP (
	clk     => clk,
	reset_p => reset_p,
	start   => img_cont_start,
	busy    => img_cont_busy,
	done    => img_cont_done,
	output  => cnn_input
	);

	CNN_comp : CNN
	PORT
	MAP (
	clk     => clk,
	reset_p => reset_p,
	start   => img_cont_done,
	input   => cnn_input,
	busy    => cnn_busy,
	done    => cnn_done,
	output  => cnn_output
	);

	UART_TX_comp : UART_TX
	PORT
	MAP
	(
	clk       => clk,
	TX_DV     => uart_start,
	TX_Byte   => uart_msg,
	TX_Active => uart_busy,
	TX_Serial => USB_UART_TX,
	TX_Done   => uart_done
	);

	LED_indicator_process : PROCESS (clk)
	BEGIN
		IF CPU_RESET = '1' THEN
			GPIO_LED_0 <= '1';
			GPIO_LED_1 <= '1';
			GPIO_LED_2 <= '1';
			GPIO_LED_3 <= '1';

		ELSIF RISING_EDGE(clk) THEN

			CASE state_machine IS
				WHEN Idle =>
					GPIO_LED_0 <= '1';
					GPIO_LED_1 <= '0';
					GPIO_LED_2 <= '0';
					GPIO_LED_3 <= '0';

				WHEN Working =>
					GPIO_LED_0 <= '0';
					GPIO_LED_1 <= '1';
					GPIO_LED_2 <= '0';
					GPIO_LED_3 <= '0';

				WHEN SendResult =>

					GPIO_LED_0 <= '0';
					GPIO_LED_1 <= '0';
					GPIO_LED_2 <= '1';
					GPIO_LED_3 <= '0';

				WHEN WaitUART =>

					GPIO_LED_0 <= '0';
					GPIO_LED_1 <= '0';
					GPIO_LED_2 <= '1';
					GPIO_LED_3 <= '0';

			END CASE;
		END IF;
	END PROCESS LED_indicator_process;

	-- Purpose: Control state machine
	TOP_LEVEL_process : PROCESS (clk, CPU_RESET)
		VARIABLE start_flag : STD_LOGIC := '0';
		VARIABLE msg_count  : INTEGER;
	BEGIN
		IF CPU_RESET = '1' THEN
			start_flag := '0';
			reset_p       <= '1';
			state_machine <= Idle;

		ELSIF RISING_EDGE(clk) THEN
			CASE state_machine IS
				WHEN Idle =>
					reset_p <= '0';

					IF GPIO_SW_N = '1' THEN
						start_flag := '1';

					ELSIF GPIO_SW_N = '0' AND start_flag = '1' THEN
						start_flag := '0';
						img_cont_start <= '1';
						state_machine  <= Working;

					END IF;

				WHEN Working =>
					img_cont_start <= '0';

					IF cnn_done = '1' THEN
						msg_count := INTEGER_SIZE/8; -- see how many messages can be sent
						state_machine <= SendResult;

					END IF;

				WHEN SendResult =>

					uart_msg <= cnn_output(INTEGER_SIZE * msg_count - 1 DOWNTO INTEGER_SIZE * msg_count - 8);

					uart_start <= '1';
					msg_count := msg_count - 1;
					state_machine <= WaitUART;

				WHEN WaitUART =>
					uart_start <= '0';

					IF uart_done = '1' THEN
						IF msg_count = 0 THEN
							state_machine <= Idle;

						ELSE
							state_machine <= SendResult;

						END IF;
					END IF;

			END CASE;
		END IF;
	END PROCESS TOP_LEVEL_process;
END TOP_LEVEL_arch;
