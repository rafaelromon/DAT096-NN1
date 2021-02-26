library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
 
entity UART_TB is
end UART_TB;
 
architecture UART_TB_arch of UART_TB is
 
  component UART_TX is
    port (
        Clk       : in  std_logic;
        TX_DV     : in  std_logic;
        TX_Byte   : in  std_logic_vector(7 downto 0);
        TX_Active : out std_logic;
        TX_Serial : out std_logic;
        TX_Done   : out std_logic
      );
  end component UART_TX;
 
  component UART_RX is
      port (
        Clk       : in  std_logic;
        RX_Serial : in  std_logic;
        RX_DV     : out std_logic;
        RX_Byte   : out std_logic_vector(7 downto 0)
        );
  end component UART_RX;
 
  constant BIT_PERIOD : time := 8680 ns;
   
  signal Clk_tb     : std_logic                    := '0';
  signal TX_DV_tb     : std_logic                    := '0';
  signal TX_BYTE_tb   : std_logic_vector(7 downto 0) := (others => '0');
  signal TX_SERIAL_tb : std_logic;
  signal TX_DONE_tb   : std_logic;
  signal RX_DV_tb     : std_logic;
  signal RX_BYTE_tb   : std_logic_vector(7 downto 0);
  signal RX_SERIAL_tb : std_logic := '1';
 
   
  -- Low-level byte-write
  procedure UART_WRITE_BYTE (
    data_in       : in  std_logic_vector(7 downto 0);
    signal serial : out std_logic) is
  begin
    
    serial <= '0'; -- Send Start Bit
    wait for BIT_PERIOD; 

    for ii in 0 to 7 loop     -- Send Data Byte
      serial <= data_in(ii);
      wait for BIT_PERIOD;
    end loop;  -- ii
    
    serial <= '1'; -- Send Stop Bit
    wait for BIT_PERIOD;
  end UART_WRITE_BYTE;
 
   
begin 
  
  UART_TX_INST : uart_tx -- Instantiate UART transmitter
    port map (
      Clk       => Clk_tb,
      TX_DV     => TX_DV_tb,
      TX_Byte   => TX_BYTE_tb,
      TX_Active => open,
      TX_Serial => TX_SERIAL_tb,
      TX_Done   => TX_DONE_tb
      );
 
  
  UART_RX_INST : uart_rx -- Instantiate UART Receiver
    port map (
      Clk       => Clk_tb,
      RX_Serial => RX_SERIAL_tb,
      RX_DV     => RX_DV_tb,
      RX_BYTE   => RX_BYTE_tb
      );
 
  Clk_tb <= not Clk_tb after 5 ns;
  -- Clk_tb <= not Clk_tb after 50 ns;
   
  process is
  begin
 
    -- Tell the UART to send a command.
    wait until rising_edge(Clk_tb);
    wait until rising_edge(Clk_tb);
    TX_DV_tb   <= '1';
    TX_BYTE_tb <= X"AB";
    wait until rising_edge(Clk_tb);
    TX_DV_tb   <= '0';
    wait until TX_DONE_tb = '1'; 
     
    -- Send a command to the UART
    wait until rising_edge(Clk_tb);
    UART_WRITE_BYTE(X"3F", RX_SERIAL_tb);
    wait until rising_edge(Clk_tb);
 
    -- Check that the correct command was received
    assert RX_BYTE_tb = X"3F"    
    report "Test Failed - Incorrect Byte Received" severity error;    
    
    assert RX_BYTE_tb /= X"3F"    
    report "Test Passed - Correct Byte Received" severity note; -- Double assert so we get pass or fail
     
  end process;
   
end UART_TB_arch;