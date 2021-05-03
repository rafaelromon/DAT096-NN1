--*****************************************************************************
-- (c) Copyright 2009 - 2012 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
--
--*****************************************************************************
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor             : Xilinx
-- \   \   \/     Version            : 4.2
--  \   \         Application        : MIG
--  /   /         Filename           : example_top.vhd
-- /___/   /\     Date Last Modified : $Date: 2011/06/02 08:35:03 $
-- \   \  /  \    Date Created       : Wed Feb 01 2012
--  \___\/\___\
--
-- Device           : 7 Series
-- Design Name      : ddr3 SDRAM
-- Purpose          :
--   Top-level  module. This module serves as an example,
--   and allows the user to synthesize a self-contained design,
--   which they can be used to test their hardware.
--   In addition to the memory controller, the module instantiates:
--     1. Synthesizable testbench - used to model user's backend logic
--        and generate different traffic patterns
-- Reference        :
-- Revision History :
--*****************************************************************************
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE WORK.function_package.ALL;

entity DDR_interface_top is

  generic (
     
   --***************************************************************************
   -- The following parameters refer to width of various ports
   --***************************************************************************
   
   BANK_WIDTH            : integer := 3;
                                     -- # of memory Bank Address bits.
   COL_WIDTH             : integer := 10;
                                     -- # of memory Column Address bits.
									 -- [9:0] according to the datasheet
   -- CS_WIDTH              : integer := 1; -- Chip select is disabled
                                     -- # of unique CS outputs to memory.
   DQ_WIDTH              : integer := 64; --**
                                     -- # of DQ (data)
   DQS_WIDTH             : integer := 8; --**
   DQS_CNT_WIDTH         : integer := 3;
                                     -- = ceil(log2(DQS_WIDTH))
   DRAM_WIDTH            : integer := 8;
                                     -- # of DQ per DQS
   ECC_TEST              : string  := "OFF";
   RANKS                 : integer := 1;
                                     -- # of Ranks.
   ROW_WIDTH             : integer := 14;
                                     -- # of memory Row Address bits.
									 -- [13:0] according to the datasheet
   ADDR_WIDTH            : integer := 28;
                                     -- # = RANK_WIDTH + BANK_WIDTH
                                     --     + ROW_WIDTH + COL_WIDTH;
									 -- # = 1+3+14+10 = 28
                                     -- Chip Select is always tied to low for
                                     -- single rank devices
   
   --***************************************************************************
   -- The following parameters are mode register settings
   --***************************************************************************
   
   BURST_MODE            : string  := "8";
                                     -- DDR3 SDRAM:
                                     -- Burst Length (Mode Register 0).
                                     -- # = "8", "4", "OTF".
                                     -- ddr3 SDRAM:
                                     -- Burst Length (Mode Register).
                                     -- # = "8", "4".
   
   --***************************************************************************
   -- Simulation parameters
   --***************************************************************************
   
   SIMULATION            : string  := "FALSE";
                                     -- Should be TRUE during design simulations and
                                     -- FALSE during implementations
   
   --***************************************************************************
   -- IODELAY and PHY related parameters
   --***************************************************************************
   
   TCQ                   : integer := 100;
   DRAM_TYPE             : string  := "DDR3";
   
   --***************************************************************************
   -- System clock frequency parameters
   --***************************************************************************

   nCK_PER_CLK           : integer := 4;
                                     -- # of memory CKs per fabric CLK
   --***************************************************************************
   -- Debug parameters
   --***************************************************************************

   DEBUG_PORT            : string  := "OFF";
                                     -- # = "ON" Enable debug signals/controls.
                                     --   = "OFF" Disable debug signals/controls.

   --***************************************************************************
   -- Temparature monitor parameter
   --***************************************************************************

   TEMP_MON_CONTROL         : string  := "INTERNAL";
                                     -- # = "INTERNAL", "EXTERNAL"   
   RST_ACT_LOW           : integer := 0
                                     -- =1 for active low reset,
                                     -- =0 for active high.
   --***************************************************************************
   -- Added generics
   --***************************************************************************
   DW:INTEGER:=64 -- Sewts the number of bits, could be 8 or 16
					-- Not in our 64-bit implementation
   );
  port (
   -- Inouts
   ddr3_dq                        : inout std_logic_vector(DATA_WIDTH_func(DW)-1 DOWNTO 0);
   ddr3_dqs_p                     : inout std_logic_vector(DQS_SIZE_func(DW)-1 downto 0);
   ddr3_dqs_n                     : inout std_logic_vector(DQS_SIZE_func(DW)-1 downto 0);
   -- Outputs
   ddr3_addr                      : out   std_logic_vector(ROW_WIDTH-1 downto 0);
   ddr3_ba                        : out   std_logic_vector(BANK_WIDTH-1 downto 0);
   ddr3_ras_n                     : out   std_logic;
   ddr3_cas_n                     : out   std_logic;
   ddr3_we_n                      : out   std_logic;
   ddr3_ck_p                      : out   std_logic_vector(0 downto 0);
   ddr3_ck_n                      : out   std_logic_vector(0 downto 0);
   ddr3_cke                       : out   std_logic_vector(0 downto 0);
   ddr3_cs_n                      : out   std_logic_vector(0 downto 0);
   ddr3_dm                        : out   std_logic_vector(DM_SIZE_func(DW)-1 downto 0);
   ddr3_odt                       : out   std_logic_vector(0 downto 0);
   -- Inputs
   -- Single-ended system clock
   sys_clk_i                      : in    std_logic;
   clk_ref_i                      : in    std_logic;
   init_calib_complete            : out std_logic;
   -- System reset - Default polarity of sys_rst pin is Active Low.
   -- System reset polarity will change based on the option 
   -- selected in GUI.
      sys_rst                     : in    std_logic;
   --***************************************************************************
   -- Added ports
   --***************************************************************************
   app_addr_in:IN std_logic_vector(2 downto 0);
   app_wdf_data_in:IN std_logic_vector(7 downto 0); -- FOR TEST SWITCHES
   app_rd_data_out:OUT STD_LOGIC_VECTOR(7 DOWNTO 0); -- FOR TEST LEDs
   app_rdy:OUT STD_LOGIC;
   app_wdf_rdy:OUT STD_LOGIC;
   app_rd_data_valid:OUT STD_LOGIC;
   app_rd_data_end:OUT STD_LOGIC;
   start_write:IN STD_LOGIC;
   start_read:IN STD_LOGIC;
   -- AN:OUT STD_LOGIC_VECTOR(7 DOWNTO 0); -- FOR TEST 7-SEGMENT
   -- DP:OUT STD_LOGIC;                    -- FOR TEST 7-SEGMENT
   -- CG:OUT STD_LOGIC;                    -- FOR TEST 7-SEGMENT
   -- CF:OUT STD_LOGIC;                    -- FOR TEST 7-SEGMENT
   -- CE:OUT STD_LOGIC;                    -- FOR TEST 7-SEGMENT
   -- CD:OUT STD_LOGIC;                    -- FOR TEST 7-SEGMENT
   -- CC:OUT STD_LOGIC;                    -- FOR TEST 7-SEGMENT
   -- CB:OUT STD_LOGIC;                    -- FOR TEST 7-SEGMENT
   -- CA:OUT STD_LOGIC;                    -- FOR TEST 7-SEGMENT
   ui_clk:out std_logic;                -- FOR TEST
   locked:OUT STD_LOGIC;                -- FOR TEST
   reset_p:IN STD_LOGIC);               -- ACTIVE HIGH RESET
   
end entity DDR_interface_top;

architecture arch_DDR_interface_top of DDR_interface_top is

  -- clogb2 function - ceiling of log base 2
  function clogb2 (size : integer) return integer is
    variable base : integer := 1;
    variable inp : integer := 0;
  begin
    inp := size - 1;
    while (inp > 1) loop
      inp := inp/2 ;
      base := base + 1;
    end loop;
    return base;
  end function;
  
  function STR_TO_INT(BM : string) return integer is
  begin
   if(BM = "8") then
     return 8;
   elsif(BM = "4") then
     return 4;
   else
     return 0;
   end if;
  end function;
  constant RANK_WIDTH : integer := clogb2(RANKS);

  function XWIDTH return integer is
  begin
    if(CS_WIDTH = 1) then
      return 0;
    else
      return RANK_WIDTH;
    end if;
  end function;
  
  constant CMD_PIPE_PLUS1        : string  := "ON";
                                     -- add pipeline stage between MC and PHY
  constant tPRDI                 : integer := 1000000;
                                     -- memory tPRDI paramter in pS.
  constant PAYLOAD_WIDTH         : integer := DATA_WIDTH_func(DW);
  constant BURST_LENGTH          : integer := STR_TO_INT(BURST_MODE);
  constant APP_DATA_WIDTH        : integer := 2 * nCK_PER_CLK * PAYLOAD_WIDTH;
  constant APP_MASK_WIDTH        : integer := APP_DATA_WIDTH / 8;

  --***************************************************************************
  -- Added constants
  --***************************************************************************

  CONSTANT APP_WDF_MASK_CONST:STD_LOGIC_VECTOR(DATA_WIDTH_func(DW)-1 DOWNTO 0):=(OTHERS=>'0');      
--  CONSTANT DW:INTEGER:=16;
  
-- Start of User Design top component

  component mig_7series_0
--    generic (
--	#parameters_user_design_top_component#
--      RST_ACT_LOW           : integer
--      );
    port( 
      ddr3_dq       : inout std_logic_vector(DATA_WIDTH_func(DW)-1 downto 0);
      ddr3_dqs_p    : inout std_logic_vector(DQS_SIZE_func(DW)-1 downto 0);
      ddr3_dqs_n    : inout std_logic_vector(DQS_SIZE_func(DW)-1 downto 0);
      ddr3_addr     : out   std_logic_vector(ROW_WIDTH-1 downto 0);
      ddr3_ba       : out   std_logic_vector(BANK_WIDTH-1 downto 0);
      ddr3_ras_n    : out   std_logic;
      ddr3_cas_n    : out   std_logic;
      ddr3_we_n     : out   std_logic;
      ddr3_ck_p     : out   std_logic_vector(0 downto 0);
      ddr3_ck_n     : out   std_logic_vector(0 downto 0);
      ddr3_cke      : out   std_logic_vector(0 downto 0);      
      ddr3_cs_n     : out   std_logic_vector(0 downto 0);
      ddr3_dm       : out   std_logic_vector(DM_SIZE_func(DW)-1 downto 0);
      ddr3_odt      : out   std_logic_vector(0 downto 0);
      app_addr                  : in    std_logic_vector(ADDR_WIDTH-1 downto 0);
      app_cmd                   : in    std_logic_vector(2 downto 0);
      app_en                    : in    std_logic;
      app_wdf_data              : in    std_logic_vector(APP_DATA_WIDTH_func(DW)-1 downto 0);
      app_wdf_end               : in    std_logic;
      app_wdf_mask              : in    std_logic_vector(DATA_WIDTH_func(DW)-1 downto 0);
      app_wdf_wren              : in    std_logic;
      app_rd_data               : out   std_logic_vector(APP_DATA_WIDTH_func(DW)-1 downto 0);
      app_rd_data_end           : out   std_logic;
      app_rd_data_valid         : out   std_logic;
      app_rdy                   : out   std_logic;
      app_wdf_rdy               : out   std_logic;
      app_sr_req                : in    std_logic;
      app_ref_req               : in    std_logic;
      app_zq_req                : in    std_logic;
      app_sr_active             : out   std_logic;
      app_ref_ack               : out   std_logic;
      app_zq_ack                : out   std_logic;
      ui_clk                    : out   std_logic;
      ui_clk_sync_rst           : out   std_logic;
      init_calib_complete       : out   std_logic;       
      -- System Clock Ports
      sys_clk_i                 : in    std_logic;
      -- Reference Clock Ports
      clk_ref_i                 : in    std_logic;      
      sys_rst             : in std_logic
      --***************************************************************************
      -- Added ports
      --***************************************************************************
      );
  end component mig_7series_0;

COMPONENT clk_wiz_0
    PORT
      (                                 -- Clock in ports
        -- Clock out ports
        clk_out1:OUT STD_LOGIC;
        clk_out2:OUT STD_LOGIC;
        -- Status and control signals
        reset_p:IN STD_LOGIC;
        locked:OUT STD_LOGIC;
        clk_in1:IN  STD_LOGIC
        );
  END COMPONENT;

COMPONENT read_write_ddr IS  
  GENERIC(APP_DATA_WIDTH:INTEGER:=APP_DATA_WIDTH_func(DW);
          DATA_WIDTH:INTEGER:=DATA_WIDTH_func(DW);
          ADDR_WIDTH:INTEGER:=ADDR_WIDTH); 
  port (ui_clk:IN STD_LOGIC;
        reset_n:IN STD_LOGIC;
        start_write:IN STD_LOGIC;
        start_read:IN STD_LOGIC;
        loop_flag:OUT STD_LOGIC;
        state:OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        app_cmd:OUT STD_LOGIC_VECTOR(2 DOWNTO 0);                                  -- command 001 = READ, 000 = WRITE
        app_addr_in:IN STD_LOGIC_VECTOR(2 DOWNTO 0);                               -- FOR TEST
        app_addr_out:OUT STD_LOGIC_VECTOR(ADDR_WIDTH-1 DOWNTO 0);                  -- 28 bit output address
        app_en:OUT STD_LOGIC;                                                      -- active strobe for app_addr and app_cmd
        app_rdy:IN STD_LOGIC;                                                      -- UI is ready o accept commands. Ifv the signal is desserted
                                                                                   -- when app_en is enabled app_cmd and app_addr command must
                                                                                   -- retried until app_rdy is asserted 
        app_rd_data_in:IN STD_LOGIC_VECTOR(APP_DATA_WIDTH-1 DOWNTO 0);             -- output from read command
        app_rd_data_out:OUT STD_LOGIC_VECTOR(7 DOWNTO 0);                          -- read data
        app_rd_data_end:IN STD_LOGIC;                                              -- the current clock cycle the last output data
        app_rd_data_valid:IN STD_LOGIC;                                            -- indicates that app_re_data is valid
        app_wdf_data_in:IN STD_LOGIC_VECTOR(7 DOWNTO 0);                           -- data to DDR
        app_wdf_data_out:OUT STD_LOGIC_VECTOR(APP_DATA_WIDTH_func(DW)-1 DOWNTO 0); -- data to write
        app_wdf_end:OUT STD_LOGIC;                                                 -- the clock cycle containd the last data to write
        app_wdf_mask:OUT STD_LOGIC_VECTOR(DATA_WIDTH DOWNTO 0);                    -- mask for app_wdf_data
                                                                                   -- what bits are to be updated
        app_wdf_rdy:IN STD_LOGIC;                                                  -- the write data FIFO is ready to recive data
        app_wdf_wren:OUT STD_LOGIC                                                 -- strobe for app_wdf_data
);
END COMPONENT read_write_ddr;

COMPONENT pulse_to_rigger is 
  PORT(clk:IN STD_LOGIC;
       reset_n:IN STD_LOGIC;
       start:IN STD_LOGIC;
       trig_pulse:OUT STD_LOGIC);
END COMPONENT pulse_to_rigger;

-- COMPONENT seg_7_driver IS
   -- GENERIC(timestep:NATURAL:=10000);
   -- PORT(reset_n:IN STD_LOGIC;
        -- clk:IN STD_LOGIC;
        -- hex_code_0:IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        -- hex_code_1:IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        -- hex_code_2:IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        -- hex_code_3:IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        -- hex_code_4:IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        -- hex_code_5:IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        -- hex_code_6:IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        -- hex_code_7:IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        -- int_code_0:IN NATURAL RANGE 0 TO 15;
        -- int_code_1:IN NATURAL RANGE 0 TO 15;
    	-- int_code_2:IN NATURAL RANGE 0 TO 15;
        -- int_code_3:IN NATURAL RANGE 0 TO 15;
        -- int_code_4:IN NATURAL RANGE 0 TO 15;
        -- int_code_5:IN NATURAL RANGE 0 TO 15;
    	-- int_code_6:IN NATURAL RANGE 0 TO 15;
    	-- int_code_7:IN NATURAL RANGE 0 TO 15;
        -- hex_int:IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        -- dot:IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        -- active_seg:IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        -- AN:OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        -- DP:OUT STD_LOGIC;
        -- CG:OUT STD_LOGIC;
        -- CF:OUT STD_LOGIC;
        -- CE:OUT STD_LOGIC;
        -- CD:OUT STD_LOGIC;
        -- CC:OUT STD_LOGIC;
        -- CB:OUT STD_LOGIC;
        -- CA:OUT STD_LOGIC);
-- END COMPONENT seg_7_driver;

COMPONENT ila_0 IS
PORT (
clk : IN STD_LOGIC;
    probe0:IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    probe1:IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    probe2:IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    probe3:IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    probe4:IN STD_LOGIC_VECTOR(ADDR_WIDTH-1 DOWNTO 0);
    probe5:IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    probe6:IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    probe7:IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    probe8:IN STD_LOGIC_VECTOR(APP_DATA_WIDTH-1 DOWNTO 0);
    probe9:IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    probe10:IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    probe11:IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    probe12:IN STD_LOGIC_VECTOR(APP_DATA_WIDTH-1 DOWNTO 0);
    probe13:IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    probe14:IN STD_LOGIC_VECTOR(0 DOWNTO 0)
 );
END COMPONENT ila_0;

-- End of User Design top component
    
  -- Signal declarations
      
   signal app_cmd                     : std_logic_vector(2 downto 0);
   signal app_en                      : std_logic;
   SIGNAL init_calib_complete_i:std_logic;
  
  --***************************************************************************
  -- Added signals
  --***************************************************************************
  signal app_addr_out_signal:std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal app_cmd_signal:std_logic_vector(2 downto 0);
  signal app_en_signal:std_logic;
  signal app_rdy_signal:std_logic;
  signal app_rd_data_in_signal:std_logic_vector(APP_DATA_WIDTH_func(DW)-1 downto 0);
  signal app_rd_data_end_signal:std_logic;
  signal app_rd_data_valid_signal:std_logic;
  signal app_wdf_data_out_signal:std_logic_vector(APP_DATA_WIDTH-1 downto 0);
  signal app_rd_data_signal:std_logic_vector(APP_DATA_WIDTH-1 downto 0);
  signal app_wdf_end_signal:std_logic;
  signal app_wdf_mask_signal:std_logic_vector(APP_MASK_WIDTH-1 downto 0);
  signal app_wdf_rdy_signal:std_logic;
  signal app_wdf_wren_signal:std_logic;
  signal ui_clk_signal:std_logic;
  signal ui_clk_sync_rst_signal:std_logic;
  SIGNAL start_read_pulse_signal:STD_LOGIC;
  SIGNAL start_write_pulse_signal:STD_LOGIC;
  SIGNAL state_signal:STD_LOGIC_VECTOR(3 DOWNTO 0);
  SIGNAL clk_100mhz:STD_LOGIC;
  SIGNAL clk_200mhz:STD_LOGIC;
  SIGNAL ui_clk_vector_signal:STD_LOGIC_VECTOR(0 DOWNTO 0);
  SIGNAL start_write_pulse_vector_signal:STD_LOGIC_VECTOR(0 DOWNTO 0);
  SIGNAL app_en_vector_signal:STD_LOGIC_VECTOR(0 DOWNTO 0);
  SIGNAL app_rdy_vector_signal:STD_LOGIC_VECTOR(0 DOWNTO 0);
  SIGNAL app_wdf_rdy_vector_signal:STD_LOGIC_VECTOR(0 DOWNTO 0);
  SIGNAL app_wdf_wren_vector_signal:STD_LOGIC_VECTOR(0 DOWNTO 0);
  SIGNAL app_wdf_end_vector_signal:STD_LOGIC_VECTOR(0 DOWNTO 0);
  SIGNAL start_read_pulse_vector_signal:STD_LOGIC_VECTOR(0 DOWNTO 0);
  SIGNAL app_rd_data_valid_vector_signal:STD_LOGIC_VECTOR(0 DOWNTO 0);
  SIGNAL app_rd_data_end_vector_signal:STD_LOGIC_VECTOR(0 DOWNTO 0);
  SIGNAL loop_flag_signal:STD_LOGIC;
 --***************************************************************************
  
begin
--***************************************************************************
 init_calib_complete <= init_calib_complete_i;
  app_wdf_mask_signal <= APP_WDF_MASK_CONST;
  app_rdy <= app_rdy_signal;
  app_wdf_rdy <= app_wdf_rdy_signal;
  app_rd_data_valid <= app_rd_data_valid_signal;
  app_rd_data_end <= app_rd_data_end_signal;
  ui_clk <= ui_clk_signal; 
  ui_clk_vector_signal(0) <= ui_clk_signal;
  app_rdy_vector_signal(0) <= app_rdy_signal;
  app_en_vector_signal(0) <= app_en_signal;
  app_wdf_wren_vector_signal(0) <= app_wdf_wren_signal;
  app_wdf_end_vector_signal(0) <= app_wdf_end_signal; 
  app_wdf_rdy_vector_signal(0) <= app_wdf_rdy_signal;
  app_rd_data_valid_vector_signal(0) <= app_rd_data_valid_signal;
  app_rd_data_end_vector_signal(0) <= app_rd_data_end_signal;
  start_write_pulse_vector_signal(0) <= start_write_pulse_signal;
  start_read_pulse_vector_signal(0) <= start_read_pulse_signal;
  
-- Start of User Design top instance
--***************************************************************************
-- The User design is instantiated below. The memory interface ports are
-- connected to the top-level and the application interface ports are
-- connected to the traffic generator module. This provides a reference
-- for connecting the memory controller to system.
--***************************************************************************

   u_mig_7series_0 : mig_7series_0
--    generic map (
--      #parameters_mapping_user_design_top_instance#
--      RST_ACT_LOW                      => RST_ACT_LOW
--      )
      port map (   
-- Memory interface ports
       ddr3_addr                      => ddr3_addr,
       ddr3_ba                        => ddr3_ba,
       ddr3_cas_n                     => ddr3_cas_n,
       ddr3_ck_n                      => ddr3_ck_n,
       ddr3_ck_p                      => ddr3_ck_p,
       ddr3_cke                       => ddr3_cke,
       ddr3_ras_n                     => ddr3_ras_n,
       ddr3_we_n                      => ddr3_we_n,
       ddr3_dq                        => ddr3_dq,
       ddr3_dqs_n                     => ddr3_dqs_n,
       ddr3_dqs_p                     => ddr3_dqs_p,
       init_calib_complete            => init_calib_complete_i,
       ddr3_cs_n                      => ddr3_cs_n,
       ddr3_dm                        => ddr3_dm,
       ddr3_odt                       => ddr3_odt,
-- Application interface ports
       app_addr                       => app_addr_out_signal,
       app_cmd                        => app_cmd_signal,
       app_en                         => app_en_signal,
       app_wdf_data                   => app_wdf_data_out_signal,
       app_wdf_end                    => app_wdf_end_signal,
       app_wdf_wren                   => app_wdf_wren_signal,
       app_rd_data                    => app_rd_data_in_signal,
       app_rd_data_end                => app_rd_data_end_signal,
       app_rd_data_valid              => app_rd_data_valid_signal,
       app_rdy                        => app_rdy_signal,
       app_wdf_rdy                    => app_wdf_rdy_signal,
       app_sr_req                     => '0',
       app_ref_req                    => '0',
       app_zq_req                     => '0',
       ui_clk                         => ui_clk_signal, --clk,
       app_wdf_mask                   => app_wdf_mask_CONST,          
-- System Clock Ports
       sys_clk_i                      => clk_200mhz,
       clk_ref_i                      => clk_200mhz,   
        sys_rst                       => sys_rst);
        
-- End of User Design top instance

clk_pll_i0 : clk_wiz_0
    PORT MAP (
      -- Clock out ports  
      clk_out1 => clk_100mhz,
      clk_out2 => clk_200mhz,
      -- Status and control signals                
      resetn => reset_n,
      locked   => locked,
      clk_in1  => sys_clk_i);

read_write_ddr_comp:
COMPONENT read_write_ddr
  GENERIC MAP(APP_DATA_WIDTH => APP_DATA_WIDTH_func(DW),
          DATA_WIDTH => DATA_WIDTH_func(DW),
          ADDR_WIDTH => ADDR_WIDTH) 
  port map(ui_clk => ui_clk_signal,
        reset_n => reset_n,
        start_write => start_write_pulse_signal,
        start_read => start_read_pulse_signal,
        loop_flag => loop_flag_signal,
        state => state_signal,
        app_cmd => app_cmd_signal,
        app_addr_in => app_addr_in,
        app_addr_out => app_addr_out_signal,
        app_en => app_en_signal,
        app_rdy => app_rdy_signal,
        app_rd_data_in => app_rd_data_in_signal,
        app_rd_data_out => app_rd_data_out,
        app_rd_data_end => app_rd_data_end_signal,
        app_rd_data_valid => app_rd_data_valid_signal,
        app_wdf_data_in => app_wdf_data_in,
        app_wdf_data_out => app_wdf_data_out_signal,
        app_wdf_end => app_wdf_end_signal,
        app_wdf_mask => app_wdf_mask_signal,
        app_wdf_rdy => app_wdf_rdy_signal,
        app_wdf_wren => app_wdf_wren_signal);

pulse_to_trigger_read_comp:
COMPONENT pulse_to_rigger
  PORT MAP(clk => ui_clk_signal,
       reset_n => reset_n,
       start => start_read,
       trig_pulse => start_read_pulse_signal);

pulse_to_trigger_write_comp:
COMPONENT pulse_to_rigger
  PORT MAP(clk => ui_clk_signal,
       reset_n => reset_n,
       start => start_write,
       trig_pulse => start_write_pulse_signal);
 
 -- seg_7_driver_comp:
 -- COMPONENT seg_7_driver
   -- GENERIC MAP(timestep => 10000)
   -- PORT MAP(reset_n => reset_n,
            -- clk => ui_clk_signal,
            -- hex_code_0 => state_signal,
            -- hex_code_1 => (OTHERS => '0'),
            -- hex_code_2 => (OTHERS => '0'),
            -- hex_code_3 => (OTHERS => '0'),
            -- hex_code_4 => (OTHERS => '0'),
            -- hex_code_5 => (OTHERS => '0'),
            -- hex_code_6 => (OTHERS => '0'),
            -- hex_code_7 => (OTHERS => '0'),
            -- int_code_0 => 0,
            -- int_code_1 => 0,
        	-- int_code_2 => 0,
        	-- int_code_3 => 0,
            -- int_code_4 => 0,
            -- int_code_5 => 0,
    	    -- int_code_6 => 0,
            -- int_code_7 => 0,
            -- hex_int => (OTHERS => '1'),
            -- dot => (OTHERS => '0'),
            -- active_seg => "00000001",
            -- AN => AN,
            -- DP => DP,
            -- CG => CG,
            -- CF => CF,
            -- CE => CE,
            -- CD => CD,
            -- CC => CC,
            -- CB => CB,
            -- CA => CA);
 
 ila_comp: COMPONENT ila_0
PORT MAP(
   clk => sys_clk_i,
   probe0 => state_signal,
   probe1 => ui_clk_vector_signal,
   probe2 => start_write_pulse_vector_signal,
   probe3 => app_cmd_signal,
   probe4 => app_addr_out_signal,
   probe5 => app_en_vector_signal,
   probe6 => app_rdy_vector_signal,
   probe7 => app_wdf_rdy_vector_signal,
   probe8 => app_wdf_data_out_signal,
   probe9 => app_wdf_wren_vector_signal,
   probe10 => app_wdf_end_vector_signal,
   probe11 => start_read_pulse_vector_signal,
   probe12 => app_rd_data_in_signal,
   probe13 => app_rd_data_valid_vector_signal,
   probe14 => app_rd_data_end_vector_signal
);
 
end architecture arch_DDR_interface_top;

