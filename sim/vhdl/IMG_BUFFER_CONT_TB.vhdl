-----------------------------------------------------
-- Title: DWConv_tb.vhdl
-- Author: Rafael Romon/NN-1
-- DAT096 - spring 2021
-----------------------------------------------------
-- Description:
-- Testbench for the IMG_BUFFER_CONT entity
-----------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY IMG_BUFFER_CONT_TB IS
generic (
	DATA_HEIGHT  : INTEGER := 3;
	DATA_WIDTH   : INTEGER := 3;
	INTEGER_SIZE : INTEGER := 8;
	WORD_SIZE    : INTEGER := 72;
	BUFFER_DEPTH : INTEGER := 3;
	ADDR_WIDTH   : INTEGER := 3
);
END IMG_BUFFER_CONT_TB;

ARCHITECTURE IMG_BUFFER_CONT_TB_arch OF IMG_BUFFER_CONT_TB IS

	signal clk_tb     : STD_LOGIC := '0';
	signal reset_p_tb : STD_LOGIC;
	signal start_tb   : STD_LOGIC;
	signal busy_tb    : STD_LOGIC;
	signal done_tb    : STD_LOGIC;
	signal output_tb  : STD_LOGIC_VECTOR((DATA_WIDTH * DATA_HEIGHT * INTEGER_SIZE) - 1 DOWNTO 0);

	component IMG_BUFFER_CONTROLLER
	generic (
	  DATA_HEIGHT  : INTEGER := 3;
	  DATA_WIDTH   : INTEGER := 3;
	  INTEGER_SIZE : INTEGER := 8;
	  WORD_SIZE    : INTEGER := 72;
		BUFFER_DEPTH : INTEGER := 4;
	  ADDR_WIDTH   : INTEGER := 11
	);
	port (
	  clk     : IN  STD_LOGIC;
	  reset_p : IN  STD_LOGIC;
	  start   : IN  STD_LOGIC;
	  busy    : OUT STD_LOGIC;
	  done    : OUT STD_LOGIC;
	  output  : OUT STD_LOGIC_VECTOR((DATA_WIDTH * DATA_HEIGHT * INTEGER_SIZE) - 1 DOWNTO 0)
	);
	end component IMG_BUFFER_CONTROLLER;

BEGIN

	IMG_BUFFER_CONTROLLER_test : IMG_BUFFER_CONTROLLER
	generic map (
	DATA_HEIGHT  => DATA_HEIGHT,
	DATA_WIDTH   => DATA_WIDTH,
	INTEGER_SIZE => INTEGER_SIZE,
	WORD_SIZE    => WORD_SIZE,
	BUFFER_DEPTH => BUFFER_DEPTH,
	ADDR_WIDTH   => ADDR_WIDTH
	)
	port map (
	clk     => clk_tb,
	reset_p => reset_p_tb,
	start   => start_tb,
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

		start_tb         <= '1';
		WAIT until done_tb = '1';
		start_tb         <= '0';
		ASSERT output_tb = x"010101010101010101"
		REPORT "Wrong value"
		SEVERITY WARNING;

		WAIT FOR 20ns;
		start_tb         <= '1';
		WAIT FOR 20ns;
		WAIT until done_tb = '1';
		start_tb         <= '0';
		ASSERT output_tb = x"020202020202020202"
		REPORT "Wrong value"
		SEVERITY WARNING;

		WAIT FOR 20ns;
		start_tb         <= '1';
		WAIT FOR 20ns;
		WAIT until done_tb = '1';
		start_tb         <= '0';
		ASSERT output_tb = x"030303030303030303"
		REPORT "Wrong value"
		SEVERITY WARNING;
		
		WAIT FOR 20ns;
		start_tb         <= '1';
		WAIT FOR 20ns;
		WAIT until done_tb = '1';
		start_tb         <= '0';
		ASSERT output_tb = x"010101010101010101"
		REPORT "Wrong value"
		SEVERITY WARNING;

		WAIT FOR 20ns;
    report "Simulation Finished." severity FAILURE;
	END PROCESS;

END ARCHITECTURE IMG_BUFFER_CONT_TB_arch;
