-----------------------------------------------------
-- Title: TOP_LEVEL_UART.vhdl
-- Author: Rafael Romon/NN-1
-- DAT096 - spring 2021
-----------------------------------------------------
-- Description:
-- This entity dictates the top level
-- architecture of the entire system
-- TODO:
-- * implement BRAM controller
-- * better implement user button
-----------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

LIBRARY UNISIM;
USE UNISIM.Vcomponents.ALL;

ENTITY TOP_LEVEL_UART IS
	GENERIC
	(
		clk_freq : INTEGER := 100 --system clock frequency in MHz
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
END TOP_LEVEL_UART;

ARCHITECTURE TOP_LEVEL_UART_arch OF TOP_LEVEL_UART IS

	TYPE states IS (Idle, SendResult, Finished);
	SIGNAL state_machine  : states := Idle;
	SIGNAL clk            : STD_LOGIC;
	SIGNAL reset_p        : STD_LOGIC                    := '0';
	SIGNAL reset_n        : STD_LOGIC                    := '1';

	SIGNAL tx_ena_signal  : STD_LOGIC                    := '0';
	SIGNAL tx_busy_signal : STD_LOGIC                    := '0';
	SIGNAL tx_data_signal : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');

	COMPONENT uart
		PORT
		(
			clk      : IN  STD_LOGIC;                    --system clock
			reset_n  : IN  STD_LOGIC;                    --ascynchronous reset
			tx_ena   : IN  STD_LOGIC;                    --initiate transmission
			tx_data  : IN  STD_LOGIC_VECTOR(7 DOWNTO 0); --data to transmit
			rx       : IN  STD_LOGIC;                    --receive pin
			rx_busy  : OUT STD_LOGIC;                    --data reception in progress
			rx_error : OUT STD_LOGIC;                    --start, parity, or stop bit error detected
			rx_data  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); --data received
			tx_busy  : OUT STD_LOGIC;                    --transmission in progress
			tx       : OUT STD_LOGIC                   --transmit pin
		);
	END COMPONENT uart;
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

	uart_i : uart
	PORT
	MAP (
	clk      => clk,
	reset_n  => reset_n,
	tx_ena   => tx_ena_signal,
	tx_data  => tx_data_signal,
	rx       => '1', -- Always high so no receive
	rx_busy  => OPEN,
	rx_error => OPEN,
	rx_data  => OPEN,
	tx_busy  => tx_busy_signal,
	tx       => USB_UART_TX
	);
	-- Purpose: Control state machine
	TOP_LEVEL_UART_process : PROCESS (clk, CPU_RESET)
		VARIABLE start_flag : STD_LOGIC := '0';
		VARIABLE sent_flag  : STD_LOGIC := '0';
	BEGIN
		IF CPU_RESET = '1' THEN
			reset_p       <= '1';
			reset_n       <= '0';

			state_machine <= Idle;

			GPIO_LED_0    <= '1';
			GPIO_LED_1    <= '1';
			GPIO_LED_2    <= '1';
			GPIO_LED_3    <= '1';

		ELSIF RISING_EDGE(clk) THEN

			reset_p <= '0';
			reset_n <= '1';

			CASE state_machine IS
				WHEN Idle =>

					GPIO_LED_0 <= '0';
					GPIO_LED_1 <= '1';
					GPIO_LED_2 <= '0';
					GPIO_LED_3 <= '0';

					IF GPIO_SW_N = '1' THEN
						start_flag := '1';
					ELSIF GPIO_SW_N = '0' AND start_flag = '1' THEN
						start_flag := '0';
						state_machine <= SendResult;
					END IF;

				WHEN SendResult =>
					GPIO_LED_0 <= '0';
					GPIO_LED_1 <= '0';
					GPIO_LED_2 <= '1';
					GPIO_LED_3 <= '0';

					IF sent_flag = '0' AND tx_busy_signal = '0' THEN
						tx_ena_signal  <= '1';
						tx_data_signal <= "01010101";
						sent_flag := '1';
					ELSIF sent_flag = '1' THEN
					   tx_ena_signal <= '0';
					   IF tx_busy_signal = '1' THEN
							tx_ena_signal <= '0';
					   ELSE
							sent_flag := '0';
							state_machine <= Finished;
						END IF;
					END IF;

				WHEN Finished =>
					GPIO_LED_0 <= '0';
					GPIO_LED_1 <= '0';
					GPIO_LED_2 <= '0';
					GPIO_LED_3 <= '1';
			END CASE;
		END IF;
	END PROCESS TOP_LEVEL_UART_process;
END TOP_LEVEL_UART_arch;
