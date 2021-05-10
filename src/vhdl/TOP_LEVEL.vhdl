-----------------------------------------------------
-- Title: TOP_LEVEL.vhdl
-- Author: Rafael Romon/NN-1
-- DAT096 - spring 2021
-----------------------------------------------------
-- Description:
-- This entity dictates the top level
-- architecture of the entire system
-- TODO:
-- * remove debouncers
-- * integrate bram controller
-- * update uart implementation
-- * implement uart receive
-----------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.function_package.ALL;  -- Helper function for setting the sizes of the memory

LIBRARY UNISIM;
USE UNISIM.Vcomponents.ALL;

ENTITY TOP_LEVEL IS
	GENERIC (
		clk_freq : INTEGER := 100; --system clock frequency in MHz
		testbench : STD_LOGIC := '0'; --disables debouncer and waits for testbench
		
		ddr_dw : INTEGER := 64;    --DDR Data width
		ddr_aw : INTEGER := 14    --DDR Address width
	);
	PORT (
		SYSCLK_P : IN STD_LOGIC;
		SYSCLK_N : IN STD_LOGIC;
		CPU_RESET : IN STD_LOGIC;
		GPIO_SW_N : IN STD_LOGIC;
		USB_UART_TX : OUT STD_LOGIC;
		GPIO_LED_0 : OUT STD_LOGIC;
		GPIO_LED_1 : OUT STD_LOGIC;
		GPIO_LED_2 : OUT STD_LOGIC;
		GPIO_LED_3 : OUT STD_LOGIC;
		
		-- DDR ports to be connected
	   DDR_RST_P    : IN   STD_LOGIC;
	   ddr3_dq     : inout std_logic_vector(DATA_WIDTH_func(ddr_dw)-1 DOWNTO 0);
       ddr3_dqs_p  : inout std_logic_vector(DQS_SIZE_func(ddr_dw)-1 downto 0);
       ddr3_dqs_n  : inout std_logic_vector(DQS_SIZE_func(ddr_dw)-1 downto 0);
       -- Outputs
       ddr3_addr   : out   std_logic_vector(ddr_aw-1 downto 0);
       ddr3_ba     : out   std_logic_vector(2 downto 0);
       ddr3_ras_n  : out   std_logic;
       ddr3_cas_n  : out   std_logic;
       ddr3_we_n   : out   std_logic;
       ddr3_ck_p   : out   std_logic_vector(0 downto 0);
       ddr3_ck_n   : out   std_logic_vector(0 downto 0);
       ddr3_cke    : out   std_logic_vector(0 downto 0);
       --Uddr3_cs_n   : out   std_logic_vector(0 downto 0);
       ddr3_dm     : out   std_logic_vector(DM_SIZE_func(ddr_dw)-1 downto 0);
       ddr3_odt    : out   std_logic_vector(0 downto 0)
	);
END TOP_LEVEL;

ARCHITECTURE TOP_LEVEL_arch OF TOP_LEVEL IS

	TYPE states IS (Idle, LoadImage, ProcessImage, SendResult);
	SIGNAL state_machine : states := Idle;
	SIGNAL clk : STD_LOGIC;
	SIGNAL reset_signal : STD_LOGIC := '0';

	SIGNAL reset_p : STD_LOGIC := '0';
	SIGNAL start_signal : STD_LOGIC := '0';

	COMPONENT button_debounce IS
		GENERIC (
			clk_freq : INTEGER := 10; --system clock frequency in MHz
			stable_time : INTEGER := 10); --time button must remain stable in ms
		PORT (
			clk : IN STD_LOGIC;
			reset_p : IN STD_LOGIC;
			button : IN STD_LOGIC;
			result : OUT STD_LOGIC
		);
	END COMPONENT button_debounce;

	SIGNAL cnn_start : STD_LOGIC := '0';
	SIGNAL loaded_image : STD_LOGIC_VECTOR(16383 DOWNTO 0);
	SIGNAL cnn_finished : STD_LOGIC;
	SIGNAL cnn_result : STD_LOGIC_VECTOR(5 DOWNTO 0);

	COMPONENT CNN IS
		PORT (
			clk : IN STD_LOGIC;
			reset_p : IN STD_LOGIC;
			start : IN STD_LOGIC;
			image : IN STD_LOGIC_VECTOR(16383 DOWNTO 0);
			finished : OUT STD_LOGIC;
			result : OUT STD_LOGIC_VECTOR(5 DOWNTO 0)
		);
	END COMPONENT CNN;

	SIGNAL TX_DV : STD_LOGIC := '0';
	SIGNAL TX_Byte : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
	SIGNAL TX_Done : STD_LOGIC;

	COMPONENT UART_TX IS
		PORT (
			clk : IN STD_LOGIC;
			TX_DV : IN STD_LOGIC;
			TX_Byte : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
			TX_Active : OUT STD_LOGIC;
			TX_Serial : OUT STD_LOGIC;
			TX_Done : OUT STD_LOGIC
		);
	END COMPONENT UART_TX;
	
	SIGNAL DDR_UI_Clk          : STD_LOGIC;
	SIGNAL init_calib_complete : STD_LOGIC;
	SIGNAL app_addr_in         : STD_LOGIC_VECTOR(2 DOWNTO 0);
	SIGNAL app_wdf_data_in     : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL app_rd_data_out     : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL app_rdy             : STD_LOGIC;
	SIGNAL app_wdf_rdy         : STD_LOGIC;
	SIGNAL app_rd_data_valid   : STD_LOGIC;
	SIGNAL app_rd_data_end     : STD_LOGIC;
	SIGNAL start_write         : STD_LOGIC;
	SIGNAL start_read          : STD_LOGIC;
	SIGNAL locked              : STD_LOGIC;
	
	
	-- Signals for testing the ddr
	SIGNAL DDR_downsample_counter : INTEGER:=0;
    SIGNAL DDR_address_counter    : STD_LOGIC_VECTOR(2 DOWNTO 0);
	
    COMPONENT TOP_LEVEL_DDR IS
        PORT (
           reset_p  : IN STD_LOGIC;    -- ACTIVE HIGH RESET
           sys_rst  : IN std_logic;    -- ACTIVE HIGH DDR RESET
           -- Inputs
           sys_clk_i                      : in    std_logic;    -- Single-ended system clock
           clk_ref_i                      : in    std_logic;
           ui_clk                         : out   std_logic;       -- FOR TEST
           -- Inouts
           ddr3_dq                        : inout std_logic_vector(DATA_WIDTH_func(ddr_dw)-1 DOWNTO 0);
           ddr3_dqs_p                     : inout std_logic_vector(DQS_SIZE_func(ddr_dw)-1 downto 0);
           ddr3_dqs_n                     : inout std_logic_vector(DQS_SIZE_func(ddr_dw)-1 downto 0);
           -- Outputs
           ddr3_addr                      : out   std_logic_vector(ddr_aw-1 downto 0);
           ddr3_ba                        : out   std_logic_vector(2 downto 0);
           ddr3_ras_n                     : out   std_logic;
           ddr3_cas_n                     : out   std_logic;
           ddr3_we_n                      : out   std_logic;
           ddr3_ck_p                      : out   std_logic_vector(0 downto 0);
           ddr3_ck_n                      : out   std_logic_vector(0 downto 0);
           ddr3_cke                       : out   std_logic_vector(0 downto 0);
           --Uddr3_cs_n                      : out   std_logic_vector(0 downto 0);
           ddr3_dm                        : out   std_logic_vector(DM_SIZE_func(ddr_dw)-1 downto 0);
           ddr3_odt                       : out   std_logic_vector(0 downto 0);
           init_calib_complete            : out std_logic;
           --***************************************************************************
           -- Added ports
           --***************************************************************************
           app_addr_in                    : IN std_logic_vector(2 downto 0);
           app_wdf_data_in                : IN std_logic_vector(7 downto 0); -- FOR TEST SWITCHES
           app_rd_data_out                : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); -- FOR TEST LEDs
           app_rdy                        : OUT STD_LOGIC;
           app_wdf_rdy                    : OUT STD_LOGIC;
           app_rd_data_valid              : OUT STD_LOGIC;
           app_rd_data_end                : OUT STD_LOGIC;
           start_write_pulse              : IN STD_LOGIC;
           start_read_pulse               : IN STD_LOGIC;
           locked                         : OUT STD_LOGIC                  -- FOR TEST
       );               
   END COMPONENT;
	

BEGIN

	-- LVDS input to internal single
	CLK_IBUFDS : IBUFDS
	GENERIC MAP(
		IOSTANDARD => "DEFAULT"
	)
	PORT MAP
	(
		I => SYSCLK_P,
		IB => SYSCLK_N,
		O => clk
	);

	CNN_comp : CNN -- Instantiate CNN transmitter
	PORT MAP
	(
		clk => clk,
		reset_p => reset_signal,
		start => cnn_start,
		image => loaded_image,
		finished => cnn_finished,
		result => cnn_result
	);

	UART_TX_comp : UART_TX -- Instantiate UART transmitter
	PORT MAP
	(
		clk => clk,
		TX_DV => TX_DV,
		TX_Byte => TX_Byte,
		TX_Active => OPEN,
		TX_Serial => USB_UART_TX,
		TX_Done => TX_Done
	);

	reset_debounce_comp : button_debounce -- debouncer for CPU_RESET
	PORT MAP
	(
		clk => clk,
		reset_p => '0',
		button => CPU_RESET,
		result => reset_p
	);
	start_debounce_comp : button_debounce -- debouncer for GPIO_SW_N
	PORT MAP
	(
		clk => clk,
		reset_p => reset_p,
		button => GPIO_SW_N,
		result => start_signal
	);
	
	ddr_interface_comp : top_level_ddr
	PORT MAP
	(
	       reset_p     =>  DDR_RST_P,
           sys_rst     => CPU_RESET,
           -- Inputs
           sys_clk_i   => SYSCLK_P,
           clk_ref_i   => SYSCLK_P,
           ui_clk      => DDR_UI_Clk,
           -- Inouts
           ddr3_dq     => ddr3_dq,
           ddr3_dqs_p  => ddr3_dqs_p,
           ddr3_dqs_n  => ddr3_dqs_n,
           -- Outputs
           ddr3_addr   => ddr3_addr,
           ddr3_ba     => ddr3_ba,
           ddr3_ras_n  => ddr3_ras_n,
           ddr3_cas_n  => ddr3_cas_n,
           ddr3_we_n   => ddr3_we_n,
           ddr3_ck_p   => ddr3_ck_p,
           ddr3_ck_n   => ddr3_ck_n,
           ddr3_cke    => ddr3_cke,
           --Uddr3_cs_n   => Uddr3_cs_n,
           ddr3_dm     => ddr3_dm,
           ddr3_odt    => ddr3_odt,
           init_calib_complete => init_calib_complete,
           --************************************************************************
           -- Added ports
           --***************************************************************************
           app_addr_in         => app_addr_in,        
           app_wdf_data_in     => app_wdf_data_in,    
           app_rd_data_out     => app_rd_data_out,    
           app_rdy             => app_rdy,            
           app_wdf_rdy         => app_wdf_rdy,        
           app_rd_data_valid   => app_rd_data_valid,  
           app_rd_data_end     => app_rd_data_end,    
           start_write_pulse   => start_write,
           start_read_pulse    => start_read,       
           locked              => locked        
	);

	LED_indicator_process : PROCESS (clk)
		VARIABLE count : INTEGER RANGE 0 TO clk_freq * 100000; -- 100ms
		VARIABLE blinking_led : STD_LOGIC := '1';
	BEGIN
		IF reset_p = '1' THEN
			GPIO_LED_0 <= '1';
			GPIO_LED_1 <= '1';
			GPIO_LED_2 <= '1';
			GPIO_LED_3 <= '1';

		ELSIF RISING_EDGE(clk) THEN

			IF testbench = '0' THEN
				IF (count < clk_freq * 100000) THEN
					count := count + 1;
				ELSE
					blinking_led := NOT(blinking_led);
					count := 0;
				END IF;
			ELSE
				blinking_led := '1';
			END IF;

			CASE state_machine IS
				WHEN Idle =>
					GPIO_LED_0 <= '1';
					GPIO_LED_1 <= '0';
					GPIO_LED_2 <= '0';
					GPIO_LED_3 <= '0';

				WHEN LoadImage =>
					GPIO_LED_0 <= '0';
					GPIO_LED_1 <= blinking_led;
					GPIO_LED_2 <= '0';
					GPIO_LED_3 <= '0';

				WHEN ProcessImage =>

					GPIO_LED_0 <= '0';
					GPIO_LED_1 <= '0';
					GPIO_LED_2 <= blinking_led;
					GPIO_LED_3 <= '0';

				WHEN SendResult =>

					GPIO_LED_0 <= '0';
					GPIO_LED_1 <= '0';
					GPIO_LED_2 <= '0';
					GPIO_LED_3 <= blinking_led;

			END CASE;
		END IF;
	END PROCESS LED_indicator_process;
	
	
	-- Testing out the DDR Process
    DDR_address_loop: PROCESS (clk)
    BEGIN
        IF reset_p = '1' THEN
            DDR_downsample_counter <= 0;
            DDR_address_counter    <= "000";
        ELSIF RISING_EDGE(clk) THEN
            IF DDR_downsample_counter = 2**14 THEN
                app_addr_in <= STD_LOGIC_VECTOR(UNSIGNED(DDR_address_counter)+1);
                app_wdf_data_in <= x"FF";
                start_write <= '1';
            ELSIF DDR_downsample_counter = 2**14+1 THEN
                start_write <= '0';
                DDR_downsample_counter <= DDR_downsample_counter+1;
            ELSIF DDR_downsample_counter = 2**15-2 THEN
                start_read <= '1';
                DDR_downsample_counter <= DDR_downsample_counter+1;
            ELSIF DDR_downsample_counter = 2**15-1 THEN
                start_read <= '0';
                DDR_downsample_counter <= 0;
            ELSE
                DDR_downsample_counter <= DDR_downsample_counter+1;
            END IF;
        END IF;
    END PROCESS DDR_address_loop;
	

	-- Purpose: Control state machine
	TOP_LEVEL_process : PROCESS (clk, CPU_RESET)
		VARIABLE count : INTEGER RANGE 0 TO clk_freq * 5000000; -- 5s
		VARIABLE start_flag : STD_LOGIC;
	BEGIN
		IF reset_p = '1' OR (testbench = '1' AND CPU_RESET = '1') THEN
			reset_signal <= '1';
			state_machine <= Idle;

		ELSIF RISING_EDGE(clk) THEN
			CASE state_machine IS
				WHEN Idle =>

					IF start_signal = '1' OR (testbench = '1' AND GPIO_SW_N = '1') THEN
						start_flag := '1';
						reset_signal <= '0';

					ELSIF start_signal = '0' AND start_flag = '1' THEN
						start_flag := '0';
						state_machine <= LoadImage;
					ELSE
						reset_signal <= '1';
					END IF;

				WHEN LoadImage =>

					IF (count < 100 * 2000000) AND testbench = '0' THEN -- temporal to simulate time
						count := count + 1;
					ELSE
						-- TODO this does nothing at the moment
						loaded_image <= (OTHERS => '0');
						state_machine <= ProcessImage;
						count := 0;

					END IF;

				WHEN ProcessImage =>
					IF (count < 100 * 2000000) AND testbench = '0' THEN -- temporal to simulate time
						count := count + 1;
					ELSE

						IF cnn_finished = '1' THEN
							cnn_start <= '0';
							state_machine <= SendResult;
							count := 0;
						ELSE
							cnn_start <= '1';
						END IF;

					END IF;

				WHEN SendResult =>
					IF (count < 100 * 2000000) AND testbench = '0' THEN -- temporal to simulate time
						count := count + 1;
					ELSE

						IF TX_Done = '1' THEN
							TX_DV <= '0';
							state_machine <= Idle;
							count := 0;
						ELSE
							TX_DV <= '1';
							TX_Byte <= cnn_result & "00";
						END IF;

					END IF;

			END CASE;
		END IF;
	END PROCESS TOP_LEVEL_process;
END TOP_LEVEL_arch;
