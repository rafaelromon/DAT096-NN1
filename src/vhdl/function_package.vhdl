-- function_package.vhdl
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

PACKAGE function_package IS
   TYPE hex_code_array IS
           array(7 DOWNTO 0) OF
              STD_LOGIC_VECTOR(3 DOWNTO 0);                            
   TYPE int_code_array IS
           array(7 DOWNTO 0) OF
              NATURAL RANGE 0 TO 15;
   TYPE seg_7_array IS
           array(7 DOWNTO 0) OF
              STD_LOGIC_VECTOR(6 DOWNTO 0);
   FUNCTION sevensegment(x:INTEGER)
      RETURN STD_LOGIC_VECTOR;
   FUNCTION ASCII_2_bin(x:STD_LOGIC_VECTOR)
      RETURN INTEGER;
   FUNCTION ASCII_2_hex(x:STD_LOGIC_VECTOR)
      RETURN STD_LOGIC_VECTOR;
   FUNCTION sl2slv(sl:STD_LOGIC)
      RETURN STD_LOGIC_VECTOR;
   FUNCTION DATA_WIDTH_func(DW:INTEGER)
      RETURN INTEGER;   
   FUNCTION APP_DATA_WIDTH_func(DW:INTEGER)
      RETURN INTEGER;
   FUNCTION DQS_SIZE_func(DW:INTEGER)
     RETURN INTEGER;
   FUNCTION DM_SIZE_func(DW:INTEGER)
     RETURN INTEGER;

END function_package;

PACKAGE BODY function_package IS
   FUNCTION sevensegment(x:INTEGER)
      RETURN STD_LOGIC_VECTOR IS
   BEGIN
      IF (x=0) THEN
         RETURN "1000000";
      ELSIF (x=1) THEN
         RETURN "1111001";
      ELSIF (x=2) THEN
         RETURN "0100100";
      ELSIF (x=3) THEN
         RETURN "0110000";
      ELSIF (x=4) THEN
         RETURN "0011001";
      ELSIF (x=5) THEN
         RETURN "0010010";
      ELSIF (x=6) THEN
         RETURN "0000010";
      ELSIF (x=7) THEN
         RETURN "1111000";
      ELSIF (x=8) THEN
         RETURN "0000000";
      ELSIF (x=9) THEN
         RETURN "0011000";
      ELSIF (x=10) THEN
         RETURN "0001000";
      ELSIF (x=11) THEN
         RETURN "0000011";
      ELSIF (x=12) THEN
         RETURN "1000110";
      ELSIF (x=13) THEN
         RETURN "0100001";
      ELSIF (x=14) THEN
         RETURN "0000110";
      ELSIF (x=15) THEN
         RETURN "0001110";
      ELSE RETURN "1010101";
      END IF;
   END  sevensegment;
   
   FUNCTION ASCII_2_bin(x:STD_LOGIC_VECTOR)
      RETURN INTEGER IS
      VARIABLE x_natural:INTEGER;
      VARIABLE x_natural_minus:INTEGER;
   BEGIN
      x_natural:=TO_INTEGER(UNSIGNED(x));
      x_natural_minus:=x_natural-48;
      IF (x_natural_minus<10) THEN
         RETURN x_natural_minus;
      ELSIF ((x_natural=65) OR x_natural=97) THEN
         RETURN 10;
      ELSIF ((x_natural=66) OR x_natural=98) THEN
         RETURN 11;
      ELSIF ((x_natural=67) OR x_natural=99) THEN
         RETURN 12;
      ELSIF ((x_natural=68) OR x_natural=100) THEN
         RETURN 13;
      ELSIF ((x_natural=69) OR x_natural=101) THEN
         RETURN 14;
      ELSIF ((x_natural=70) OR x_natural=101) THEN
         RETURN 15;
      ELSE
         RETURN 15;
      END IF;
   END ASCII_2_bin;

   FUNCTION ASCII_2_hex(x:STD_LOGIC_VECTOR)
      RETURN STD_LOGIC_VECTOR IS
   BEGIN
      RETURN STD_LOGIC_VECTOR(TO_UNSIGNED(ASCII_2_bin(x),4));
   END ASCII_2_hex;

   FUNCTION sl2slv(sl:STD_LOGIC)
      RETURN STD_LOGIC_VECTOR IS
      VARIABLE slv:STD_LOGIC_VECTOR(0 DOWNTO 0);
   BEGIN
      slv(0) := sl;
      RETURN slv;
   END sl2slv;

FUNCTION APP_DATA_WIDTH_func(DW:INTEGER)
    RETURN INTEGER IS
  BEGIN
	IF (DW = 64) THEN
		RETURN 512;
	ELSIF (DW = 32) THEN
		RETURN 256;
	ELSIF (DW = 16) THEN
		RETURN 128;
	ELSE
		RETURN 64;
	END IF;
  END FUNCTION;

FUNCTION DATA_WIDTH_func(DW:INTEGER)
    RETURN INTEGER IS
  BEGIN
	IF (DW = 64) THEN
		RETURN 64;
	ELSIF (DW = 32) THEN
		RETURN 32;
    ELSIF (DW = 16) THEN
        RETURN 16;
    ELSE
        RETURN 8;
    END IF;
  END FUNCTION;
  
  FUNCTION DQS_SIZE_func(DW:INTEGER)
     RETURN INTEGER IS
  BEGIN
	IF (DW = 64) THEN
		RETURN 8;
	ELSIF (DW = 32) THEN
		RETURN 4;
    ELSIF (DW = 16) THEN
        RETURN 2;
    ELSE
        RETURN 1;
    END IF;
  END FUNCTION;
  
  FUNCTION DM_SIZE_func(DW:INTEGER) 
     RETURN INTEGER IS
  BEGIN
	IF (DW = 64) THEN
		RETURN 8;
	ELSIF (DW = 32) THEN
		RETURN 4;
    ELSIF (DW = 16) THEN
        RETURN 2;
    ELSE
        RETURN 1;
    END IF;
  END FUNCTION;

END function_package;