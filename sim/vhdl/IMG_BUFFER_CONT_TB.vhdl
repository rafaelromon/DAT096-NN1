LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY IMG_BUFFER_CONT_TB IS
	GENERIC (
		ROW_WIDTH : INTEGER := 128;
		IMAGE_DEPTH : INTEGER := 128;
		ADDR_WIDTH : INTEGER := 11
	);
END IMG_BUFFER_CONT_TB;

ARCHITECTURE IMG_BUFFER_CONT_TB_arch OF IMG_BUFFER_CONT_TB IS

	SIGNAL clk_tb : STD_LOGIC := '0';
	SIGNAL reset_p_tb : STD_LOGIC;
	SIGNAL start_tb : STD_LOGIC;
	SIGNAL busy_tb : STD_LOGIC;
	SIGNAL image_tb : STD_LOGIC_VECTOR((ROW_WIDTH * IMAGE_DEPTH) - 1 DOWNTO 0);
	COMPONENT IMG_BUFFER_CONTROLLER
		PORT (
			clk : IN STD_LOGIC;
			reset_p : IN STD_LOGIC;
			start : IN STD_LOGIC;
			busy : OUT STD_LOGIC;
			image : OUT STD_LOGIC_VECTOR((ROW_WIDTH * IMAGE_DEPTH) - 1 DOWNTO 0)
		);
	END COMPONENT IMG_BUFFER_CONTROLLER;

BEGIN

	IMG_BUFFER_CONTROLLER_i : IMG_BUFFER_CONTROLLER
	PORT MAP(
		clk => clk_tb,
		reset_p => reset_p_tb,
		start => start_tb,
		busy => busy_tb,
		image => image_tb
	);

	clk_tb <= NOT clk_tb AFTER 5 ns;

	reset_p_tb <= '0',
		'1' AFTER 10 ns,
		'0' AFTER 20 ns;
	start_tb <= '0',
		'1' AFTER 30 ns,
		'0' AFTER 40 ns;

END ARCHITECTURE IMG_BUFFER_CONT_TB_arch;
