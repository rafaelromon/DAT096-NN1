
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY CNN_tb IS
	GENERIC
	(
		INPUT_WIDTH   : INTEGER := 3;
		INPUT_HEIGHT  : INTEGER := 3;
		IO_SIZE       : INTEGER := 8;
		INTERNAL_SIZE : INTEGER := 32
	);
END CNN_tb;

ARCHITECTURE CNN_tb_arch OF CNN_tb IS

	SIGNAL clk_tb     : STD_LOGIC := '1';
	SIGNAL reset_p_tb : STD_LOGIC;
	SIGNAL start_tb   : STD_LOGIC;
	SIGNAL input_tb   : STD_LOGIC_VECTOR(INPUT_HEIGHT * INPUT_WIDTH * IO_SIZE - 1 DOWNTO 0);
	SIGNAL busy_tb    : STD_LOGIC;
	SIGNAL done_tb    : STD_LOGIC;
	SIGNAL output_tb  : STD_LOGIC_VECTOR(IO_SIZE - 1 DOWNTO 0);
	COMPONENT CNN IS
		GENERIC
		(
			INPUT_WIDTH   : INTEGER := 3;
			INPUT_HEIGHT  : INTEGER := 3;
			IO_SIZE       : INTEGER := 8;
			INTERNAL_SIZE : INTEGER := 32
		);
		PORT
		(
			clk     : IN  STD_LOGIC;
			reset_p : IN  STD_LOGIC;
			start   : IN  STD_LOGIC;
			input   : IN  STD_LOGIC_VECTOR(INPUT_HEIGHT * INPUT_WIDTH * IO_SIZE - 1 DOWNTO 0);
			busy    : OUT STD_LOGIC;
			done    : OUT STD_LOGIC;
			output  : OUT STD_LOGIC_VECTOR(IO_SIZE - 1 DOWNTO 0)
		);
	END COMPONENT;

BEGIN

	CNN_comp : CNN
	GENERIC
	MAP (
	INPUT_WIDTH   => INPUT_WIDTH,
	INPUT_HEIGHT  => INPUT_HEIGHT,
	IO_SIZE       => IO_SIZE,
	INTERNAL_SIZE => INTERNAL_SIZE
	)
	PORT MAP
	(
		clk     => clk_tb,
		reset_p => reset_p_tb,
		start   => start_tb,
		input   => input_tb,
		busy    => busy_tb,
		done    => done_tb,
		output  => output_tb
	);

	clk_tb <= NOT clk_tb AFTER 10 ns;

	PROCESS IS
	BEGIN

		reset_p_tb <= '1';
		WAIT FOR 20ns;
		reset_p_tb <= '0';
		WAIT FOR 20ns;
		input_tb <= x"010101010101010101";
		start_tb <= '1';
		WAIT FOR 20ns;
		start_tb <= '0';
		WAIT UNTIL done_tb = '1';
		WAIT FOR 20ns;
		REPORT "Simulation Finished." SEVERITY FAILURE;
	END PROCESS;

END CNN_tb_arch;
