----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/03/2021 08:42:23 AM
-- Design Name: 
-- Module Name: state_machine_scribble - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity state_machine_scribble is
    generic( ADDR_WIDTH : integer;
             WRITE : std_logic_vector(2 downto 0):= "000";
             READ : std_logic_vector(2 downto 0):=  "001");
    Port ( app_cmd : in std_logic_vector(2 downto 0);
           app_addr : in STD_LOGIC;
           app_en : in STD_LOGIC;
           app_full : out STD_LOGIC;
           clk : in std_logic;
           reset_p: in std_logic);
end state_machine_scribble;

architecture Behavioral of state_machine_scribble is

signal app_addr_upper : std_logic_vector(ADDR_WIDTH/2-1 downto 0);
signal app_addr_lower : std_logic_vector(ADDR_WIDTH/2-1 downto 0);

begin
--pseudo code
app_addr_upper <= app_addr(ADDR_WIDTH-1 downto ADDR_WIDTH);
app_addr_lower <= app_addr(ADDR_WIDTH/2-1 downto 0);

if !reset_p
    app_en = 1  -- setting app enable ready and then waiting for the app_rdy to go high
    if app_rdy && app_en -- When app_rdy and app_en are high then commands can be handled
        if app_cmd == WRITE -- checking if the commandis WRITE (i.e. 000)
            
            app_wdf_end <= '1' -- setting this if the word is the last to be written
         else if app_cmd == READ
        
        

end Behavioral;
