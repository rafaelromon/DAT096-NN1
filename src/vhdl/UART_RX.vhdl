-----------------------------------------------------
-- Title: UART_RX.vhdl
-- Author: Rafael Romon/NN-1
-- DAT096 - spring 2021
-----------------------------------------------------
-- Description:
-- UART Receiver. 8 bits w/ 1 start and 1 end bit
-- no parity.
-- TODO:
-- * implement CTS/RTS flow control
-- * implement oversampling for receive
-----------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY UART_RX IS
	GENERIC (
		--CLKS_PER_BIT : integer := 87  -- (Frequency of clk)/(Frequency of UART)
		CLKS_PER_BIT : INTEGER := 867 -- 100 MHz / 115200 baud rate
	);
	PORT (
		clk : IN STD_LOGIC;
		RX_Serial : IN STD_LOGIC;
		RX_DV : OUT STD_LOGIC;
		RX_Byte : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
	);
END UART_RX;
ARCHITECTURE UART_RX_arch OF UART_RX IS

	TYPE states IS (Idle, RX_Start_Bit, RX_Data_Bits,
		RX_Stop_Bit, Cleanup);
	SIGNAL StateMachine : states := Idle;

	SIGNAL RX_Data_R : STD_LOGIC := '0';
	SIGNAL RX_Data : STD_LOGIC := '0';

	SIGNAL clk_Count : INTEGER RANGE 0 TO CLKS_PER_BIT - 1 := 0;
	SIGNAL Bit_Index : INTEGER RANGE 0 TO 7 := 0; -- 8 Bits Total
	SIGNAL RX_Byte_signal : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
	SIGNAL RX_DV_signal : STD_LOGIC := '0';

BEGIN

	-- Purpose: Double-register the incoming data.
	-- This allows it to be used in the UART RX Clock Domain.
	-- (It removes problems caused by metastabiliy)
	double_register : PROCESS (clk)
	BEGIN
		IF rising_edge(clk) THEN
			RX_Data_R <= RX_Serial;
			RX_Data <= RX_Data_R;
		END IF;
	END PROCESS double_register;

	-- Purpose: Control RX state machine
	UART_RX_process : PROCESS (clk)
	BEGIN
		IF rising_edge(clk) THEN

			CASE StateMachine IS
				WHEN Idle =>
					RX_DV_signal <= '0';
					clk_Count <= 0;
					Bit_Index <= 0;

					IF RX_Data = '0' THEN -- Start bit detected
						StateMachine <= RX_Start_Bit;
					ELSE
						StateMachine <= Idle;
					END IF;

				WHEN RX_Start_Bit =>
					IF clk_Count = (CLKS_PER_BIT - 1)/2 THEN -- Check middle of start bit to make sure it's still low
						IF RX_Data = '0' THEN
							clk_Count <= 0; -- reset counter since we found the middle
							StateMachine <= RX_Data_Bits;
						ELSE
							StateMachine <= Idle;
						END IF;
					ELSE
						clk_Count <= clk_Count + 1;
						StateMachine <= RX_Start_Bit;
					END IF;

				WHEN RX_Data_Bits =>
					IF clk_Count < CLKS_PER_BIT - 1 THEN -- Wait g_CLKS_PER_BIT-1 clock cycles to sample serial data
						clk_Count <= clk_Count + 1;
						StateMachine <= RX_Data_Bits;
					ELSE
						clk_Count <= 0;
						RX_Byte_signal(Bit_Index) <= RX_Data;

						IF Bit_Index < 7 THEN -- Check if we have sent out all bits
							Bit_Index <= Bit_Index + 1;
							StateMachine <= RX_Data_Bits;
						ELSE
							Bit_Index <= 0;
							StateMachine <= RX_Stop_Bit;
						END IF;
					END IF;

				WHEN RX_Stop_Bit => -- Receive Stop bit.  Stop bit = 1
					IF clk_Count < CLKS_PER_BIT - 1 THEN -- Wait g_CLKS_PER_BIT-1 clock cycles for Stop bit to finish
						clk_Count <= clk_Count + 1;
						StateMachine <= RX_Stop_Bit;
					ELSE
						RX_DV_signal <= '1';
						clk_Count <= 0;
						StateMachine <= Cleanup;
					END IF;

				WHEN Cleanup => -- Stay here 1 clock
					StateMachine <= Idle;
					RX_DV_signal <= '0';
				WHEN OTHERS =>
					StateMachine <= Idle;

			END CASE;
		END IF;
	END PROCESS UART_RX_process;

	RX_DV <= RX_DV_signal;
	RX_Byte <= RX_Byte_signal;

END UART_RX_arch;
