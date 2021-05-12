-----------------------------------------------------
-- Title: FullyConnect.vhdl
-- Author: Johan Nilsson/NN-1
-- DAT096 - spring 2021
-----------------------------------------------------
-- Description:
-- The full connection (dense) layer are the last 
-- layers of the CNN where the input vector is reduced
-- into just a few elements in a vector
-----------------------------------------------------
-- ToDo
-- Implement quant so that the output is convertet from
-- int32 back to int8
-----------------------------------------------------


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY FullyConnect IS
GENERIC(
  INPUT_NUM        : INTEGER := 9;
  NEURON_NUM       : INTEGER := 2;
  IN_SIZE          : INTEGER := 8;
  OUT_SIZE         : INTEGER := 32
);

PORT(
  clk           : IN  STD_LOGIC;
  reset_p       : IN  STD_LOGIC;
  enable        : IN  STD_LOGIC;
  input         : IN  STD_LOGIC_VECTOR((INPUT_NUM*IN_SIZE) - 1 DOWNTO 0);
  weight_values : IN  STD_LOGIC_VECTOR((INPUT_NUM*NEURON_NUM*IN_SIZE) - 1 DOWNTO 0);
  bias_values   : IN  STD_LOGIC_VECTOR(NEURON_NUM*OUT_SIZE - 1 DOWNTO 0);
  busy          : OUT STD_LOGIC;
  done          : OUT STD_LOGIC;
  output        : OUT STD_LOGIC_VECTOR(NEURON_NUM*OUT_SIZE - 1 DOWNTO 0)
);
END FullyConnect;

ARCHITECTURE FullyConnect_arch OF FullyConnect IS


  TYPE IN_ARRAY 	IS ARRAY (0 TO INPUT_NUM - 1) OF STD_LOGIC_VECTOR(IN_SIZE - 1 DOWNTO 0);
  TYPE FILTER_ARRAY IS ARRAY (0 TO NEURON_NUM-1) OF STD_LOGIC_VECTOR(INPUT_NUM*IN_SIZE-1 DOWNTO 0);
  TYPE OUT_ARRAY 	IS ARRAY (0 TO NEURON_NUM - 1) OF STD_LOGIC_VECTOR(OUT_SIZE - 1 DOWNTO 0);

  SIGNAL input_array    : IN_ARRAY;
  SIGNAL weight_array   : FILTER_ARRAY;
  SIGNAL bias_array     : OUT_ARRAY;
  
--  SIGNAL neuron_input        : STD_LOGIC_VECTOR(INPUT_NUM*IN_SIZE - 1 DOWNTO 0);
  SIGNAL neuron_busy_vector  : STD_LOGIC_VECTOR(NEURON_NUM - 1 DOWNTO 0);
  SIGNAL neuron_done_vector  : STD_LOGIC_VECTOR(NEURON_NUM - 1 DOWNTO 0);
  SIGNAL neuron_output_array : OUT_ARRAY; 


  COMPONENT Reg
    GENERIC(
        SIG_WIDTH : INTEGER := 8
        );
    PORT(
	   clk     : IN  STD_LOGIC;
	   reset_p : IN  STD_LOGIC;
	   enable  : IN  STD_LOGIC;
	   input   : IN  STD_LOGIC_VECTOR(SIG_WIDTH - 1 DOWNTO 0);
	   output  : OUT STD_LOGIC_VECTOR(SIG_WIDTH - 1 DOWNTO 0)
	   );
  END COMPONENT Reg;


  COMPONENT Neuron
    GENERIC (
        KERNEL_SIZE : INTEGER := 9;
        IN_SIZE    : INTEGER := 8;
        OUT_SIZE    : INTEGER := 32
        );
    PORT (
        clk           : IN  STD_LOGIC;
        reset_p       : IN  STD_LOGIC;
        enable        : IN  STD_LOGIC;
        input         : IN  STD_LOGIC_VECTOR((KERNEL_SIZE*IN_SIZE) - 1 DOWNTO 0);
        filter_values : IN  STD_LOGIC_VECTOR((KERNEL_SIZE*IN_SIZE) - 1 DOWNTO 0);
        bias          : IN  STD_LOGIC_VECTOR(OUT_SIZE - 1 DOWNTO 0);
        busy          : OUT STD_LOGIC;
        done          : OUT STD_LOGIC;
        output        : OUT STD_LOGIC_VECTOR(OUT_SIZE - 1 DOWNTO 0)
        );
  END COMPONENT Neuron;


BEGIN

  init_input_array: FOR i IN 0 TO INPUT_NUM-1 GENERATE
    input_array(i) <= input( ((i+1)*IN_SIZE-1) DOWNTO (i*IN_SIZE) );
  END GENERATE; 
  
  Neuron_operation: FOR i IN 0 TO NEURON_NUM-1 GENERATE
    weight_array(i)  <= weight_values( ((i+1)*IN_SIZE*INPUT_NUM-1) DOWNTO (i*IN_SIZE*INPUT_NUM) );
    bias_array(i) <= bias_values( ((i+1)*OUT_SIZE-1) DOWNTO (i*OUT_SIZE) );

    neuron_comp: Neuron
    generic map (
      KERNEL_SIZE => INPUT_NUM,
      IN_SIZE     => IN_SIZE,
      OUT_SIZE    => OUT_SIZE
    )
    port map (
      clk           => clk,
      reset_p       => reset_p,
      enable        => enable,
      input         => input_array(i),
      filter_values => weight_array(i),
      bias          => bias_array(i),
      busy          => neuron_busy_vector(i),
      done          => neuron_done_vector(i),
      output        => neuron_output_array(i)
    );
  END GENERATE;

  -- BusyDone : PROCESS(clk)
  -- BEGIN
  -- END;

END FullyConnect_arch;
