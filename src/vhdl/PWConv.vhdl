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

ENTITY PWConv is
GENERIC
(
  INPUT_WIDTH      : INTEGER := 128;
  INPUT_HEIGHT     : INTEGER := 128;
  INPUT_CHANNELS   : INTEGER := 8;
  FILTERS          : INTEGER := 1;
  KERNEL_HEIGHT    : INTEGER := 1;
  KERNEL_WIDTH    : INTEGER := 1;
  KERNEL_CHANNELS  : INTEGER := 8;
  IN_SIZE         : INTEGER := 8;
  OUT_SIZE         : INTEGER := 32
);
PORT
(
  clk           : IN  STD_LOGIC;
  reset_p       : IN  STD_LOGIC;
  enable        : IN  STD_LOGIC;
  input         : IN  STD_LOGIC_VECTOR((INPUT_WIDTH*INPUT_HEIGHT*IN_SIZE) - 1 DOWNTO 0);
  filter_values : IN  STD_LOGIC_VECTOR ((FILTERS*KERNEL_HEIGHT*KERNEL_WIDTH*KERNEL_CHANNELS*IN_SIZE) - 1 DOWNTO 0);
  bias_values          : IN  STD_LOGIC_VECTOR(FILTERS*OUT_SIZE - 1 DOWNTO 0);
  busy          : OUT STD_LOGIC;
  done          : OUT STD_LOGIC;
  output        : OUT STD_LOGIC_VECTOR(OUT_SIZE - 1 DOWNTO 0)
);
END PWConv;

ARCHITECTURE PWConv_arch OF PWConv IS

  TYPE IN_ARRAY IS ARRAY (0 TO (FILTERS) - 1) OF STD_LOGIC_VECTOR(KERNEL_HEIGHT*KERNEL_WIDTH*KERNEL_CHANNELS*IN_SIZE - 1 DOWNTO 0);
  TYPE OUT_ARRAY IS ARRAY (0 TO (FILTERS) - 1) OF STD_LOGIC_VECTOR(OUT_SIZE - 1 DOWNTO 0);
  TYPE ROW_ARRAY IS ARRAY (0 TO INPUT_WIDTH-1) OF STD_LOGIC_VECTOR(IN_SIZE*INPUT_WIDTH-1 DOWNTO 0);

  SIGNAL input_array    : ROW_ARRAY;
  SIGNAL filter_array   : IN_ARRAY;
  SIGNAL bias_array   : OUT_ARRAY;

  SIGNAL neuron_input   : STD_LOGIC_VECTOR(KERNEL_HEIGHT*KERNEL_WIDTH*KERNEL_CHANNELS*IN_SIZE - 1 DOWNTO 0);
  SIGNAL neuron_busy_vector  : STD_LOGIC_VECTOR(FILTERS - 1 DOWNTO 0);
  SIGNAL neuron_done_vector  : STD_LOGIC_VECTOR(FILTERS - 1 DOWNTO 0);
  SIGNAL neuron_output_array   : OUT_ARRAY;

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

  component Neuron
  generic (
  KERNEL_SIZE : INTEGER := 9;
  IN_SIZE    : INTEGER := 8;
  OUT_SIZE    : INTEGER := 32
  );
  port (
    clk           : IN  STD_LOGIC;
    reset_p       : IN  STD_LOGIC;
    enable        : IN  STD_LOGIC;
    input         : IN  STD_LOGIC_VECTOR((KERNEL_HEIGHT*KERNEL_WIDTH*KERNEL_CHANNELS*IN_SIZE) - 1 DOWNTO 0);
    filter_values : IN  STD_LOGIC_VECTOR ((KERNEL_HEIGHT*KERNEL_WIDTH*KERNEL_CHANNELS*IN_SIZE) - 1 DOWNTO 0);
    bias          : IN  STD_LOGIC_VECTOR(OUT_SIZE - 1 DOWNTO 0);
    busy          : OUT STD_LOGIC;
    done          : OUT STD_LOGIC;
    output        : OUT STD_LOGIC_VECTOR(OUT_SIZE - 1 DOWNTO 0)
  );
  end component Neuron;

begin


  line_buff: FOR i in 0 DOWNTO INPUT_WIDTH-1 GENERATE
    input_array(i) <= input((IN_SIZE*INPUT_WIDTH * (1+i)) - 1 DOWNTO (IN_SIZE*INPUT_WIDTH * i));
  END GENERATE;

  filter: FOR i in 0 to FILTERS-1 GENERATE

    filter_array(i)  <= filter_values((KERNEL_HEIGHT*KERNEL_WIDTH*KERNEL_CHANNELS*IN_SIZE * (i + 1)) - 1 DOWNTO (KERNEL_HEIGHT*KERNEL_WIDTH*KERNEL_CHANNELS*IN_SIZE * i));
    bias_array(i) <= bias_values((OUT_SIZE * (i + 1)) - 1 DOWNTO (OUT_SIZE * i));

    neuron_comp: Neuron
    generic map (
      KERNEL_SIZE => KERNEL_HEIGHT*KERNEL_WIDTH*KERNEL_CHANNELS,
      IN_SIZE     => IN_SIZE,
      OUT_SIZE    => OUT_SIZE
    )
    port map (
      clk           => clk,
      reset_p       => reset_p,
      enable        => enable,
      input         => neuron_input,
      filter_values => filter_array(i),
      bias          => bias_array(i),
      busy          => neuron_busy_vector(i),
      done          => neuron_done_vector(i),
      output        => neuron_output_array(i)
    );
  END GENERATE;

  PROCESS (clk)
    VARIABLE base_row : INTEGER := 0;
    VARIABLE base_column : INTEGER:= INPUT_WIDTH;
  BEGIN
    IF reset_p = '0' THEN
        base_row := 0;
        base_column := INPUT_WIDTH;
        done <= '0';
    ELSIF RISING_EDGE(clk) THEN
      IF enable = '1' THEN        
        IF base_row + KERNEL_HEIGHT-1 < INPUT_HEIGHT THEN
            IF base_column - (KERNEL_WIDTH+1) >= 0 THEN
                FOR row IN 0 to KERNEL_HEIGHT-1 LOOP
                    neuron_input(KERNEL_HEIGHT*(KERNEL_WIDTH-row) DOWNTO KERNEL_HEIGHT*(KERNEL_WIDTH-(row+1)))<= input_array(base_row+row)(base_column DOWNTO base_column-KERNEL_WIDTH+1);
                END LOOP;

                    base_column := base_column - 1;
                ELSE
                    base_column := INPUT_WIDTH;
                    base_row := base_row + 1;
                END IF;
            else
                done <= '1';
            END IF;
        END IF;
    END IF;
  END PROCESS;
END PWConv_arch;
