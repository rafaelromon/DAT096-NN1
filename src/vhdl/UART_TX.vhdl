-----------------------------------------------------
-- UART_TX.vdhl -- 
-- Author: Rafael Romón --
-----------------------------------------------------
-- UART Transmitterr. 8 bits w/ 1 start and 1 end --
-- bit, no parity. --
-----------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY UART_TX IS
	GENERIC 
	(
		--clkS_PER_BIT : integer := 87 -- (Frequency of clk)/(Frequency of UART)
		clkS_PER_BIT : INTEGER := 868 -- 100 MHz / 115200 baud rate
	);
	PORT 
	(
		clk       : IN std_logic;
		TX_DV     : IN std_logic;
		TX_Byte   : IN std_logic_vector(7 DOWNTO 0);
		TX_Active : OUT std_logic;
		TX_Serial : OUT std_logic;
		TX_Done   : OUT std_logic
	);
END UART_TX;
ARCHITECTURE UART_TX_arch OF UART_TX IS

	TYPE states IS (Idle, TX_Start_Bit, TX_Data_Bits, 
	TX_Stop_Bit, Cleanup);
	SIGNAL StateMachine   : states := Idle;

	SIGNAL clk_Count      : INTEGER RANGE 0 TO clkS_PER_BIT - 1 := 0;
	SIGNAL Bit_Index      : INTEGER RANGE 0 TO 7 := 0; -- 8 Bits Total
	SIGNAL TX_Data        : std_logic_vector(7 DOWNTO 0) := (OTHERS => '0');
	SIGNAL TX_Done_signal : std_logic := '0';
 
BEGIN
	-- Purpose: Control RX state machine
	UART_RX_process : PROCESS (clk)
	BEGIN
		IF rising_edge(clk) THEN
 
			CASE StateMachine IS

				WHEN Idle => 
					TX_Active      <= '0';
					TX_Serial      <= '1'; -- Drive Line High for Idle
					TX_Done_signal <= '0';
					clk_Count      <= 0;
					Bit_Index      <= 0;

					IF TX_DV = '1' THEN
						TX_Data      <= TX_Byte;
						StateMachine <= TX_Start_Bit;
					ELSE
						StateMachine <= Idle;
					END IF; 
 
				WHEN TX_Start_Bit => -- Send out Start Bit. Start bit = 0
					TX_Active <= '1';
					TX_Serial <= '0';

					-- Wait g_clkS_PER_BIT-1 clock cycles for start bit to finish
					IF clk_Count < clkS_PER_BIT - 1 THEN
						clk_Count    <= clk_Count + 1;
						StateMachine <= TX_Start_Bit;
					ELSE
						clk_Count    <= 0;
						StateMachine <= TX_Data_Bits;
					END IF;
 
				WHEN TX_Data_Bits => -- Wait g_clkS_PER_BIT-1 clock cycles for data bits to finish
					TX_Serial <= TX_Data(Bit_Index);
 
					IF clk_Count < clkS_PER_BIT - 1 THEN
						clk_Count    <= clk_Count + 1;
						StateMachine <= TX_Data_Bits;
					ELSE
						clk_Count <= 0; 
 
						IF Bit_Index < 7 THEN -- Check if we have sent out all bits
							Bit_Index    <= Bit_Index + 1;
							StateMachine <= TX_Data_Bits;
						ELSE
							Bit_Index    <= 0;
							StateMachine <= TX_Stop_Bit;
						END IF;
					END IF;

				WHEN TX_Stop_Bit => -- Send out Stop bit. Stop bit = 1
					TX_Serial <= '1';
 
					IF clk_Count < clkS_PER_BIT - 1 THEN -- Wait g_clkS_PER_BIT-1 clock cycles for Stop bit to finish
						clk_Count    <= clk_Count + 1;
						StateMachine <= TX_Stop_Bit;
					ELSE
						TX_Done_signal <= '1';
						clk_Count      <= 0;
						StateMachine   <= Cleanup;
					END IF;
 
				WHEN Cleanup => -- Stay here 1 clock
					TX_Active      <= '0';
					TX_Done_signal <= '1';
					StateMachine   <= Idle; 
 
				WHEN OTHERS => 
					StateMachine <= Idle;

			END CASE;
		END IF;
	END PROCESS UART_RX_process;

	TX_Done <= TX_Done_signal;
 
END UART_TX_arch;