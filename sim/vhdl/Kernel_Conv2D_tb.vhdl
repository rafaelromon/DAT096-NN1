
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY Kernel_Conv2D_tb is
    GENERIC
	(
		KERNEL_HEIGHT : INTEGER := 3;
		KERNEL_WIDTH  : INTEGER := 3;
		INT_SIZE      : INTEGER := 8;
		FILTER_SIZE   : INTEGER := 8;
		OUT_SIZE      : INTEGER := 32
	);
END Kernel_Conv2D_tb;

ARCHITECTURE Kernel_Conv2D_tb_arch OF Kernel_Conv2D_tb IS

signal clk_tb           : STD_LOGIC := '1';
signal reset_p_tb       : STD_LOGIC := '0';
signal enable_tb       : STD_LOGIC := '0';
signal input_tb         : STD_LOGIC_VECTOR((KERNEL_HEIGHT * KERNEL_WIDTH * INT_SIZE) - 1 DOWNTO 0);
signal filter_values_tb : STD_LOGIC_VECTOR ((KERNEL_HEIGHT * KERNEL_WIDTH * FILTER_SIZE) - 1 DOWNTO 0);
signal output_tb        : STD_LOGIC_VECTOR(OUT_SIZE - 1 DOWNTO 0);

component Kernel_Conv2D
port (
  clk           : IN  STD_LOGIC;
  reset_p       : IN  STD_LOGIC;
  enable        : IN STD_LOGIC;
  input         : IN  STD_LOGIC_VECTOR((KERNEL_HEIGHT * KERNEL_WIDTH * INT_SIZE) - 1 DOWNTO 0);
  filter_values : IN  STD_LOGIC_VECTOR ((KERNEL_HEIGHT * KERNEL_WIDTH * FILTER_SIZE) - 1 DOWNTO 0);
  output        : OUT STD_LOGIC_VECTOR(OUT_SIZE - 1 DOWNTO 0)
);
end component Kernel_Conv2D;

BEGIN

    Kernel_Conv2D_i : Kernel_Conv2D
    port map (
    clk           => clk_tb,
    reset_p       => reset_p_tb,
    enable        => enable_tb,
    input         => input_tb,
    filter_values => filter_values_tb,
    output        => output_tb
    );
        
	clk_tb <= NOT clk_tb AFTER 10 ns;	

	PROCESS IS
	BEGIN

		reset_p_tb <= '1';
		WAIT FOR 20ns;
		reset_p_tb <= '0';
		WAIT FOR 20ns;		
		input_tb <= "000010101110100011011001111100000000100010011010000000001001011000010110";
		filter_values_tb <= "001010111011111010001000010010001000011000011101100010001001011001010111";
		enable_tb <= '1';
		WAIT FOR 20ns;
		--enable_tb <= '0';
		WAIT FOR 10000ms;

	END PROCESS;

END Kernel_Conv2D_tb_arch; 