-----------------------------------------------------
-- Title: IMG_BUFF_.vhdl
-- Author: Rafael Romon/NN-1
-- DAT096 - spring 2021
-----------------------------------------------------
-- Description:
--
-----------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY IMG_BUFFER_CONTROLLER IS
	GENERIC (
		ROW_WIDTH: INTEGER := 4096;
		IMAGE_DEPTH : INTEGER := 4;		
		ADDR_WIDTH : INTEGER := 9
	);
	PORT (
		clk : IN STD_LOGIC; -- clock signal
		reset_p : IN STD_LOGIC; -- reset signal active high
		start : IN STD_LOGIC; -- signal to start reading new image
		busy : OUT STD_LOGIC; -- signal indicating controller is busy reading new image
		image : OUT STD_LOGIC_VECTOR((ROW_WIDTH*IMAGE_DEPTH) - 1 DOWNTO 0) -- output image
	);
END IMG_BUFFER_CONTROLLER;

ARCHITECTURE IMG_BUFFER_CONTROLLER_arch OF IMG_BUFFER_CONTROLLER IS

	SIGNAL base_addr : INTEGER := 0;
	SIGNAL temp_img : STD_LOGIC_VECTOR((ROW_WIDTH*IMAGE_DEPTH) - 1 DOWNTO 0);

	SIGNAL addra : STD_LOGIC_VECTOR (5 DOWNTO 0) := "000000";
	SIGNAL douta : STD_LOGIC_VECTOR (4095 DOWNTO 0);

	SIGNAL addrb : STD_LOGIC_VECTOR (5 DOWNTO 0) := "000001";
	SIGNAL doutb : STD_LOGIC_VECTOR (4095 DOWNTO 0);

	COMPONENT image_buffer
		PORT (
			clka : IN STD_LOGIC;
			ena : IN STD_LOGIC;
			wea : IN STD_LOGIC_VECTOR (0 TO 0);
			addra : IN STD_LOGIC_VECTOR (5 DOWNTO 0);
			dina : IN STD_LOGIC_VECTOR (4095 DOWNTO 0);
			douta : OUT STD_LOGIC_VECTOR (4095 DOWNTO 0);
			clkb : IN STD_LOGIC;
			enb : IN STD_LOGIC;
			web : IN STD_LOGIC_VECTOR (0 TO 0);
			addrb : IN STD_LOGIC_VECTOR (5 DOWNTO 0);
			dinb : IN STD_LOGIC_VECTOR (4095 DOWNTO 0);
			doutb : OUT STD_LOGIC_VECTOR (4095 DOWNTO 0)
		);
	END COMPONENT image_buffer;
BEGIN

	image_buffer_i : image_buffer
	PORT MAP(
		clka => clk,
		ena => '1',
		wea => "0",
		addra => addra,
		dina => (OTHERS => '0'),
		douta => douta,
		clkb => clk,
		enb => '1',
		web => "0",
		addrb => addrb,
		dinb => (OTHERS => '0'),
		doutb => doutb
	);
	IMG_BUFFER_CONTROLLER_process : PROCESS (clk, reset_p)
		VARIABLE start_flag : STD_LOGIC := '0';
		VARIABLE read_flag : STD_LOGIC := '0';
		VARIABLE word_count : INTEGER := 0;
		VARIABLE up_limit : INTEGER;
		VARIABLE low_limit : INTEGER;
	BEGIN

		IF reset_p = '1' THEN
			base_addr <= 0;
			temp_img <= (OTHERS => '0');
			image <= (OTHERS => '0');

		ELSIF RISING_EDGE(clk) THEN
			IF start = '1' THEN
				busy <= '1';
				start_flag := '1';
				up_limit := (ROW_WIDTH*IMAGE_DEPTH) - 1;
			END IF;

			IF start_flag = '1' THEN

				IF word_count < IMAGE_DEPTH THEN

						addra <= STD_LOGIC_VECTOR(to_unsigned(base_addr + word_count, addra'length));
						addrb <= STD_LOGIC_VECTOR(to_unsigned(base_addr + word_count + 1, addrb'length));

						low_limit := up_limit - (ROW_WIDTH * 2);

						temp_img(up_limit DOWNTO low_limit+1) <= douta & doutb;
                        
						word_count := word_count + 2;
						up_limit := low_limit;

				ELSE
					image <= temp_img;
					busy <= '0';
					start_flag := '0';
				END IF;
			END IF;
		END IF;
	END PROCESS IMG_BUFFER_CONTROLLER_process;
END IMG_BUFFER_CONTROLLER_arch;
