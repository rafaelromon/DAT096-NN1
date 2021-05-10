
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY Neuron_tb is
    GENERIC
	(
		KERNEL_SIZE : INTEGER := 9;
		INT_SIZE      : INTEGER := 8;
		FILTER_SIZE   : INTEGER := 8;
		OUT_SIZE      : INTEGER := 32
	);
END Neuron_tb;

ARCHITECTURE Neuron_tb_arch OF Neuron_tb IS

signal clk_tb           : STD_LOGIC := '1';
signal reset_p_tb       : STD_LOGIC := '0';
signal enable_tb       : STD_LOGIC := '0';
signal input_tb         : STD_LOGIC_VECTOR((KERNEL_SIZE * INT_SIZE) - 1 DOWNTO 0);
signal filter_values_tb : STD_LOGIC_VECTOR ((KERNEL_SIZE * FILTER_SIZE) - 1 DOWNTO 0);
signal bias_tb          : STD_LOGIC_VECTOR(OUT_SIZE - 1 DOWNTO 0);
signal output_tb        : STD_LOGIC_VECTOR(OUT_SIZE - 1 DOWNTO 0);

component Neuron
port (
  clk           : IN  STD_LOGIC;
  reset_p       : IN  STD_LOGIC;
  enable        : IN  STD_LOGIC;
  input         : IN  STD_LOGIC_VECTOR((KERNEL_SIZE * INT_SIZE) - 1 DOWNTO 0);
  filter_values : IN  STD_LOGIC_VECTOR ((KERNEL_SIZE * FILTER_SIZE) - 1 DOWNTO 0);
  bias          : IN  STD_LOGIC_VECTOR(OUT_SIZE - 1 DOWNTO 0);
  busy          : OUT STD_LOGIC;
  done          : OUT STD_LOGIC;
  output        : OUT STD_LOGIC_VECTOR(OUT_SIZE - 1 DOWNTO 0)
);

end component Neuron;

BEGIN

    Neuron_i : Neuron
    port map (
    clk           => clk_tb,
    reset_p       => reset_p_tb,
    enable        => enable_tb,
    input         => input_tb,
    filter_values => filter_values_tb,
    bias => bias_tb,
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
		bias_tb <= "00000000000000000000000000000001";
		enable_tb <= '1';
		WAIT FOR 20ns;
		enable_tb <= '0';
		WAIT FOR 10000ms;

	END PROCESS;

END Neuron_tb_arch;
