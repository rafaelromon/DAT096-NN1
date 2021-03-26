-----------------------------------------------------
-- Title: TOP_LEVEL.vhdl
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

library UNISIM;
USE UNISIM.Vcomponents.ALL;

ENTITY TOP_LEVEL IS
	PORT
	(
		ref_clk_clk_p     : IN STD_LOGIC;
		ref_clk_clk_n     : IN STD_LOGIC;
		CPU_RESET    : IN STD_LOGIC;
		GPIO_SW_N    : IN STD_LOGIC;
		USB_UART_TX  : OUT STD_LOGIC;
		USB_UART_RTS : OUT STD_LOGIC;
		GPIO_LED_0: OUT STD_LOGIC;
		GPIO_LED_1: OUT STD_LOGIC;
		GPIO_LED_2: OUT STD_LOGIC;
		GPIO_LED_3: OUT STD_LOGIC
	);
END TOP_LEVEL;

ARCHITECTURE TOP_LEVEL_arch OF TOP_LEVEL IS

	TYPE states IS (Idle, LoadImage, ProcessImage, SendResult);
	SIGNAL state_machine : states := Idle;
	SIGNAL reset_signal: STD_LOGIC := '0';        
    SIGNAL clk: STD_LOGIC;
    
	SIGNAL cnn_start : STD_LOGIC := '0';
	SIGNAL loaded_image : STD_LOGIC_VECTOR(16383 DOWNTO 0);
	SIGNAL cnn_finished : STD_LOGIC;
	SIGNAL cnn_result : STD_LOGIC_VECTOR(5 DOWNTO 0);
    
	COMPONENT CNN IS
		PORT
		(
			clk       : IN std_logic;
			reset_p   : IN std_logic;
			start     : IN std_logic;
			image     : IN std_logic_vector(16383 DOWNTO 0);
			finished  : OUT std_logic;
			result    : OUT std_logic_vector(5 DOWNTO 0)
		);
	END COMPONENT CNN;

	SIGNAL TX_DV : STD_LOGIC := '0';
	SIGNAL TX_Byte : STD_LOGIC_vector(7 DOWNTO 0) := (OTHERS => '0');
	SIGNAL TX_Done : STD_LOGIC;

	COMPONENT UART_TX IS
		PORT
		(
			clk        : IN STD_LOGIC;
			TX_DV      : IN STD_LOGIC;
			TX_Byte    : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
			TX_Active  : OUT STD_LOGIC;
			TX_Serial  : OUT STD_LOGIC;
			TX_Done    : OUT STD_LOGIC
		);
	END COMPONENT UART_TX;

BEGIN
    
    -- LVDS input to internal single
  CLK_IBUFDS : IBUFDS
  generic map(
    IOSTANDARD => "DEFAULT"
  )
  port map(
    I  => ref_clk_clk_p,
    IB => ref_clk_clk_n,
    O  => clk
    );
    
	CNN_comp : CNN -- Instantiate CNN transmitter
	PORT MAP
	(
		clk       => clk,
		reset_p   => reset_signal,
		start     => cnn_start,
		image     => loaded_image,
		finished  => cnn_finished,
		result    => cnn_result
	);

	UART_TX_comp : UART_TX -- Instantiate UART transmitter
	PORT MAP
	(
		clk        => clk,
		TX_DV      => TX_DV,
		TX_Byte    => TX_Byte,
		TX_Active  => USB_UART_RTS,
		TX_Serial  => USB_UART_TX,
		TX_Done    => TX_Done
	);

	-- Purpose: Control state machine
	TOP_LEVEL_process : PROCESS (clk, CPU_RESET)
	BEGIN
	    IF CPU_RESET = '1' THEN	      
	    
	       GPIO_LED_0 <= '1';
	       GPIO_LED_1 <= '1';
	       GPIO_LED_2 <= '1';
	       GPIO_LED_3 <= '1';
	       	       
           state_machine <= Idle;

		ELSIF RISING_EDGE(clk) THEN
			CASE state_machine IS
				WHEN Idle =>
                                       
                    GPIO_LED_0 <= '1';
                    GPIO_LED_1 <= '0';
                    GPIO_LED_2 <= '0';
                    GPIO_LED_3 <= '0';                                        
                    
					IF GPIO_SW_N = '1' THEN -- TODO this will cause problems once moved into the board
						reset_signal <= '0';
						state_machine <= LoadImage;
					ELSE
						reset_signal <= '1';
					END IF;

				WHEN LoadImage =>
				
				    GPIO_LED_0 <= '0';
                    GPIO_LED_1 <= '1';
				
					-- TODO this does nothing at the moment
					loaded_image <= (OTHERS => '0');
					state_machine <= ProcessImage;

				WHEN ProcessImage =>
                    
                    GPIO_LED_1 <= '0';
                    GPIO_LED_2 <= '1';
                    
					IF cnn_finished = '1' THEN
						cnn_start <= '0';
					    state_machine <= SendResult;
					ELSE
						cnn_start <= '1';
                    END IF;

				WHEN SendResult =>
                    
                    GPIO_LED_2 <= '0';
                    GPIO_LED_3 <= '1';
                    
					IF TX_Done = '1' THEN
						TX_DV <= '0';
						state_machine <= Idle;
					ELSE
						TX_DV <= '1';
						TX_Byte <= cnn_result & "00";
					END IF;

			END CASE;
		END IF;
	END PROCESS TOP_LEVEL_process;
END TOP_LEVEL_arch;
