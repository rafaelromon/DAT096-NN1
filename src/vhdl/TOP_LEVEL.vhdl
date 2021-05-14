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
	GENERIC (
		INPUT_WIDTH   : INTEGER := 3;
		INPUT_HEIGHT  : INTEGER := 3;
		INTEGER_SIZE  : INTEGER := 8;
		RESULT_SIZE   : INTEGER := 8
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

	TYPE states IS (Idle, LoadImage, ProcessImage, SendResult);
	SIGNAL state_machine : states := Idle;
	SIGNAL clk           : STD_LOGIC;
	SIGNAL reset_signal  : STD_LOGIC := '0';

	SIGNAL start_signal  : STD_LOGIC := '0';

	SIGNAL img_cont_start : STD_LOGIC := '1';
	SIGNAL img_cont_busy  : STD_LOGIC;
	SIGNAL img_cont_done  : STD_LOGIC;

	component IMG_BUFFER_CONTROLLER
	generic (
	  INPUT_WIDTH  : INTEGER := 3;
	  INPUT_HEIGHT : INTEGER := 3;
	  INTEGER_SIZE : INTEGER := 8;
	  WORD_SIZE    : INTEGER := 128;
	  IMAGE_DEPTH  : INTEGER := 128;
	  ADDR_WIDTH   : INTEGER := 11
	);
	port (
	  clk     : IN  STD_LOGIC;
	  reset_p : IN  STD_LOGIC;
	  start   : IN  STD_LOGIC;
	  busy    : OUT STD_LOGIC;
	  done    : OUT STD_LOGIC;
	  image   : OUT STD_LOGIC_VECTOR((INPUT_WIDTH * INPUT_HEIGHT * INTEGER_SIZE) - 1 DOWNTO 0)
	);
	end component IMG_BUFFER_CONTROLLER;


	SIGNAL cnn_start     : STD_LOGIC := '0';
	SIGNAL loaded_image  : STD_LOGIC_VECTOR(INPUT_HEIGHT*INPUT_WIDTH*INTEGER_SIZE-1 DOWNTO 0);
	SIGNAL cnn_busy      : STD_LOGIC;
	SIGNAL cnn_done  : STD_LOGIC;
	SIGNAL cnn_output    : STD_LOGIC_VECTOR(RESULT_SIZE-1 DOWNTO 0);

	component CNN
	generic (
  	INPUT_WIDTH   : INTEGER := 3;
  	INPUT_HEIGHT  : INTEGER := 3;
  	IO_SIZE       : INTEGER := 8;
  	INTERNAL_SIZE : INTEGER := 32
	);
	port (
  	clk     : IN  STD_LOGIC;
  	reset_p : IN  STD_LOGIC;
  	start   : IN  STD_LOGIC;
  	input   : IN  STD_LOGIC_VECTOR(INPUT_HEIGHT * INPUT_WIDTH * IO_SIZE - 1 DOWNTO 0);
  	busy    : OUT STD_LOGIC;
  	done    : OUT STD_LOGIC;
  	output  : OUT STD_LOGIC_VECTOR(IO_SIZE-1 DOWNTO 0)
	);
	end component CNN;


	SIGNAL uart_start   : STD_LOGIC                    := '0';
	SIGNAL uart_msg : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
	SIGNAL uart_busy : STD_LOGIC;
	SIGNAL uart_done : STD_LOGIC;

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

	IMG_BUFFER_CONTROLLER_i : IMG_BUFFER_CONTROLLER
	PORT MAP
	(
  	clk     => clk,
  	reset_p => reset_signal,
  	start   => img_cont_start,
  	busy    => img_cont_busy,
  	done    => img_cont_done,
  	image   => loaded_image
	);

	CNN_comp : CNN
	port map (
	  clk     => clk,
	  reset_p => reset_signal,
	  start   => cnn_start,
	  input   => loaded_image,
	  busy    => cnn_busy,
	  done    => cnn_done,
	  output  => cnn_output
	);


	UART_TX_comp : UART_TX -- Instantiate UART transmitter
	PORT MAP
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

				WHEN LoadImage =>
					GPIO_LED_0 <= '0';
					GPIO_LED_1 <= '1';
					GPIO_LED_2 <= '0';
					GPIO_LED_3 <= '0';

				WHEN ProcessImage =>

					GPIO_LED_0 <= '0';
					GPIO_LED_1 <= '0';
					GPIO_LED_2 <= '1';
					GPIO_LED_3 <= '0';

				WHEN SendResult =>

					GPIO_LED_0 <= '0';
					GPIO_LED_1 <= '0';
					GPIO_LED_2 <= '0';
					GPIO_LED_3 <= '1';

			END CASE;
		END IF;
	END PROCESS LED_indicator_process;

	-- Purpose: Control state machine
	TOP_LEVEL_process : PROCESS (clk, CPU_RESET)
		VARIABLE start_flag : STD_LOGIC := '0';
		VARIABLE sent_flag  : STD_LOGIC := '0';
	BEGIN
		IF CPU_RESET = '1' THEN
			reset_signal  <= '1';
			state_machine <= Idle;

		ELSIF RISING_EDGE(clk) THEN
			CASE state_machine IS
				WHEN Idle =>
				    reset_signal  <= '0';

					IF GPIO_SW_N = '1' THEN
						start_flag := '1';
					ELSIF GPIO_SW_N = '0' AND start_flag = '1' THEN
						start_flag := '0';
						state_machine <= LoadImage;
					END IF;

				WHEN LoadImage =>

					IF img_cont_start = '0' and img_cont_busy = '0' THEN
					   img_cont_start <= '1';
					ELSIF img_cont_busy = '1' THEN
					   img_cont_start <= '0';
					ELSIF img_cont_done = '1' THEN
					   state_machine <= ProcessImage;
					END IF;


				WHEN ProcessImage =>

					IF cnn_done = '1' THEN
						cnn_start     <= '0';
						state_machine <= SendResult;
					ELSE
						cnn_start <= '1';
					END IF;

				WHEN SendResult =>
				    -- sends 1 through UART

                    IF uart_busy = '1' AND uart_done = '0' THEN
                        uart_start <= '0';
                    ELSIF uart_done = '1' THEN
                        state_machine <= Idle;
                    ELSE
                        uart_start   <= '1';
                        uart_msg <= "00110001";
                    END IF;

			END CASE;
		END IF;
	END PROCESS TOP_LEVEL_process;
END TOP_LEVEL_arch;
