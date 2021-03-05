-----------------------------------------------------
-- UART_RX.vdhl                                    --        
-- Author: Rafael Romón                            --
-----------------------------------------------------
-- UART Receiver. 8 bits w/ 1 start and 1 end bit  --
-- no parity.                                      --
-----------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
 
entity UART_RX is
  generic (
    --CLKS_PER_BIT : integer := 87  -- (Frequency of clk)/(Frequency of UART)
    CLKS_PER_BIT : integer := 868 -- 100 MHz / 115200 baud rate    
    );
  port (
    clk       : in  std_logic;
    RX_Serial : in  std_logic;
    RX_DV     : out std_logic;
    RX_Byte   : out std_logic_vector(7 downto 0)
    );
end UART_RX;
 
 
architecture UART_RX_arch of UART_RX is
 
  type states is (Idle, RX_Start_Bit, RX_Data_Bits,
                     RX_Stop_Bit, Cleanup);
  signal StateMachine : states := Idle;
 
  signal RX_Data_R : std_logic := '0';
  signal RX_Data   : std_logic := '0';
   
  signal clk_Count : integer range 0 to CLKS_PER_BIT-1 := 0;
  signal Bit_Index : integer range 0 to 7 := 0;  -- 8 Bits Total
  signal RX_Byte_signal   : std_logic_vector(7 downto 0) := (others => '0');
  signal RX_DV_signal     : std_logic := '0';
   
begin
 
  -- Purpose: Double-register the incoming data.
  -- This allows it to be used in the UART RX Clock Domain.
  -- (It removes problems caused by metastabiliy)
  double_register : process (clk)
  begin
    if rising_edge(clk) then
      RX_Data_R <= RX_Serial;
      RX_Data   <= RX_Data_R;
    end if;
  end process double_register;
   
  -- Purpose: Control RX state machine
  UART_RX_process: process (clk)
  begin
    if rising_edge(clk) then
         
      case StateMachine is
        when Idle =>
          RX_DV_signal     <= '0';
          clk_Count <= 0;
          Bit_Index <= 0;
 
          if RX_Data = '0' then       -- Start bit detected
            StateMachine <= RX_Start_Bit;
          else
            StateMachine <= Idle;
          end if;
        
        when RX_Start_Bit =>
          if clk_Count = (CLKS_PER_BIT-1)/2 then -- Check middle of start bit to make sure it's still low
            if RX_Data = '0' then
              clk_Count <= 0;  -- reset counter since we found the middle
              StateMachine   <= RX_Data_Bits;
            else
              StateMachine   <= Idle;
            end if;
          else
            clk_Count <= clk_Count + 1;
            StateMachine   <= RX_Start_Bit;
          end if;
                             
        when RX_Data_Bits =>
          if clk_Count < CLKS_PER_BIT-1 then -- Wait g_CLKS_PER_BIT-1 clock cycles to sample serial data
            clk_Count <= clk_Count + 1;
            StateMachine   <= RX_Data_Bits;
          else
            clk_Count <= 0;
            RX_Byte_signal(Bit_Index) <= RX_Data;
                                     
            if Bit_Index < 7 then -- Check if we have sent out all bits
              Bit_Index <= Bit_Index + 1;
              StateMachine <= RX_Data_Bits;
            else
              Bit_Index <= 0;
              StateMachine <= RX_Stop_Bit;
            end if;
          end if;
       
        when RX_Stop_Bit =>  -- Receive Stop bit.  Stop bit = 1          
          if clk_Count < CLKS_PER_BIT-1 then -- Wait g_CLKS_PER_BIT-1 clock cycles for Stop bit to finish
            clk_Count <= clk_Count + 1;
            StateMachine   <= RX_Stop_Bit;
          else
            RX_DV_signal <= '1';
            clk_Count <= 0;
            StateMachine <= Cleanup;
          end if;       
                               
        when Cleanup => -- Stay here 1 clock
          StateMachine <= Idle;
          RX_DV_signal   <= '0';                       
        when others =>
          StateMachine <= Idle;
 
      end case;
    end if;
  end process UART_RX_process;
 
  RX_DV   <= RX_DV_signal;
  RX_Byte <= RX_Byte_signal;
   
end UART_RX_arch;