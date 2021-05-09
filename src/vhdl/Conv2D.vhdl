-----------------------------------------------------
-- Title: Conv2D.vhdl
-- Author: Rafael Romon/NN-1
-- DAT096 - spring 2021
-----------------------------------------------------
-- Description:
-- 
-----------------------------------------------------


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

entity Conv2D is
  GENERIC (
    INPUT_HEIGHT : INTEGER := 128;
	INPUT_WIDTH  : INTEGER := 128;
    KERNEL_HEIGHT: INTEGER := 3;
    KERNEL_WIDTH : INTEGER := 3;
    KERNEL_NUM   : INTEGER := 8
  );
  PORT (
    input  : IN  UNSIGNED((INPUT_HEIGHT*INPUT_WIDTH)-1 DOWNTO 0);
	output : OUT UNSIGNED(((INPUT_HEIGHT-1)*(INPUT_WIDTH-1))-1 DOWNTO 0)
  );
end Conv2D;

architecture Conv2D_arch of Conv2D is

begin


end Conv2D_arch;
