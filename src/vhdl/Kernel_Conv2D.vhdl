-----------------------------------------------------
-- Title: Kernel_Conv2D.vhdl
-- Author: Rafael Romon/NN-1
-- DAT096 - spring 2021
-----------------------------------------------------
-- Description:
--
-----------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

LIBRARY UNISIM;
USE UNISIM.vcomponents.ALL;

LIBRARY UNIMACRO;
USE UNIMACRO.vcomponents.ALL;

ENTITY Kernel_Conv2D IS
	GENERIC
	(
		KERNEL_HEIGHT : INTEGER := 3;
		KERNEL_WIDTH  : INTEGER := 3;
		INT_SIZE      : INTEGER := 8;
		FILTER_SIZE   : INTEGER := 8;
		OUT_SIZE      : INTEGER := 32
	);
	PORT
	(
		clk           : IN  STD_LOGIC;
		reset_p       : IN  STD_LOGIC;
		enable        : IN  STD_LOGIC;
		input         : IN  STD_LOGIC_VECTOR((KERNEL_HEIGHT * KERNEL_WIDTH * INT_SIZE) - 1 DOWNTO 0);
		filter_values : IN  STD_LOGIC_VECTOR ((KERNEL_HEIGHT * KERNEL_WIDTH * FILTER_SIZE) - 1 DOWNTO 0);
		busy          : OUT STD_LOGIC;
		done          : OUT STD_LOGIC;
		output        : OUT STD_LOGIC_VECTOR(OUT_SIZE - 1 DOWNTO 0)
	);
END Kernel_Conv2D;

ARCHITECTURE Kernel_Conv2D_arch OF Kernel_Conv2D IS
	TYPE INT_ARRAY IS ARRAY (0 TO (KERNEL_HEIGHT * KERNEL_WIDTH) - 1) OF STD_LOGIC_VECTOR(INT_SIZE - 1 DOWNTO 0);
	TYPE FILT_ARRAY IS ARRAY (0 TO (KERNEL_HEIGHT * KERNEL_WIDTH) - 1) OF STD_LOGIC_VECTOR(FILTER_SIZE - 1 DOWNTO 0);
	TYPE OUT_ARRAY IS ARRAY (0 TO (KERNEL_HEIGHT * KERNEL_WIDTH)) OF STD_LOGIC_VECTOR(OUT_SIZE - 1 DOWNTO 0);

	SIGNAL input_array  : INT_ARRAY;
	SIGNAL filter_array : FILT_ARRAY;
	SIGNAL temp_sum     : OUT_ARRAY;
	SIGNAL MACC_enable  : STD_LOGIC;

	COMPONENT Reg
		GENERIC
		(
			SIG_WIDTH : INTEGER := 8
		);
		PORT
		(
			clk     : IN  STD_LOGIC;
			reset_p : IN  STD_LOGIC;
			input   : IN  STD_LOGIC_VECTOR(SIG_WIDTH - 1 DOWNTO 0);
			output  : OUT STD_LOGIC_VECTOR(SIG_WIDTH - 1 DOWNTO 0)
		);
	END COMPONENT Reg;

BEGIN

	Reg_output : Reg GENERIC
	MAP (
	SIG_WIDTH => OUT_SIZE
	)
	PORT MAP
	(
		clk     => clk,
		reset_p => reset_p,
		input   => temp_sum(KERNEL_HEIGHT * KERNEL_WIDTH),
		output  => output
	);

	Regs : FOR i IN 0 TO 8 GENERATE
		Reg_input : Reg
		GENERIC
		MAP (
		SIG_WIDTH => INT_SIZE
		)
		PORT
		MAP (
		clk     => clk,
		reset_p => reset_p,
		input   => input((INT_SIZE * (i + 1)) - 1 DOWNTO (INT_SIZE * i)),
		output  => input_array(i)
		);

		Reg_filter : Reg
		GENERIC
		MAP (
		SIG_WIDTH => INT_SIZE
		)
		PORT
		MAP (
		clk     => clk,
		reset_p => reset_p,
		input   => filter_values((FILTER_SIZE * (i + 1)) - 1 DOWNTO (FILTER_SIZE * i)),
		output  => filter_array(i)
		);
		MACC_MACRO_inst : MACC_MACRO
		GENERIC
		MAP (
		DEVICE  => "7SERIES",   -- Target Device: "VIRTEX5", "7SERIES", "SPARTAN6" 
		LATENCY => 3,           -- Desired clock cycle latency, 1-4
		WIDTH_A => INT_SIZE,    -- Multiplier A-input bus width, 1-25
		WIDTH_B => FILTER_SIZE, -- Multiplier B-input bus width, 1-18     
		WIDTH_P => OUT_SIZE)    -- Accumulator output bus width, 1-48
		PORT
		MAP (
		P         => temp_sum(i + 1), -- MACC ouput bus, width determined by WIDTH_P generic 
		A         => input_array(i),  -- Multiplier input A bus, width determined by WIDTH_A generic	     
		ADDSUB    => '1',             -- 1-bit add/sub input, high selects add, low selects subtract
		B         => filter_array(i), -- Multiplier input B bus, width determined by WIDTH_B generic
		CARRYIN   => '0',             -- 1-bit carry-in input to accumulator
		CE        => MACC_enable,          -- 1-bit active high input clock enable
		CLK       => clk,             -- 1-bit positive edge clock input
		LOAD      => '1',             -- 1-bit active high input load accumulator enable
		LOAD_DATA => temp_sum(i),     -- Load accumulator input data, width determined by WIDTH_A generic
		RST       => reset_p          -- 1-bit input active high reset
		);

	END GENERATE;
		
	PROCESS(clk)
	BEGIN
	   IF RISING_EDGE(clk) THEN
	       if enable = '1' THEN
	           temp_sum(0) <= (OTHERS => '0');
	           MACC_enable <= '1';	 
	           busy <= '1'; 
	        END IF; -- TODO figure out when it finished
	   END IF;
	end process;

END Kernel_Conv2D_arch;
