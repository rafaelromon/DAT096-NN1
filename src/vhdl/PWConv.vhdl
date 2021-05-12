-----------------------------------------------------
-- Title: PWConv.vhdl
-- Author: Rafael Romon/NN-1
-- DAT096 - spring 2021
-----------------------------------------------------
-- Description:
-- TODO:
-- Channels are not implemented
-----------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY PWConv IS
	GENERIC
	(
		INPUT_WIDTH     : INTEGER := 128;
		INPUT_HEIGHT    : INTEGER := 128;
		INPUT_CHANNELS  : INTEGER := 1; -- TODO implement channels
		FILTERS         : INTEGER := 1;
		KERNEL_HEIGHT   : INTEGER := 1;
		KERNEL_WIDTH    : INTEGER := 1;
		KERNEL_CHANNELS : INTEGER := 8;
		STRIDE          : INTEGER := 1;
		IN_SIZE         : INTEGER := 8;
		OUT_SIZE        : INTEGER := 32
	);
	PORT
	(
		clk           : IN  STD_LOGIC;
		reset_p       : IN  STD_LOGIC;
		start        : IN  STD_LOGIC;
		input         : IN  STD_LOGIC_VECTOR((INPUT_WIDTH * INPUT_HEIGHT * IN_SIZE) - 1 DOWNTO 0);
		filter_values : IN  STD_LOGIC_VECTOR ((FILTERS * KERNEL_HEIGHT * KERNEL_WIDTH * KERNEL_CHANNELS * IN_SIZE) - 1 DOWNTO 0);
		bias_values   : IN  STD_LOGIC_VECTOR(FILTERS * OUT_SIZE - 1 DOWNTO 0);
		busy          : OUT STD_LOGIC;
		done          : OUT STD_LOGIC;
		output        : OUT STD_LOGIC_VECTOR((INPUT_WIDTH * INPUT_HEIGHT * OUT_SIZE) - 1 DOWNTO 0)
	);
END PWConv;

ARCHITECTURE PWConv_arch OF PWConv IS

  TYPE states IS (Idle, WaitBuffer, WaitNeuron, SaveOutput);
	SIGNAL state_machine : states := Idle;

	signal output_signal: STD_LOGIC_VECTOR((INPUT_WIDTH * INPUT_HEIGHT * OUT_SIZE) - 1 DOWNTO 0);
	signal output_enable: STD_LOGIC := '0';

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

    SIGNAL line_start : STD_LOGIC;
    SIGNAL line_move : STD_LOGIC;
    SIGNAL line_busy : STD_LOGIC;
    SIGNAL line_done : STD_LOGIC;

	COMPONENT LINE_BUFF
		GENERIC
		(
			INPUT_WIDTH    : INTEGER := 128;
			INPUT_HEIGHT   : INTEGER := 128;
			INPUT_CHANNELS : INTEGER := 8;
			KERNEL_WIDTH   : INTEGER := 3;
			KERNEL_HEIGHT  : INTEGER := 3;
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
			done    : OUT STD_LOGIC;
			output  : OUT STD_LOGIC_VECTOR((KERNEL_HEIGHT * KERNEL_WIDTH * INTEGER_SIZE) - 1 DOWNTO 0)
		);
	END COMPONENT LINE_BUFF;

	TYPE IN_ARRAY IS ARRAY (0 TO (FILTERS) - 1) OF STD_LOGIC_VECTOR(KERNEL_HEIGHT * KERNEL_WIDTH * KERNEL_CHANNELS * IN_SIZE - 1 DOWNTO 0);
	TYPE OUT_ARRAY IS ARRAY (0 TO (FILTERS) - 1) OF STD_LOGIC_VECTOR(OUT_SIZE - 1 DOWNTO 0);

	SIGNAL filter_array        : IN_ARRAY;
	SIGNAL bias_array          : OUT_ARRAY;

	SIGNAL neuron_start        : STD_LOGIC := '0';
	SIGNAL neuron_input        : STD_LOGIC_VECTOR(KERNEL_HEIGHT * KERNEL_WIDTH * KERNEL_CHANNELS * IN_SIZE - 1 DOWNTO 0);
	SIGNAL neuron_busy_vector  : STD_LOGIC_VECTOR(FILTERS - 1 DOWNTO 0);
	SIGNAL neuron_done_vector  : STD_LOGIC_VECTOR(FILTERS - 1 DOWNTO 0);
	SIGNAL neuron_output_array : OUT_ARRAY;

	COMPONENT Neuron
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
			input         : IN  STD_LOGIC_VECTOR((KERNEL_HEIGHT * KERNEL_WIDTH * KERNEL_CHANNELS * IN_SIZE) - 1 DOWNTO 0);
			filter_values : IN  STD_LOGIC_VECTOR ((KERNEL_HEIGHT * KERNEL_WIDTH * KERNEL_CHANNELS * IN_SIZE) - 1 DOWNTO 0);
			bias          : IN  STD_LOGIC_VECTOR(OUT_SIZE - 1 DOWNTO 0);
			busy          : OUT STD_LOGIC;
			done          : OUT STD_LOGIC;
			output        : OUT STD_LOGIC_VECTOR(OUT_SIZE - 1 DOWNTO 0)
		);
	END COMPONENT Neuron;

BEGIN

		output_buff : Reg
		GENERIC
		MAP(
		SIG_WIDTH => INPUT_WIDTH * INPUT_HEIGHT * OUT_SIZE
		)
		PORT MAP
		(
			clk     => clk,
			reset_p => reset_p,
			enable  => output_enable,
			input   => output_signal,
			output  => output
		);

    LINE_BUFF_i : LINE_BUFF
    generic map (
        INPUT_WIDTH    => INPUT_WIDTH,
        INPUT_HEIGHT   => INPUT_HEIGHT,
        INPUT_CHANNELS => INPUT_CHANNELS,
        KERNEL_WIDTH   => KERNEL_WIDTH,
        KERNEL_HEIGHT  => KERNEL_HEIGHT,
        STRIDE         => STRIDE,
        INTEGER_SIZE   => IN_SIZE
    )
    port map (
        clk     => clk,
        reset_p => reset_p,
        start   => line_start,
        move    => line_move,
        input   => input,
        busy    => line_busy,
        done    => line_done,
        output  => neuron_input
    );


	filter : FOR i IN 0 TO FILTERS - 1 GENERATE

		filter_array(i) <= filter_values((KERNEL_HEIGHT * KERNEL_WIDTH * KERNEL_CHANNELS * IN_SIZE * (i + 1)) - 1 DOWNTO (KERNEL_HEIGHT * KERNEL_WIDTH * KERNEL_CHANNELS * IN_SIZE * i));
		bias_array(i)   <= bias_values((OUT_SIZE * (i + 1)) - 1 DOWNTO (OUT_SIZE * i));

		neuron_comp : Neuron
		GENERIC
		MAP(
		KERNEL_SIZE => KERNEL_HEIGHT * KERNEL_WIDTH * KERNEL_CHANNELS,
		IN_SIZE     => IN_SIZE,
		OUT_SIZE    => OUT_SIZE
		)
		PORT
		MAP(
		clk           => clk,
		reset_p       => reset_p,
		enable        => neuron_start,
		input         => neuron_input,
		filter_values => filter_array(i),
		bias          => bias_array(i),
		busy          => neuron_busy_vector(i),
		done          => neuron_done_vector(i),
		output        => neuron_output_array(i)
		);
	END GENERATE;

	PROCESS (clk)
		variable output_index: INTEGER := INPUT_HEIGHT*INPUT_WIDTH;
	BEGIN
		IF reset_p = '1' THEN
			done          <= '0';
			output_enable <= '1';
			neuron_start  <= '0';
			line_start    <= '0';
			line_move    <= '0';
			output_signal <= (OTHERS => '0');
		ELSIF RISING_EDGE(clk) THEN
			CASE state_machine IS
				WHEN Idle =>
					output_index     := INPUT_HEIGHT*INPUT_WIDTH;
					busy          <= '0';

				  IF line_done = '1' THEN
						done <= '1';
					END IF;
					IF start = '1' THEN
						line_start    <= '1';
						busy          <= '1';
						done          <= '0';
						output_enable <= '0';
						state_machine <= WaitBuffer;
					END IF;
				WHEN WaitBuffer =>
				        line_start    <= '0';
                        line_move    <= '0';
                        
						IF line_busy = '0' THEN
								neuron_start <= '1';
								state_machine <= WaitNeuron;
						END IF;
				WHEN WaitNeuron =>
						if neuron_done_vector(0) = '1' THEN -- all neurons finish at the same time
							neuron_start  <= '0';
							state_machine <= SaveOutput;
						END IF;
				WHEN SaveOutput =>

					-- TODO only supports 1 filter
					output_signal((OUT_SIZE*output_index)-1 DOWNTO OUT_SIZE*(output_index-1)) <= neuron_output_array(0);

					IF line_done = '1' THEN							
							output_enable <= '1';
							state_machine <= Idle;
					else
					    line_move    <= '1';
						output_index := output_index - 1;
						state_machine <= WaitBuffer;
					END IF;
    			END CASE;
    		END IF;
	END PROCESS;
END PWConv_arch;
