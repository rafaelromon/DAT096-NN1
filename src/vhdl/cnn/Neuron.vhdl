-----------------------------------------------------
-- Title: Neuron.vhdl
-- Author: Rafael Romon/NN-1
-- DAT096 - spring 2021
-----------------------------------------------------
-- Description:
-- Implements a Neuron model using DPS blocks includes
-- adding bias, passing through ReLu, multiplying by
-- scale and truncating size.
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
		KERNEL_HEIGHT : INTEGER := 3;
		KERNEL_WIDTH  : INTEGER := 3;
		KERNEL_DEPTH  : INTEGER := 1;
		IO_SIZE       : INTEGER := 8; -- integer sizes for input and output
		INTERNAL_SIZE : INTEGER := 32 -- integer size for internal operations
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
END Neuron;

ARCHITECTURE Neuron_arch OF Neuron IS

	TYPE states IS (Idle, Mult, Accumulate, AddBias, Activation, MultScale, WaitMacc, OutputResult);
	SIGNAL state_machine : states := Idle;

	-----
	-- Reg component and signals
	-----

	TYPE LINE_ARRAY IS ARRAY (0 TO KERNEL_HEIGHT - 1) OF STD_LOGIC_VECTOR(KERNEL_WIDTH * KERNEL_DEPTH * IO_SIZE - 1 DOWNTO 0);
	SIGNAL input_array   : LINE_ARRAY;
	SIGNAL filter_array  : LINE_ARRAY;

	SIGNAL output_enable : STD_LOGIC;
	SIGNAL output_signal : STD_LOGIC_VECTOR(IO_SIZE - 1 DOWNTO 0);

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

	-----
	-- DSP48 MACC and ADD signals
	-----

	TYPE IO_ARRAY IS ARRAY (0 TO KERNEL_HEIGHT - 1) OF STD_LOGIC_VECTOR(IO_SIZE - 1 DOWNTO 0);
	TYPE INTERNAL_ARRAY IS ARRAY (0 TO KERNEL_HEIGHT - 1) OF STD_LOGIC_VECTOR(INTERNAL_SIZE - 1 DOWNTO 0);

	SIGNAL macc_a_array   : IO_ARRAY;
	SIGNAL macc_b_array   : IO_ARRAY;
	SIGNAL macc_out_array : INTERNAL_ARRAY;
	SIGNAL macc_enable      : STD_LOGIC := '0';
	SIGNAL macc_load      : STD_LOGIC := '1';

	SIGNAL add_a          : STD_LOGIC_VECTOR(INTERNAL_SIZE - 1 DOWNTO 0);
	SIGNAL add_b          : STD_LOGIC_VECTOR(INTERNAL_SIZE - 1 DOWNTO 0);
	SIGNAL add_out        : STD_LOGIC_VECTOR(INTERNAL_SIZE - 1 DOWNTO 0);
	SIGNAL add_enable      : STD_LOGIC := '0';

	-----
	-- ReLu component and signals
	-----

	SIGNAL relu_out        : STD_LOGIC_VECTOR(INTERNAL_SIZE - 1 DOWNTO 0);

	component ReLu
	generic (
  	INT_SIZE : INTEGER := 32
	);
	port (
  	clk     : IN  STD_LOGIC;
  	enable  : IN  STD_LOGIC;
  	reset_p : IN  STD_LOGIC;
  	input   : IN  STD_LOGIC_VECTOR(INT_SIZE - 1 DOWNTO 0);
  	output  : OUT STD_LOGIC_VECTOR(INT_SIZE - 1 DOWNTO 0)
	);
	end component ReLu;

	-----
	-- Residual signals from attempted scaling implementation
	-----

  SIGNAL mult_out        : STD_LOGIC_VECTOR(INTERNAL_SIZE*2 - 1 DOWNTO 0);

BEGIN

	-- Output Register
	Reg_output : Reg GENERIC
	MAP (
	SIG_WIDTH => IO_SIZE
	)
	PORT MAP
	(
		clk     => clk,
		reset_p => reset_p,
		enable  => '1',
		input   => output_signal,
		output  => output
	);

	-- Creates one line buffers for input and filters and macc per row
	row : FOR i IN 0 TO KERNEL_HEIGHT - 1 GENERATE

		input_line : Reg
		GENERIC
		MAP(
		SIG_WIDTH => IO_SIZE * KERNEL_HEIGHT * KERNEL_DEPTH
		)
		PORT
		MAP
		(
		clk     => clk,
		reset_p => reset_p,
		enable  => '1',
		input   => input(IO_SIZE * KERNEL_WIDTH * KERNEL_DEPTH * (KERNEL_HEIGHT - i) - 1 DOWNTO IO_SIZE * KERNEL_WIDTH * KERNEL_DEPTH * (KERNEL_HEIGHT - (i + 1))),
		output  => input_array(i)
		);

		filter_line : Reg
		GENERIC
		MAP(
		SIG_WIDTH => IO_SIZE * KERNEL_HEIGHT * KERNEL_DEPTH
		)
		PORT
		MAP
		(
		clk     => clk,
		reset_p => reset_p,
		enable  => '1',
		input   => filter_values(IO_SIZE * KERNEL_WIDTH * KERNEL_DEPTH * (KERNEL_HEIGHT - i) - 1 DOWNTO IO_SIZE * KERNEL_WIDTH * KERNEL_DEPTH * (KERNEL_HEIGHT - (i + 1))),
		output  => filter_array(i)
		);

		macc_comp : MACC_MACRO
		GENERIC
		MAP (
		DEVICE  => "7SERIES",     -- Target Device: "VIRTEX5", "7SERIES", "SPARTAN6"
		LATENCY => 1,             -- Desired clock cycle latency, 1-4
		WIDTH_A => IO_SIZE,       -- Multiplier A-input bus width, 1-25
		WIDTH_B => IO_SIZE,       -- Multiplier B-input bus width, 1-18
		WIDTH_P => INTERNAL_SIZE) -- Accumulator output bus width, 1-48
		PORT
		MAP (
		P       => macc_out_array(i), -- MACC ouput bus, width determined by WIDTH_P generic
		A       => macc_a_array(i),   -- Multiplier input A bus, width determined by WIDTH_A generic
		ADDSUB  => '1',               -- 1-bit add/sub input, high selects add, low selects subtract
		B       => macc_b_array(i),   -- Multiplier input B bus, width determined by WIDTH_B generic
		CARRYIN => '0',               -- 1-bit carry-in input to accumulator
		CE      => macc_enable,               -- 1-bit active high input clock enable
		CLK     => clk,               -- 1-bit positive edge clock input
		LOAD    => macc_load,         -- 1-bit active high input load accumulator enable
		LOAD_DATA => (OTHERS => '0'), -- Load accumulator input data, width determined by WIDTH_A generic
		RST     => reset_p            -- 1-bit input active high reset
		);

	END GENERATE;

	add_comp: ADDSUB_MACRO
	GENERIC
	MAP (
	DEVICE  => "7SERIES",     -- Target Device: "VIRTEX5", "7SERIES", "SPARTAN6"
	LATENCY => 0,             -- Desired clock cycle latency, 0-2
	WIDTH   => INTERNAL_SIZE) -- Input / Output bus width, 1-48
	PORT
	MAP (
	CARRYOUT => OPEN,    -- 1-bit carry-out output signal
	RESULT   => add_out, -- Add/sub result output, width defined by WIDTH generic
	A        => add_a,   -- Input A bus, width defined by WIDTH generic
	ADD_SUB  => '1',     -- 1-bit add/sub input, high selects add, low selects subtract
	B        => add_b,   -- Input B bus, width defined by WIDTH generic
	CARRYIN  => '0',     -- 1-bit carry-in input
	CE       => add_enable,     -- 1-bit clock enable input
	CLK      => clk,     -- 1-bit clock input
	RST      => reset_p  -- 1-bit active high synchronous reset
	);

	ReLu_comp : ReLu
	generic map (
	  INT_SIZE => INTERNAL_SIZE
	)
	port map (
	  clk     => clk,
	  enable  => '1',
	  reset_p => reset_p,
	  input   => add_out,
	  output  => relu_out
	);

	PROCESS (clk)
		VARIABLE line_index : INTEGER := KERNEL_WIDTH * KERNEL_DEPTH;
		VARIABLE acc_count : INTEGER := 0;
		VARIABLE wait_clk: STD_LOGIC := '0';
	BEGIN
		IF reset_p = '1' THEN
			busy          <= '0';
			done          <= '0';
			macc_enable   <= '0';
			add_enable    <= '0';
			macc_load     <= '1';
			output_signal <= (OTHERS => '0');

		ELSIF RISING_EDGE(clk) THEN
			CASE state_machine IS
				WHEN Idle =>
					line_index := KERNEL_WIDTH * KERNEL_DEPTH;

					IF start = '1' THEN
						busy          <= '1';
						done          <= '0';
						state_machine <= WaitMacc;
					END IF;

				WHEN WaitMacc => -- empty macc_buffer and wait for it to start
						macc_enable   <= '1';

	        	IF wait_clk = '0' THEN -- this is a really dirty implementation
							FOR i IN 0 TO KERNEL_HEIGHT - 1 LOOP
								macc_a_array(i) <= (OTHERS => '0');
								macc_b_array(i) <= (OTHERS => '0');
							END LOOP;

							wait_clk := '1';

						ELSE
							wait_clk := '0';
							macc_load <= '0'; -- start accumulating
							state_machine <= Mult;

						END IF;

				WHEN Mult => -- multiply and accumulate elements within a row

					FOR i IN 0 TO KERNEL_HEIGHT - 1 LOOP
						macc_a_array(i) <= input_array(i)((IO_SIZE * line_index) - 1 DOWNTO IO_SIZE * (line_index - 1));
						macc_b_array(i) <= filter_array(i)((IO_SIZE * line_index) - 1 DOWNTO IO_SIZE * (line_index - 1));
					END LOOP;

					IF line_index > 1 THEN
						line_index := line_index - 1;
					ELSE
							state_machine <= Accumulate;
					END IF;

				WHEN Accumulate => -- accumulate results from different rows
					add_enable <= '1';
					macc_enable   <= '0';

					IF wait_clk = '0' THEN -- this is a really dirty implementation
						wait_clk := '1';

					ELSE
						if acc_count = 0 THEN
								add_a <= macc_out_array(0);
								add_b <= macc_out_array(1);
									acc_count := 1;

						ELSE
								add_a <= add_out;
								add_b <= macc_out_array(acc_count);
						END IF;

						IF acc_count < KERNEL_HEIGHT-1 THEN
							acc_count := acc_count + 1;

						ELSE
							wait_clk := '0';
							state_machine <= AddBias;
						END IF;
					END IF;

				WHEN AddBias    => -- reuses adder to add bias
					add_a <= add_out;
					add_b <= bias;
					add_enable <= '0';
					state_machine <= Activation;

				WHEN Activation => -- waits for ReLu to work
					IF wait_clk = '0' THEN -- this is a really dirty implementation
						wait_clk := '1';
					ELSE
						wait_clk := '0';
						state_machine <= MultScale;
					END IF;

				WHEN MultScale =>  -- TODO implement scaling
			    mult_out <= (OTHERS => '0');
					mult_out(INTERNAL_SIZE - 1 DOWNTO 0) <= relu_out;
					state_machine <= OutputResult;

				WHEN OutputResult => -- truncates to int8 and outputs
					output_signal <= mult_out(IO_SIZE - 1 DOWNTO 0); --truncate to output size

					IF wait_clk = '0' THEN -- this is a really dirty implementation
						wait_clk := '1';
					ELSE
						wait_clk := '0';
						busy          <= '0';
						done          <= '1';
						output_enable <= '1';
						state_machine <= Idle;
					END IF;

			END CASE;
		END IF;
	END PROCESS;

END Neuron_arch;
