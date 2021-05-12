
LIBRARY IEEE;
USE ieee.std_logic_1164.all;


ENTITY FullyConnect_TB IS
GENERIC(
  INPUT_NUM_TB        : INTEGER := 9;
  NEURON_NUM_TB       : INTEGER := 2;
  IN_SIZE_TB          : INTEGER := 8;
  OUT_SIZE_TB         : INTEGER := 32	
	);
END FullyConnect_TB;

ARCHITECTURE FullyConnect_TB_arch OF FullyConnect_TB IS

SIGNAL clk_tb           : STD_LOGIC := '1';
SIGNAL reset_p_tb       : STD_LOGIC := '0';
SIGNAL enable_tb        : STD_LOGIC := '0';
SIGNAL input_tb         : STD_LOGIC_VECTOR(INPUT_NUM_TB*IN_SIZE_TB - 1 DOWNTO 0);
SIGNAL weight_tb 		: STD_LOGIC_VECTOR(INPUT_NUM_TB*NEURON_NUM_TB*IN_SIZE_TB - 1 DOWNTO 0);
SIGNAL bias_tb          : STD_LOGIC_VECTOR(NEURON_NUM_TB*OUT_SIZE_TB - 1 DOWNTO 0);
SIGNAL busy_tb          : STD_LOGIC;
SIGNAL done_tb          : STD_LOGIC;
SIGNAL output_tb        : STD_LOGIC_VECTOR(NEURON_NUM_TB*OUT_SIZE_TB - 1 DOWNTO 0);


COMPONENT FullyConnect
PORT(
  clk           : IN  STD_LOGIC;
  reset_p       : IN  STD_LOGIC;
  enable        : IN  STD_LOGIC;
  input         : IN  STD_LOGIC_VECTOR((INPUT_NUM_TB*IN_SIZE_TB) - 1 DOWNTO 0);
  weight_values : IN  STD_LOGIC_VECTOR((INPUT_NUM_TB*NEURON_NUM_TB*IN_SIZE_TB) - 1 DOWNTO 0);
  bias_values   : IN  STD_LOGIC_VECTOR(NEURON_NUM_TB*OUT_SIZE_TB - 1 DOWNTO 0);
  busy          : OUT STD_LOGIC;
  done          : OUT STD_LOGIC;
  output        : OUT STD_LOGIC_VECTOR(NEURON_NUM_TB*OUT_SIZE_TB - 1 DOWNTO 0)
	);
END COMPONENT FullyConnect;

BEGIN

test_comp : COMPONENT FullyConnect
  PORT MAP(
	clk           => clk_tb,
	reset_p       => reset_p_tb,
	enable        => enable_tb,
	input         => input_tb,
	weight_values => weight_tb,
	bias_values   => bias_tb, 
	busy          => busy_tb,
	done          => done_tb,
	output        => output_tb
	);
	
	
	clk_tb <= NOT clk_tb AFTER 10 ns;
	
	
test_proc : PROCESS
BEGIN

	reset_p_tb <= '1';
	WAIT FOR 20ns;
	reset_p_tb <= '0';
	WAIT FOR 20ns;
	input_tb <= "000010011010001001100011111000111011100011010101000000000000001101000011";
	weight_tb <= "11011110000010110111011001110001110110000011010101010100100001110100011";
	bias_tb <= "00000000000000000000000000000001";
	enable_tb <= '1';
	WAIT FOR 20ns;
	enable_tb <= '0';
	WAIT FOR 10000ms;

END PROCESS;

END FullyConnect_TB_arch;
