
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY KernelWindow_tb IS
	GENERIC
	(
		INPUT_WIDTH     : INTEGER := 3;
		INPUT_HEIGHT    : INTEGER := 3;
		INPUT_CHANNELS  : INTEGER := 1;
		FILTERS         : INTEGER := 1;
		KERNEL_HEIGHT   : INTEGER := 2;
		KERNEL_WIDTH    : INTEGER := 2;
		KERNEL_CHANNELS : INTEGER := 1;
		ZERO_PADDING    : INTEGER := 1;
		STRIDE          : INTEGER := 1;
		INTEGER_SIZE    : INTEGER := 8
	);
END KernelWindow_tb;

ARCHITECTURE KernelWindow_tb_arch OF KernelWindow_tb IS

	SIGNAL clk_tb     : STD_LOGIC := '1';
	SIGNAL reset_p_tb : STD_LOGIC := '0';
	SIGNAL start_tb   : STD_LOGIC := '0';
	SIGNAL move_tb    : STD_LOGIC := '0';
	SIGNAL input_tb   : STD_LOGIC_VECTOR((INPUT_WIDTH * INPUT_HEIGHT * INTEGER_SIZE) - 1 DOWNTO 0);
	SIGNAL busy_tb    : STD_LOGIC;
	SIGNAL ready_tb   : STD_LOGIC;
	SIGNAL done_tb    : STD_LOGIC;
	SIGNAL output_tb  : STD_LOGIC_VECTOR((KERNEL_HEIGHT * KERNEL_WIDTH * INTEGER_SIZE) - 1 DOWNTO 0);

	COMPONENT KernelWindow
		GENERIC
		(
			INPUT_WIDTH    : INTEGER := 128;
			INPUT_HEIGHT   : INTEGER := 128;
			INPUT_CHANNELS : INTEGER := 8;
			KERNEL_WIDTH   : INTEGER := 1;
			KERNEL_HEIGHT  : INTEGER := 1;
			ZERO_PADDING   : INTEGER := 0;
			STRIDE         : INTEGER := 1;
			INTEGER_SIZE   : INTEGER := 8
		);
		PORT
		(
			clk     : IN  STD_LOGIC;
			reset_p : IN  STD_LOGIC;
			start   : IN  STD_LOGIC;
			move    : IN  STD_LOGIC;
			input   : IN  STD_LOGIC_VECTOR((INPUT_WIDTH * INPUT_HEIGHT * INTEGER_SIZE) - 1 DOWNTO 0);
			busy    : OUT STD_LOGIC;
			ready   : OUT STD_LOGIC;
			done    : OUT STD_LOGIC;
			output  : OUT STD_LOGIC_VECTOR((KERNEL_HEIGHT * KERNEL_WIDTH * INTEGER_SIZE) - 1 DOWNTO 0)
		);
	END COMPONENT KernelWindow;
BEGIN

	KernelWindow_i : KernelWindow
	GENERIC
	MAP (
	INPUT_WIDTH    => INPUT_WIDTH,
	INPUT_HEIGHT   => INPUT_HEIGHT,
	INPUT_CHANNELS => INPUT_CHANNELS,
	KERNEL_WIDTH   => KERNEL_WIDTH,
	KERNEL_HEIGHT  => KERNEL_HEIGHT,
	ZERO_PADDING  =>  ZERO_PADDING,
	STRIDE         => STRIDE,
	INTEGER_SIZE   => INTEGER_SIZE
	)
	PORT MAP
	(
		clk     => clk_tb,
		reset_p => reset_p_tb,
		start   => start_tb,
		move    => move_tb,
		input   => input_tb,
		busy    => busy_tb,
		ready   => ready_tb,
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
		input_tb <= x"112233445566778899";
		start_tb <= '1';
		WAIT FOR 20ns;
		start_tb <= '0';

		WAIT until ready_tb = '1';
		ASSERT output_tb = x"00000011"
		REPORT "Wrong value"
		SEVERITY WARNING;
		move_tb           <= '1';
		WAIT FOR 20ns;
		move_tb           <= '0';

		WAIT until ready_tb = '1';
		ASSERT output_tb = x"00001122"
		REPORT "Wrong value"
		SEVERITY WARNING;
		move_tb           <= '1';
		WAIT FOR 20ns;
        move_tb           <= '0';

		WAIT until ready_tb = '1';
		ASSERT output_tb = x"00002233"
		REPORT "Wrong value"
		SEVERITY WARNING;
		move_tb           <= '1';
		WAIT FOR 20ns;
		move_tb           <= '0';

		WAIT until ready_tb = '1';
		ASSERT output_tb = x"00003300"
		REPORT "Wrong value"
		SEVERITY WARNING;
		move_tb           <= '1';
		WAIT FOR 20ns;
		move_tb           <= '0';

		WAIT until ready_tb = '1';
		ASSERT output_tb = x"00110044"
		REPORT "Wrong value"
		SEVERITY WARNING;
		move_tb           <= '1';
		WAIT FOR 20ns;
		move_tb           <= '0';

		WAIT until ready_tb = '1';
		ASSERT output_tb = x"11224455"
		REPORT "Wrong value"
		SEVERITY WARNING;
		move_tb           <= '1';
		WAIT FOR 20ns;
        move_tb           <= '0';

		WAIT until ready_tb = '1';
		ASSERT output_tb = x"22335566"
		REPORT "Wrong value"
		SEVERITY WARNING;
		move_tb           <= '1';
		WAIT FOR 20ns;
		move_tb           <= '0';

		WAIT until ready_tb = '1';
		ASSERT output_tb = x"33006600"
		REPORT "Wrong value"
		SEVERITY WARNING;
		move_tb           <= '1';
		WAIT FOR 20ns;
		move_tb           <= '0';

		WAIT until ready_tb = '1';
		ASSERT output_tb = x"00440077"
		REPORT "Wrong value"
		SEVERITY WARNING;
		move_tb           <= '1';
		WAIT FOR 20ns;
		move_tb           <= '0';

		WAIT until ready_tb = '1';
		ASSERT output_tb = x"44557788"
		REPORT "Wrong value"
		SEVERITY WARNING;
		move_tb           <= '1';
		WAIT FOR 20ns;
		move_tb           <= '0';

		WAIT until ready_tb = '1';
		ASSERT output_tb = x"55668899"
		REPORT "Wrong value"
		SEVERITY WARNING;
		move_tb           <= '1';
		WAIT FOR 20ns;
		move_tb           <= '0';

		WAIT until ready_tb = '1';
		ASSERT output_tb = x"66009900"
		REPORT "Wrong value"
		SEVERITY WARNING;
		move_tb           <= '1';
		WAIT FOR 20ns;
		move_tb           <= '0';

		WAIT until ready_tb = '1';
		ASSERT output_tb = x"00770000"
		REPORT "Wrong value"
		SEVERITY WARNING;
		move_tb           <= '1';
		WAIT FOR 20ns;
		move_tb           <= '0';

		WAIT until ready_tb = '1';
		ASSERT output_tb = x"77880000"
		REPORT "Wrong value"
		SEVERITY WARNING;
		move_tb           <= '1';
		WAIT FOR 20ns;
        move_tb           <= '0';

		WAIT until ready_tb = '1';
		ASSERT output_tb = x"88990000"
		REPORT "Wrong value"
		SEVERITY WARNING;
		move_tb           <= '1';
		WAIT FOR 20ns;
		move_tb           <= '0';

		WAIT until ready_tb = '1';
		ASSERT output_tb = x"99000000"
		REPORT "Wrong value"
		SEVERITY WARNING;
		move_tb           <= '1';
		WAIT FOR 20ns;
		move_tb           <= '0';

    WAIT until done_tb = '1';
	    WAIT FOR 20ns;
        report "Simulation FInished." severity FAILURE;
	END PROCESS;

END KernelWindow_tb_arch;
