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
  NEURON_NUM       : INTEGER := 1;
  IN_SIZE          : INTEGER := 8;
  OUT_SIZE         : INTEGER := 32
);

PORT(
  clk           : IN  STD_LOGIC;
  reset_p       : IN  STD_LOGIC;
  start        : IN  STD_LOGIC;
  input         : IN  STD_LOGIC_VECTOR((INPUT_NUM*IN_SIZE) - 1 DOWNTO 0);
  weight_values : IN  STD_LOGIC_VECTOR((INPUT_NUM*NEURON_NUM*IN_SIZE) - 1 DOWNTO 0);
  bias_values   : IN  STD_LOGIC_VECTOR(NEURON_NUM*OUT_SIZE - 1 DOWNTO 0);
  busy          : OUT STD_LOGIC;
  done          : OUT STD_LOGIC;
  output        : OUT STD_LOGIC_VECTOR(NEURON_NUM*IN_SIZE - 1 DOWNTO 0)
);
END FullyConnect;

ARCHITECTURE FullyConnect_arch OF FullyConnect IS


    --  TYPE IN_ARRAY 	IS ARRAY (0 TO INPUT_NUM - 1) OF STD_LOGIC_VECTOR(IN_SIZE - 1 DOWNTO 0);
  TYPE IN_ARRAY 	IS ARRAY (0 TO NEURON_NUM-1) OF STD_LOGIC_VECTOR(IN_SIZE-1 DOWNTO 0);
  TYPE FILTER_ARRAY IS ARRAY (0 TO NEURON_NUM-1) OF STD_LOGIC_VECTOR(INPUT_NUM*IN_SIZE-1 DOWNTO 0);
  --TYPE OUT_ARRAY 	IS ARRAY (0 TO NEURON_NUM-1) OF STD_LOGIC_VECTOR(OUT_SIZE-1 DOWNTO 0);
  TYPE OUT_ARRAY 	IS ARRAY (0 TO NEURON_NUM-1) OF STD_LOGIC_VECTOR(OUT_SIZE-1 DOWNTO 0);
  

--  SIGNAL input_array    : IN_ARRAY;
  SIGNAL weight_array   : FILTER_ARRAY;
  SIGNAL bias_array     : OUT_ARRAY;
  
--  SIGNAL neuron_input        : STD_LOGIC_VECTOR(INPUT_NUM*IN_SIZE - 1 DOWNTO 0);
  SIGNAL neuron_busy_vector  : STD_LOGIC_VECTOR(NEURON_NUM-1 DOWNTO 0);
  SIGNAL busy_out			 : STD_LOGIC_VECTOR(NEURON_NUM-1 DOWNTO 0);
  SIGNAL neuron_done_vector  : STD_LOGIC_VECTOR(NEURON_NUM-1 DOWNTO 0);
  SIGNAL done_out			 : STD_LOGIC_VECTOR(NEURON_NUM-1 DOWNTO 0);
  SIGNAL neuron_output_array : IN_ARRAY; 
  SIGNAL pre_output          : STD_LOGIC_VECTOR(IN_SIZE-1 DOWNTO 0);        --Not really sure about this one

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
		GENERIC
		(
			KERNEL_HEIGHT : INTEGER := 9;
			KERNEL_WIDTH  : INTEGER := 1;
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
	END COMPONENT Neuron;


BEGIN

--  init_input_array: FOR i IN 0 TO INPUT_NUM-1 GENERATE
--    input_array(i) <= input( ((i+1)*IN_SIZE-1) DOWNTO (i*IN_SIZE) );
--  END GENERATE; 
  
  Neuron_operation: FOR i IN 0 TO NEURON_NUM-1 GENERATE
    weight_array(i)  <= weight_values( ((i+1)*IN_SIZE*INPUT_NUM-1) DOWNTO (i*IN_SIZE*INPUT_NUM) );
    bias_array(i)    <= bias_values( ((i+1)*OUT_SIZE-1) DOWNTO (i*OUT_SIZE) );
    --bias_array(i) <= bias_values( ((i+1)*IN_SIZE-1) DOWNTO (i*IN_SIZE) );

    neuron_comp: Neuron
    generic map (
        KERNEL_HEIGHT   => 1,
        KERNEL_WIDTH    => 1,   
        KERNEL_DEPTH    => 9,  -- This needs to be 9 as to not mess with the data width of the registers in Neuron.vhdl
        IO_SIZE         => IN_SIZE,   
        INTERNAL_SIZE   => OUT_SIZE
    )
    port map (
      clk           => clk,
      reset_p       => reset_p,
      start         => start,
      input         => input,
      filter_values => weight_array(i),
      bias          => bias_array(i),
      scale         => x"FFFFFFFF",
      busy          => neuron_busy_vector(i),
      done          => neuron_done_vector(i),
      output        => neuron_output_array(i)
    );
    
  END GENERATE;

  -- I might be oversimplifying things but this is how I imagine this would continue
  
  done_out(0) <= neuron_done_vector(0);
  
  Anding_done: FOR i IN 1 TO NEURON_NUM-1 GENERATE
	done_out(i) <= neuron_done_vector(i) AND done_out(i-1);
  END GENERATE;
  
  -- Anding the busy
  busy_out(0) <= neuron_busy_vector(0);
  
  Anding_busy: FOR i IN 1 TO NEURON_NUM-1 GENERATE
	busy_out(i) <= neuron_busy_vector(i) AND busy_out(i-1);
  END GENERATE;
  
  Output_remapping: FOR i IN 0 TO NEURON_NUM-1 GENERATE
    --output((i+1)*OUT_SIZE-1 DOWNTO i*OUT_SIZE) <= neuron_output_array(i);   
    pre_output((i+1)*IN_SIZE-1 DOWNTO i*IN_SIZE) <= neuron_output_array(i);   
  END GENERATE;
 
  busy 	 <= busy_out(NEURON_NUM-1);
  done 	 <= done_out(NEURON_NUM-1);
  
  output_reg: reg
  GENERIC MAP(
    SIG_WIDTH => IN_SIZE
  )
  PORT MAP(
    clk => clk,
    reset_p => reset_p,
    enable => '1',
    input => pre_output,
    output => output
  );

END FullyConnect_arch;
