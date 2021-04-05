library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CNN is
 PORT (clk:in std_logic;
       reset_p: in std_logic;
       start:in std_logic;       
       image:in std_logic_vector(16383 downto 0);
       
       finished: out std_logic;
       result: out std_logic_vector(5 downto 0)
       );             
end CNN;

architecture CNN_arch of CNN is
    signal enable: std_logic := '0';

begin
    stupid_cnn: process(clk, reset_p)
    begin
        if reset_p='1' then
             finished <= '0';
             result <= (others => '0');                           
        elsif RISING_EDGE(clk) then
            if start='1' and enable='0' then
                enable <= '1';
                finished <= '0';
            elsif enable ='1' then
                -- put image into buffers
                -- do cnn stuff
               finished <= '1';       
               result <= "101010";
               enable <= '0';                               
            end if;
        end if;
    end process;
    
end CNN_arch;
