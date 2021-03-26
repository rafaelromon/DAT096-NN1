library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
 
entity TOP_LEVEL_TB is
end TOP_LEVEL_TB;
 
architecture TOP_LEVEL_TB_arch of TOP_LEVEL_TB is
 
  component TOP_LEVEL is
    port (
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
  end component TOP_LEVEL;   
   
  signal clk_p_tb     : STD_LOGIC := '0';
  signal clk_n_tb     : STD_LOGIC := '1';
  signal reset_tb     : STD_LOGIC;
  signal pushbutton_tb     : STD_LOGIC := '0';
  signal uart_tx_tb     : STD_LOGIC;
  signal uart_rts_tb     : STD_LOGIC;
  signal led_0_tb     : STD_LOGIC;
  signal led_1_tb     : STD_LOGIC;
  signal led_2_tb     : STD_LOGIC;    
  signal led_3_tb     : STD_LOGIC;    
  
 
   
begin 
  
  TOP_LEVEL_comp: TOP_LEVEL 
    port map (
		ref_clk_clk_p => clk_p_tb,
		ref_clk_clk_n => clk_n_tb,
		CPU_RESET => reset_tb,
		GPIO_SW_N => pushbutton_tb,
		USB_UART_TX => uart_tx_tb,
		USB_UART_RTS => uart_rts_tb,
		GPIO_LED_0 => led_0_tb,
		GPIO_LED_1 => led_1_tb,
		GPIO_LED_2 => led_2_tb,
		GPIO_LED_3 => led_3_tb
	); 
 
  
 
  clk_p_tb <= not clk_p_tb after 5 ns;
  clk_n_tb <= not clk_n_tb after 5 ns;
   
  process is
  begin
    
    reset_tb <= '1';
    wait for 5ns;
    reset_tb <= '0';
    wait for 10ns;   
    pushbutton_tb <= '1';   
    wait for 5ns;    
    pushbutton_tb <= '0';
    wait for 1000000ns;
    
  end process;
   
end TOP_LEVEL_TB_arch;