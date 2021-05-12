-----------------------------------------------------
-- Title: Neuron.vhdl
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

ENTITY Neuron IS
	GENERIC
	(
		KERNEL_SIZE : INTEGER := 9;
		IN_SIZE     : INTEGER := 8;
		OUT_SIZE    : INTEGER := 32
	);
	PORT
	(
		clk           : IN  STD_LOGIC;
		reset_p       : IN  STD_LOGIC;
		enable        : IN  STD_LOGIC;
		input         : IN  STD_LOGIC_VECTOR((KERNEL_SIZE * IN_SIZE) - 1 DOWNTO 0);
		filter_values : IN  STD_LOGIC_VECTOR ((KERNEL_SIZE * IN_SIZE) - 1 DOWNTO 0);
		bias          : IN  STD_LOGIC_VECTOR(OUT_SIZE - 1 DOWNTO 0);
		busy          : OUT STD_LOGIC;
		done          : OUT STD_LOGIC;
		output        : OUT STD_LOGIC_VECTOR(OUT_SIZE - 1 DOWNTO 0)
	);
END Neuron;

ARCHITECTURE Neuron_arch OF Neuron IS
	TYPE IN_ARRAY IS ARRAY (0 TO (KERNEL_SIZE) - 1) OF STD_LOGIC_VECTOR(IN_SIZE - 1 DOWNTO 0);
	TYPE OUT_ARRAY IS ARRAY (0 TO KERNEL_SIZE) OF STD_LOGIC_VECTOR(OUT_SIZE - 1 DOWNTO 0);

	SIGNAL input_array   : IN_ARRAY;
	SIGNAL filter_array  : IN_ARRAY;
	SIGNAL temp_sum      : OUT_ARRAY;
	SIGNAL DSP_enable    : STD_LOGIC;
	SIGNAL enable_latch  : STD_LOGIC;
	SIGNAL output_signal : STD_LOGIC_VECTOR(OUT_SIZE - 1 DOWNTO 0);

	COMPONENT Reg
		GENERIC
		(
			SIG_WIDTH : INTEGER := 8
		);
		PORT
		(
			clk     : IN  STD_LOGIC;
			reset_p : IN  STD_LOGIC;
			enable  : IN  STD_LOGIC;
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
		enable  => enable_latch,
		input   => output_signal,
		output  => output
	);

	Regs : FOR i IN 0 TO KERNEL_SIZE - 1 GENERATE
		Reg_input : Reg
		GENERIC
		MAP (
		SIG_WIDTH => IN_SIZE
		)
		PORT
		MAP (
		clk     => clk,
		reset_p => reset_p,
		enable  => '1',
		input   => input((IN_SIZE * (i + 1)) - 1 DOWNTO (IN_SIZE * i)),
		output  => input_array(i)
		);

		Reg_filter : Reg
		GENERIC
		MAP (
		SIG_WIDTH => IN_SIZE
		)
		PORT
		MAP (
		clk     => clk,
		reset_p => reset_p,
		enable  => '1',
		input   => filter_values((IN_SIZE * (i + 1)) - 1 DOWNTO (IN_SIZE * i)),
		output  => filter_array(i)
		);
		MACC_MACRO_inst : MACC_MACRO
		GENERIC
		MAP (
		DEVICE  => "7SERIES", -- Target Device: "VIRTEX5", "7SERIES", "SPARTAN6"
		LATENCY => 1,         -- Desired clock cycle latency, 1-4
		WIDTH_A => IN_SIZE,   -- Multiplier A-input bus width, 1-25
		WIDTH_B => IN_SIZE,   -- Multiplier B-input bus width, 1-18
		WIDTH_P => OUT_SIZE)  -- Accumulator output bus width, 1-48
		PORT
		MAP (
		P         => temp_sum(i + 1), -- MACC ouput bus, width determined by WIDTH_P generic
		A         => input_array(i),  -- Multiplier input A bus, width determined by WIDTH_A generic
		ADDSUB    => '1',             -- 1-bit add/sub input, high selects add, low selects subtract
		B         => filter_array(i), -- Multiplier input B bus, width determined by WIDTH_B generic
		CARRYIN   => '0',             -- 1-bit carry-in input to accumulator
		CE        => DSP_enable,      -- 1-bit active high input clock enable
		CLK       => clk,             -- 1-bit positive edge clock input
		LOAD      => '1',             -- 1-bit active high input load accumulator enable
		LOAD_DATA => temp_sum(i),     -- Load accumulator input data, width determined by WIDTH_A generic
		RST       => reset_p          -- 1-bit input active high reset
		);

	END GENERATE;

	ADDSUB_MACRO_inst : ADDSUB_MACRO
	GENERIC
	MAP (
	DEVICE  => "7SERIES", -- Target Device: "VIRTEX5", "7SERIES", "SPARTAN6"
	LATENCY => 0,         -- Desired clock cycle latency, 0-2
	WIDTH   => OUT_SIZE)  -- Input / Output bus width, 1-48
	PORT
	MAP (
	CARRYOUT => OPEN,                  -- 1-bit carry-out output signal
	RESULT   => output_signal,         -- Add/sub result output, width defined by WIDTH generic
	A        => temp_sum(KERNEL_SIZE), -- Input A bus, width defined by WIDTH generic
	ADD_SUB  => '1',                   -- 1-bit add/sub input, high selects add, low selects subtract
	B        => bias,                  -- Input B bus, width defined by WIDTH generic
	CARRYIN  => '0',                   -- 1-bit carry-in input
	CE       => DSP_enable,            -- 1-bit clock enable input
	CLK      => clk,                   -- 1-bit clock input
	RST      => reset_p                -- 1-bit active high synchronous reset
	);

	PROCESS (clk)
		VARIABLE count : INTEGER := 0;
	BEGIN
		IF reset_p = '1' THEN
			DSP_enable <= '0';
			busy       <= '0';
			done       <= '0';
		ELSIF RISING_EDGE(clk) THEN
			IF enable = '1' THEN
				temp_sum(0)  <= (OTHERS => '0');
				DSP_enable   <= '1';
				busy         <= '1';
				enable_latch <= '0';
				done         <= '0';
			END IF;
			IF DSP_enable = '1' THEN
				IF count < KERNEL_SIZE * 2 THEN -- neuron takes 2 clock cycles per MULT_ACC and 1 for the ADD
					count := count + 1;

					IF count = (KERNEL_SIZE * 2) THEN -- enable output latch
						enable_latch <= '1';
					END IF;
				ELSE
					DSP_enable   <= '0';
					busy         <= '0';
					enable_latch <= '0';
					done         <= '1';
					count := 0;
				END IF;
			END IF;
		END IF;
	END PROCESS;

END Neuron_arch;
