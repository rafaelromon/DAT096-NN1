
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY CNN_TB IS
END CNN_TB;

ARCHITECTURE CNN_TB_arch OF CNN_TB IS

	COMPONENT CNN
		PORT (
			clk : IN STD_LOGIC;
			resetn : IN STD_LOGIC;
			start : IN STD_LOGIC;
			image : IN STD_LOGIC_VECTOR(16383 DOWNTO 0);

			finished : OUT STD_LOGIC;
			result : OUT STD_LOGIC_VECTOR(5 DOWNTO 0)
		);
	END COMPONENT CNN;

	SIGNAL clk_tb : STD_LOGIC := '1';
	SIGNAL resetn_tb : STD_LOGIC := '1';
	SIGNAL start_tb : STD_LOGIC := '0';
	SIGNAL image_tb : STD_LOGIC_VECTOR(16383 DOWNTO 0);

	SIGNAL finished_tb : STD_LOGIC;
	SIGNAL result_tb : STD_LOGIC_VECTOR(5 DOWNTO 0);

BEGIN

	CNN_comp :
	COMPONENT CNN
		PORT MAP(
			clk => clk_tb,
			resetn => resetn_tb,
			start => start_tb,
			image => image_tb,
			finished => finished_tb,
			result => result_tb
		);

		resetn_tb <= '1',
		'0' AFTER 20 ns,
		'1' AFTER 50 ns;

		testprocess : PROCESS
		BEGIN
			image_tb <= (OTHERS => '0');
			start_tb <= '1';
			WAIT UNTIL finished_tb = '1';
			ASSERT result_tb = "101010"
			SEVERITY ERROR;
		END PROCESS;

	clock_process :
	PROCESS
	BEGIN
		clk_tb <= NOT(clk_tb);
		WAIT FOR 5 ns;
	END PROCESS;

END CNN_TB_arch;
