LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY UART_TB IS
END UART_TB;

ARCHITECTURE UART_TB_arch OF UART_TB IS

	COMPONENT UART_TX IS
		PORT (
			clk : IN STD_LOGIC;
			TX_DV : IN STD_LOGIC;
			TX_Byte : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
			TX_Active : OUT STD_LOGIC;
			TX_Serial : OUT STD_LOGIC;
			TX_Done : OUT STD_LOGIC
		);
	END COMPONENT UART_TX;

	COMPONENT UART_RX IS
		PORT (
			clk : IN STD_LOGIC;
			RX_Serial : IN STD_LOGIC;
			RX_DV : OUT STD_LOGIC;
			RX_Byte : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
		);
	END COMPONENT UART_RX;

	CONSTANT BIT_PERIOD : TIME := 8680 ns;

	SIGNAL clk_tb : STD_LOGIC := '0';
	SIGNAL TX_DV_tb : STD_LOGIC := '0';
	SIGNAL TX_BYTE_tb : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
	SIGNAL TX_SERIAL_tb : STD_LOGIC;
	SIGNAL TX_DONE_tb : STD_LOGIC;
	SIGNAL RX_DV_tb : STD_LOGIC;
	SIGNAL RX_BYTE_tb : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL RX_SERIAL_tb : STD_LOGIC := '1';
	-- Low-level byte-write
	PROCEDURE UART_WRITE_BYTE (
		data_in : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		SIGNAL serial : OUT STD_LOGIC) IS
	BEGIN

		serial <= '0'; -- Send Start Bit
		WAIT FOR BIT_PERIOD;

		FOR ii IN 0 TO 7 LOOP -- Send Data Byte
			serial <= data_in(ii);
			WAIT FOR BIT_PERIOD;
		END LOOP; -- ii

		serial <= '1'; -- Send Stop Bit
		WAIT FOR BIT_PERIOD;
	END UART_WRITE_BYTE;
BEGIN

	UART_TX_INST : uart_tx -- Instantiate UART transmitter
	PORT MAP(
		clk => clk_tb,
		TX_DV => TX_DV_tb,
		TX_Byte => TX_BYTE_tb,
		TX_Active => OPEN,
		TX_Serial => TX_SERIAL_tb,
		TX_Done => TX_DONE_tb
	);
	UART_RX_INST : uart_rx -- Instantiate UART Receiver
	PORT MAP(
		clk => clk_tb,
		RX_Serial => RX_SERIAL_tb,
		RX_DV => RX_DV_tb,
		RX_BYTE => RX_BYTE_tb
	);

	clk_tb <= NOT clk_tb AFTER 5 ns;
	-- clk_tb <= not clk_tb after 50 ns;

	PROCESS IS
	BEGIN

		-- Tell the UART to send a command.
		WAIT UNTIL rising_edge(clk_tb);
		WAIT UNTIL rising_edge(clk_tb);
		TX_DV_tb <= '1';
		TX_BYTE_tb <= X"AB";
		WAIT UNTIL rising_edge(clk_tb);
		TX_DV_tb <= '0';
		WAIT UNTIL TX_DONE_tb = '1';

		-- Send a command to the UART
		WAIT UNTIL rising_edge(clk_tb);
		UART_WRITE_BYTE(X"3F", RX_SERIAL_tb);
		WAIT UNTIL rising_edge(clk_tb);

		-- Check that the correct command was received
		ASSERT RX_BYTE_tb = X"3F"
		REPORT "Test Failed - Incorrect Byte Received" SEVERITY error;

		ASSERT RX_BYTE_tb /= X"3F"
		REPORT "Test Passed - Correct Byte Received" SEVERITY note; -- Double assert so we get pass or fail

	END PROCESS;

END UART_TB_arch;
