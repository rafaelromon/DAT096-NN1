
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY Neuron_tb IS
	GENERIC
	(
		KERNEL_HEIGHT : INTEGER := 3;
		KERNEL_WIDTH  : INTEGER := 3;
		KERNEL_DEPTH  : INTEGER := 1;
		IO_SIZE       : INTEGER := 8;
		INTERNAL_SIZE : INTEGER := 32
	);
END Neuron_tb;

ARCHITECTURE Neuron_tb_arch OF Neuron_tb IS

	SIGNAL clk_tb           : STD_LOGIC := '0';
	SIGNAL reset_p_tb       : STD_LOGIC := '0';
	SIGNAL start_tb         : STD_LOGIC := '0';
	SIGNAL input_tb         : STD_LOGIC_VECTOR((KERNEL_HEIGHT * KERNEL_WIDTH * KERNEL_DEPTH * IO_SIZE) - 1 DOWNTO 0);
	SIGNAL filter_values_tb : STD_LOGIC_VECTOR ((KERNEL_HEIGHT * KERNEL_WIDTH * KERNEL_DEPTH * IO_SIZE) - 1 DOWNTO 0);
	SIGNAL bias_tb          : STD_LOGIC_VECTOR(INTERNAL_SIZE - 1 DOWNTO 0);
	SIGNAL scale_tb         : STD_LOGIC_VECTOR(INTERNAL_SIZE - 1 DOWNTO 0);
	SIGNAL busy_tb          : STD_LOGIC;
	SIGNAL done_tb          : STD_LOGIC;
	SIGNAL output_tb        : STD_LOGIC_VECTOR(IO_SIZE - 1 DOWNTO 0);

	COMPONENT Neuron
		GENERIC
		(
			KERNEL_HEIGHT : INTEGER := 3;
			KERNEL_WIDTH  : INTEGER := 3;
			KERNEL_DEPTH  : INTEGER := 1;
			IO_SIZE       : INTEGER := 8;
			INTERNAL_SIZE : INTEGER := 32
		);
		PORT
		(
			clk           : IN  STD_LOGIC;
			reset_p       : IN  STD_LOGIC;
			start         : IN  STD_LOGIC;
			input         : IN  STD_LOGIC_VECTOR((KERNEL_HEIGHT * KERNEL_WIDTH * KERNEL_DEPTH * IO_SIZE) - 1 DOWNTO 0);
			filter_values : IN  STD_LOGIC_VECTOR ((KERNEL_HEIGHT * KERNEL_WIDTH * KERNEL_DEPTH * IO_SIZE) - 1 DOWNTO 0);
			bias          : IN  STD_LOGIC_VECTOR(INTERNAL_SIZE - 1 DOWNTO 0);
			scale         : IN  STD_LOGIC_VECTOR(INTERNAL_SIZE - 1 DOWNTO 0);
			busy          : OUT STD_LOGIC;
			done          : OUT STD_LOGIC;
			output        : OUT STD_LOGIC_VECTOR(IO_SIZE - 1 DOWNTO 0)
		);
	END COMPONENT Neuron;

BEGIN

	Neuron_i : Neuron
	GENERIC
	MAP (
	KERNEL_HEIGHT => KERNEL_HEIGHT,
	KERNEL_WIDTH  => KERNEL_WIDTH,
	KERNEL_DEPTH  => KERNEL_DEPTH,
	IO_SIZE       => IO_SIZE,
	INTERNAL_SIZE => INTERNAL_SIZE
	)
	PORT MAP
	(
		clk           => clk_tb,
		reset_p       => reset_p_tb,
		start         => start_tb,
		input         => input_tb,
		filter_values => filter_values_tb,
		bias          => bias_tb,
		scale         => scale_tb,
		busy          => busy_tb,
		done          => done_tb,
		output        => output_tb
	);

	clk_tb <= NOT clk_tb AFTER 10 ns;

	PROCESS IS
	BEGIN

		reset_p_tb <= '1';
		WAIT FOR 20ns;
		reset_p_tb <= '0';
		WAIT FOR 20ns;
		input_tb         <= "000010101110100011011001111100000000100010011010000000001001011000010110";
		filter_values_tb <= "001010111011111010001000010010001000011000011101100010001001011001010111";
		bias_tb          <= "00000000000000000000000000000001";
		scale_tb         <= "00000000000000000000000000000001";
		start_tb         <= '1';
		WAIT FOR 20ns;
		start_tb <= '0';
	WAIT until done_tb = '1';
	WAIT FOR 20ns;
    report "Simulation FInished." severity FAILURE;    

	END PROCESS;

END Neuron_tb_arch;
