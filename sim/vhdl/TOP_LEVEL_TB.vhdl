LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY TOP_LEVEL_TB IS
END TOP_LEVEL_TB;

ARCHITECTURE TOP_LEVEL_TB_arch OF TOP_LEVEL_TB IS

	COMPONENT TOP_LEVEL
		GENERIC
		(
			clk_freq  : INTEGER := 100;
			testbench : STD_LOGIC
		);
		PORT
		(
			SYSCLK_P     : IN  STD_LOGIC;
			SYSCLK_N     : IN  STD_LOGIC;
			CPU_RESET    : IN  STD_LOGIC;
			GPIO_SW_N    : IN  STD_LOGIC;
			USB_UART_TX  : OUT STD_LOGIC;
			GPIO_LED_0   : OUT STD_LOGIC;
			GPIO_LED_1   : OUT STD_LOGIC;
			GPIO_LED_2   : OUT STD_LOGIC;
			GPIO_LED_3   : OUT STD_LOGIC
		);
	END COMPONENT TOP_LEVEL;
	SIGNAL clk_p_tb      : STD_LOGIC := '0';
	SIGNAL clk_n_tb      : STD_LOGIC := '1';
	SIGNAL reset_tb      : STD_LOGIC;
	SIGNAL pushbutton_tb : STD_LOGIC := '0';
	SIGNAL uart_tx_tb    : STD_LOGIC;
	SIGNAL uart_rts_tb   : STD_LOGIC;
	SIGNAL led_0_tb      : STD_LOGIC;
	SIGNAL led_1_tb      : STD_LOGIC;
	SIGNAL led_2_tb      : STD_LOGIC;
	SIGNAL led_3_tb      : STD_LOGIC;

BEGIN

	TOP_LEVEL_comp : TOP_LEVEL
	GENERIC
	MAP (
	testbench => '1'
	)
	PORT MAP
	(
		SYSCLK_P     => clk_p_tb,
		SYSCLK_N     => clk_n_tb,
		CPU_RESET    => reset_tb,
		GPIO_SW_N    => pushbutton_tb,
		USB_UART_TX  => uart_tx_tb,
		GPIO_LED_0   => led_0_tb,
		GPIO_LED_1   => led_1_tb,
		GPIO_LED_2   => led_2_tb,
		GPIO_LED_3   => led_3_tb
	);

	clk_p_tb <= NOT clk_p_tb AFTER 10 ns;
	clk_n_tb <= NOT clk_n_tb AFTER 10 ns;

	PROCESS IS
	BEGIN

		reset_tb <= '1';
		WAIT FOR 10ns;
		reset_tb <= '0';
		WAIT FOR 10ns;
		pushbutton_tb <= '1';
		WAIT FOR 20ns;
		pushbutton_tb <= '0';
		WAIT FOR 10000ms;

	END PROCESS;

END TOP_LEVEL_TB_arch;
