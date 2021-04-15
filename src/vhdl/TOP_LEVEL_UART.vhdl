-----------------------------------------------------
-- Title: TOP_LEVEL_UART.vhdl
-- Author: Rafael Romón/NN-1
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
		clk_freq  : INTEGER   := 100 --system clock frequency in MHz
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
	SIGNAL state_machine : states := Idle;
	SIGNAL clk           : STD_LOGIC;
	SIGNAL reset_signal  : STD_LOGIC                    := '0';

	SIGNAL TX_DV_signal         : STD_LOGIC                    := '0';
	SIGNAL TX_Byte_signal       : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
	SIGNAL TX_Done_signal       : STD_LOGIC;

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
	PORT
	MAP
	(
	I  => SYSCLK_P,
	IB => SYSCLK_N,
	O  => clk
	);

	UART_TX_comp : UART_TX -- Instantiate UART transmitter
	PORT
	MAP
	(
	clk       => clk,
	TX_DV     => TX_DV_signal,
	TX_Byte   => TX_Byte_signal,
	TX_Active => OPEN,
	TX_Serial => USB_UART_TX,
	TX_Done   => TX_Done_signal
	);

	-- Purpose: Control state machine
	TOP_LEVEL_UART_process : PROCESS (clk, CPU_RESET)
		VARIABLE start_flag : STD_LOGIC := '0';
		VARIABLE sent_flag  : STD_LOGIC := '0';
	BEGIN
		IF CPU_RESET = '1' THEN
			reset_signal  <= '1';
			state_machine <= Idle;

			GPIO_LED_0    <= '1';
			GPIO_LED_1    <= '1';
			GPIO_LED_2    <= '1';
			GPIO_LED_3    <= '1';

		ELSIF RISING_EDGE(clk) THEN
			CASE state_machine IS
				WHEN Idle =>

					GPIO_LED_0 <= '0';
					GPIO_LED_1 <= '0';
					GPIO_LED_2 <= '1';
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

					IF sent_flag = '0' THEN						
						TX_DV_signal   <= '1';
						TX_Byte_signal <= "01010101";
						sent_flag := '1';
					ELSIF sent_flag = '1' and TX_Done_signal = '0' THEN
						TX_DV_signal <= '0';
					ELSE
					    sent_flag := '0';
						state_machine <= Finished;
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