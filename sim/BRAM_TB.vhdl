library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity BRAM_TB is
    GENERIC(IMG_ADDR:INTEGER:=4;
            IMG_WIDTH:INTEGER:=128;
            IMG_DEPTH:INTEGER:=12*128);
end BRAM_TB;

architecture Behavioral of BRAM_TB is

signal clk_tb : std_logic := '1';
signal ena_tb, enb_tb : std_logic := '0';
signal wea_tb : std_logic_vector(0 downto 0):="0";
signal addr_tb : std_logic_vector(IMG_ADDR-1 downto 0) := (others => '0');
signal dina_tb, doutb_tb : std_logic_vector(IMG_WIDTH-1 downto 0) := (others => '0');

COMPONENT image_buffer
  PORT (
    clka : IN STD_LOGIC; -- Clock signal port A
    clkb : IN STD_LOGIC; -- Clock signal port A
    ena : IN STD_LOGIC; --Enable signal port A
    enb : IN STD_LOGIC; --Enable signal port B
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0); --Write enable signal port A
    addra : IN STD_LOGIC_VECTOR(IMG_ADDR-1 DOWNTO 0); --8 bit address port A
    addrb : IN STD_LOGIC_VECTOR(IMG_ADDR-1 DOWNTO 0); --8 bit address port B
    dina : IN STD_LOGIC_VECTOR(IMG_WIDTH-1 DOWNTO 0); --8 bit data input to the RAM
    doutb : OUT STD_LOGIC_VECTOR(IMG_WIDTH-1 DOWNTO 0) --8 bit data output from the RAM.
  );
END COMPONENT image_buffer;

begin

--Instantiating BRAM.
    BRAM:
    component image_buffer
    PORT MAP(clka => clk_tb,
            clkb => clk_tb,
            ena => ena_tb,
            enb => enb_tb,
            wea => wea_tb,
            addra => addr_tb,
            addrb => addr_tb,
            dina => dina_tb,
            doutb => doutb_tb
            );

--Simulation process.
process
begin          
    wait until clk_tb = '0';
           
    --Writing and reading all the memory locations
    for i in 0 to IMG_DEPTH-1 loop    
        
        -- Prepare memory to write
        wea_tb <= "1";            
        ena_tb <= '1';  
        enb_tb <= '0';           
        
        addr_tb <= addr_tb + "1";
        dina_tb <= std_logic_vector(to_unsigned(i+1, IMG_WIDTH));   
        
        wait on clk_tb; --ram is unavailable for 1 clock cycle 
        wait on clk_tb;                                                                             
        
        -- Prepare memory to read
        wea_tb <= "0"; 
        ena_tb <= '0';  
        enb_tb <= '1';  
        
        wait on clk_tb; --ram is unavailable for 1 clock cycle 
        wait on clk_tb;                                       
        
        wait until clk_tb = '1'; -- output is ready on rising edge 
        wait until clk_tb = '0'; -- better to wait half a cycle to check
        assert to_integer(unsigned(doutb_tb)) = i+1;
        REPORT "RAM memory is " & integer'image(to_integer(unsigned(doutb_tb))) & 
            " but should be " & integer'image(i+1)
        SEVERITY ERROR;        
        
    end loop;
    wea_tb <= "0";  
    wait;
end process;

-- clock process
process
begin
    clk_tb <= not(clk_tb);
    wait for 5 ns;
end process;
end Behavioral;
