
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity CNN_TB is
end CNN_TB;

architecture CNN_TB_arch of CNN_TB is

COMPONENT CNN
 PORT (clk:in std_logic;
       resetn: in std_logic;
       start:in std_logic;       
       image:in std_logic_vector(16383 downto 0);
       
       finished: out std_logic;
       result: out std_logic_vector(5 downto 0)
       );     
END COMPONENT CNN;

signal clk_tb: std_logic := '1';
signal resetn_tb: std_logic := '1';
signal start_tb: std_logic := '0';
signal image_tb: std_logic_vector(16383 downto 0);

signal finished_tb: std_logic;
signal result_tb:  std_logic_vector(5 downto 0);

begin

    CNN_comp:
    component CNN
    PORT MAP(clk => clk_tb,
            resetn => resetn_tb,
            start => start_tb,
            image => image_tb,
            finished => finished_tb,
            result => result_tb
            );
            
    resetn_tb<='1',
               '0' AFTER 20 ns,
               '1' AFTER 50 ns;
               
    testprocess: process
    begin
        image_tb <= (others=>'0');
        start_tb <= '1';       
        wait until finished_tb = '1';
        assert result_tb = "101010"
        severity ERROR;     
    end process;
    
    clock_process:
 process
    begin
        clk_tb <= not(clk_tb);
        wait for 5 ns;
    end process;

end CNN_TB_arch;
