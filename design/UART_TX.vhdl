-----------------------------------------------------
-- UART_TX.vdhl                                    --        
-- Author: Rafael Romón                            --
-----------------------------------------------------
-- UART Transmitterr. 8 bits w/ 1 start and 1 end  --
--  bit, no parity.                                --
-----------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity UART_TX is
  generic (
    --CLKS_PER_BIT : integer := 87  -- (Frequency of Clk)/(Frequency of UART)
    CLKS_PER_BIT : integer := 868 -- 100 MHz / 115200 baud rate
    );
  port (
    Clk       : in  std_logic;
    TX_DV     : in  std_logic;
    TX_Byte   : in  std_logic_vector(7 downto 0);
    TX_Active : out std_logic;
    TX_Serial : out std_logic;
    TX_Done   : out std_logic
    );
end UART_TX;
 
 
architecture UART_TX_arch of UART_TX is
 
  type states is (Idle, TX_Start_Bit, TX_Data_Bits,
                     TX_Stop_Bit, Cleanup);
  signal StateMachine : states := Idle;
 
  signal Clk_Count : integer range 0 to CLKS_PER_BIT-1 := 0;
  signal Bit_Index : integer range 0 to 7 := 0;  -- 8 Bits Total
  signal TX_Data   : std_logic_vector(7 downto 0) := (others => '0');
  signal TX_Done_signal   : std_logic := '0';
   
begin    

  -- Purpose: Control RX state machine
  UART_RX_process: process (Clk)
  begin
    if rising_edge(Clk) then
        
      case StateMachine is
 
        when Idle =>
          TX_Active <= '0';
          TX_Serial <= '1';         -- Drive Line High for Idle
          TX_Done_signal   <= '0';
          Clk_Count <= 0;
          Bit_Index <= 0;
 
          if TX_DV = '1' then
            TX_Data <= TX_Byte;
            StateMachine <= TX_Start_Bit;
          else
            StateMachine <= Idle;
          end if;            
        
        when TX_Start_Bit => -- Send out Start Bit. Start bit = 0
          TX_Active <= '1';
          TX_Serial <= '0';
 
          -- Wait g_CLKS_PER_BIT-1 clock cycles for start bit to finish
          if Clk_Count < CLKS_PER_BIT-1 then
            Clk_Count <= Clk_Count + 1;
            StateMachine   <= TX_Start_Bit;
          else
            Clk_Count <= 0;
            StateMachine   <= TX_Data_Bits;
          end if;
                               
        when TX_Data_Bits => -- Wait g_CLKS_PER_BIT-1 clock cycles for data bits to finish 
          TX_Serial <= TX_Data(Bit_Index);
           
          if Clk_Count < CLKS_PER_BIT-1 then
            Clk_Count <= Clk_Count + 1;
            StateMachine   <= TX_Data_Bits;
          else
            Clk_Count <= 0;             
            
            if Bit_Index < 7 then -- Check if we have sent out all bits
              Bit_Index <= Bit_Index + 1;
              StateMachine   <= TX_Data_Bits;
            else
              Bit_Index <= 0;
              StateMachine   <= TX_Stop_Bit;
            end if;
          end if;
 
        when TX_Stop_Bit => -- Send out Stop bit.  Stop bit = 1
          TX_Serial <= '1';
          
          if Clk_Count < CLKS_PER_BIT-1 then  -- Wait g_CLKS_PER_BIT-1 clock cycles for Stop bit to finish
            Clk_Count <= Clk_Count + 1;
            StateMachine   <= TX_Stop_Bit;
          else
            TX_Done_signal   <= '1';
            Clk_Count <= 0;
            StateMachine   <= Cleanup;
          end if;
                            
        when Cleanup => -- Stay here 1 clock
          TX_Active <= '0';
          TX_Done_signal   <= '1';
          StateMachine   <= Idle;           
                       
        when others =>
          StateMachine <= Idle;
 
      end case;
    end if;
  end process UART_RX_process;
 
  TX_Done <= TX_Done_signal;
   
end UART_TX_arch;