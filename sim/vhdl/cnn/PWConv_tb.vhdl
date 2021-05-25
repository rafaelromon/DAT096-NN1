-----------------------------------------------------
-- Title: PWConv_tb.vhdl
-- Author: Rafael Romon/NN-1
-- DAT096 - spring 2021
-----------------------------------------------------
-- Description:
-- Testbench for the Conv entity used as a PointWise
-- convolution.
-----------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY PWConv_tb is
  generic (
    INPUT_WIDTH    : INTEGER := 9;
    INPUT_HEIGHT   : INTEGER := 9;
    INPUT_CHANNELS : INTEGER := 1;
    KERNEL_HEIGHT  : INTEGER := 1;
    KERNEL_WIDTH   : INTEGER := 1;
    KERNEL_DEPTH   : INTEGER := 1;
    STRIDE         : INTEGER := 1;
    ZERO_PADDING   : INTEGER := 0;
    IO_SIZE        : INTEGER := 8;
    INTERNAL_SIZE  : INTEGER := 32
  );
END PWConv_tb;

ARCHITECTURE PWConv_tb_arch OF PWConv_tb IS

signal clk_tb           : STD_LOGIC := '1';
signal reset_p_tb       : STD_LOGIC;
signal start_tb         : STD_LOGIC;
signal input_tb         : STD_LOGIC_VECTOR((INPUT_WIDTH * INPUT_HEIGHT * IO_SIZE) - 1 DOWNTO 0);
signal filter_values_tb : STD_LOGIC_VECTOR ((KERNEL_HEIGHT * KERNEL_WIDTH * KERNEL_DEPTH * IO_SIZE) - 1 DOWNTO 0);
signal bias_tb          : STD_LOGIC_VECTOR(INTERNAL_SIZE - 1 DOWNTO 0);
signal scale_tb         : STD_LOGIC_VECTOR(INTERNAL_SIZE - 1 DOWNTO 0);
signal busy_tb          : STD_LOGIC;
signal done_tb          : STD_LOGIC;
signal output_tb        : STD_LOGIC_VECTOR(((INPUT_WIDTH * INPUT_HEIGHT * IO_SIZE)/STRIDE) - 1 DOWNTO 0);


component Conv
generic (
  INPUT_WIDTH    : INTEGER := 9;
  INPUT_HEIGHT   : INTEGER := 9;
  INPUT_CHANNELS : INTEGER := 1;
  KERNEL_HEIGHT  : INTEGER := 1;
  KERNEL_WIDTH   : INTEGER := 1;
  KERNEL_DEPTH   : INTEGER := 1;
  STRIDE         : INTEGER := 1;
  ZERO_PADDING   : INTEGER := 0;
  IO_SIZE        : INTEGER := 8;
  INTERNAL_SIZE  : INTEGER := 32
);
port (
  clk           : IN  STD_LOGIC;
  reset_p       : IN  STD_LOGIC;
  start         : IN  STD_LOGIC;
  input         : IN  STD_LOGIC_VECTOR((INPUT_WIDTH * INPUT_HEIGHT * IO_SIZE) - 1 DOWNTO 0);
  filter_values : IN  STD_LOGIC_VECTOR ((KERNEL_HEIGHT * KERNEL_WIDTH * KERNEL_DEPTH * IO_SIZE) - 1 DOWNTO 0);
  bias          : IN  STD_LOGIC_VECTOR(INTERNAL_SIZE - 1 DOWNTO 0);
  scale         : IN  STD_LOGIC_VECTOR(INTERNAL_SIZE - 1 DOWNTO 0);
  busy          : OUT STD_LOGIC;
  done          : OUT STD_LOGIC;
  output        : OUT STD_LOGIC_VECTOR(((INPUT_WIDTH * INPUT_HEIGHT * IO_SIZE)/STRIDE) - 1 DOWNTO 0)
);
end component Conv;


BEGIN

Conv_i : Conv
generic map (
  INPUT_WIDTH    => INPUT_WIDTH,
  INPUT_HEIGHT   => INPUT_HEIGHT,
  INPUT_CHANNELS => INPUT_CHANNELS,
  KERNEL_HEIGHT  => KERNEL_HEIGHT,
  KERNEL_WIDTH   => KERNEL_WIDTH,
  KERNEL_DEPTH   => KERNEL_DEPTH,
  STRIDE         => STRIDE,
  ZERO_PADDING   => ZERO_PADDING,
  IO_SIZE        => IO_SIZE,
  INTERNAL_SIZE  => INTERNAL_SIZE
)
port map (
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
		input_tb <= x"4afeb122ba1bb0746ffc4cf796370ece7470204cb4ab519062ba00e07b23eeacd00c6b7e6a76a1a0d2583ea526a6f5603a4a0e77f646dc05735b455d0c2838547dada51c7c9f8d769fee52e2259141115b";
    filter_values_tb <= x"01";
    bias_tb  <= "00000000000000000000000000111000";
		scale_tb <= "00000000000000000000000000000001";
		start_tb <= '1';
		WAIT FOR 20ns;
		start_tb <= '0';
    WAIT until done_tb = '1';
    WAIT FOR 20ns;
    report "Simulation Finished." severity FAILURE;

	END PROCESS;

END PWConv_tb_arch;
