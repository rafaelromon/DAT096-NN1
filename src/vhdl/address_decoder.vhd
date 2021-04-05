----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/03/2021 09:45:40 AM
-- Design Name: 
-- Module Name: address_decoder - Behavioral
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

entity address_decoder is
    Port ( app_addr : in STD_LOGIC;
           col : out STD_LOGIC;
           row : out STD_LOGIC;
           bank : out STD_LOGIC;
           rank : out STD_LOGIC);
end address_decoder;

architecture Behavioral of address_decoder is

begin

decode: process 
if (MEM_ADDR_ORDER == "ROW_BANK_COLUMN")
      begin
        assign col = app_rdy_r
                      ? app_addr_r1[0+:COL_WIDTH]
                      : app_addr_r2[0+:COL_WIDTH];
        assign row = app_rdy_r
                       ? app_addr_r1[COL_WIDTH+BANK_WIDTH+:ROW_WIDTH]
                       : app_addr_r2[COL_WIDTH+BANK_WIDTH+:ROW_WIDTH];
        assign bank = app_rdy_r
                        ? app_addr_r1[COL_WIDTH+:BANK_WIDTH]
                        : app_addr_r2[COL_WIDTH+:BANK_WIDTH];
        assign rank = (RANKS == 1)
                        ? 1'b0
                        : app_rdy_r
                          ? app_addr_r1[COL_WIDTH+ROW_WIDTH+BANK_WIDTH+:RANK_WIDTH]
                          : app_addr_r2[COL_WIDTH+ROW_WIDTH+BANK_WIDTH+:RANK_WIDTH];
      end
      else
      begin
        assign col = app_rdy_r
                      ? app_addr_r1[0+:COL_WIDTH]
                      : app_addr_r2[0+:COL_WIDTH];
        assign row = app_rdy_r
                       ? app_addr_r1[COL_WIDTH+:ROW_WIDTH]
                       : app_addr_r2[COL_WIDTH+:ROW_WIDTH];
        assign bank = app_rdy_r
                        ? app_addr_r1[COL_WIDTH+ROW_WIDTH+:BANK_WIDTH]
                        : app_addr_r2[COL_WIDTH+ROW_WIDTH+:BANK_WIDTH];
        assign rank = (RANKS == 1)
                        ? 1'b0
                        : app_rdy_r
                          ? app_addr_r1[COL_WIDTH+ROW_WIDTH+BANK_WIDTH+:RANK_WIDTH]
                          : app_addr_r2[COL_WIDTH+ROW_WIDTH+BANK_WIDTH+:RANK_WIDTH];
      end

end Behavioral;
