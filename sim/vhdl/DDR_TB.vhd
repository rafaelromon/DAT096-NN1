----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/10/2021 09:36:00 AM
-- Design Name: 
-- Module Name: DDR_TB - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity DDR_TB is
--  Port ( );
end DDR_TB;

architecture Behavioral of DDR_TB is

constant PERIOD : time := 10 ns;    -- Setting the clock period to be 100 MHz

component mig_7series_DDR port (

      ddr3_dq       : inout std_logic_vector(31 downto 0);
      ddr3_dqs_p    : inout std_logic_vector(3 downto 0);
      ddr3_dqs_n    : inout std_logic_vector(3 downto 0);


      ddr3_addr     : out   std_logic_vector(15 downto 0);
      ddr3_ba       : out   std_logic_vector(2 downto 0);
      ddr3_ras_n    : out   std_logic;  --Row address strobe 
      ddr3_cas_n    : out   std_logic;  --Column address strobe 
      ddr3_we_n     : out   std_logic;  
      ddr3_reset_n  : out   std_logic;
      ddr3_ck_p     : out   std_logic_vector(0 downto 0);   -- Memory clock signal high
      ddr3_ck_n     : out   std_logic_vector(0 downto 0);   -- Memory clock signal low
      ddr3_cke      : out   std_logic_vector(1 downto 0);
      ddr3_dm       : out   std_logic_vector(3 downto 0);
      ddr3_odt      : out   std_logic_vector(1 downto 0);   -- On die termination
      
      app_addr                  : in    std_logic_vector(29 downto 0);  -- Indicates the address for the current request
      app_cmd                   : in    std_logic_vector(2 downto 0);   -- Command selection for the current request
                                                                        -- 000      Memory read
                                                                        -- 001      Memory write
                                                                        -- Others   RESERVED
      app_en                    : in    std_logic;  -- active-high strobe for app_addr[], app_cmd[2:0], app_sz and app_hi_pri inp
      app_wdf_data              : in    std_logic_vector(255 downto 0); --Provides the data for write commands
      app_wdf_end               : in    std_logic;  -- Indicates that the current clock cycle is the last of input data on app_wdf_data[]
      app_wdf_mask              : in    std_logic_vector(31 downto 0);  -- Provides mask for app_wdf_data[]
      app_wdf_wren              : in    std_logic;  --This is the active-high strobe for app_wdf_data[]
      app_rd_data               : out   std_logic_vector(255 downto 0); -- Provides the output data from read commands
      app_rd_data_end           : out   std_logic;  -- Indicates that the current clock cycle is the last of output data on app_rd_data[]
      app_rd_data_valid         : out   std_logic;  -- Indicates that app_rd_data[] is valid
      app_rdy                   : out   std_logic;  
      app_wdf_rdy               : out   std_logic;  --Indicates that the write data FIFO is ready to receive data
                                                    --Write data is accepted when app_wdf_rdy = '1' and app_wdf_wren ='1'
      app_sr_req                : in    std_logic;  -- Reserved, should be tied to '0'
      app_ref_req               : in    std_logic;  --This active-high input requests that a refresh command be issued to the DRAM
      app_zq_req                : in    std_logic;  --Sends an (active-high) input request that a ZQ calibration command be issued
      app_sr_active             : out   std_logic;  --Reserved output
      app_ref_ack               : out   std_logic;  --This active-high output indicates that the memory controller has sen the refresh command
      app_zq_ack                : out   std_logic;  --Active-high indication that the calibration request has been sent
      ui_clk                    : out   std_logic;  --System clock, must be 1/4 of the DRAM clock
      ui_clk_sync_rst           : out   std_logic;  --Full frequency memory clock
      init_calib_complete       : out   std_logic;  --Asserted when the PHY layer calibration is finished
      
      -- debug signals
      ddr3_ila_wrpath           : out   std_logic_vector(390 downto 0);
      ddr3_ila_rdpath           : out   std_logic_vector(1023 downto 0);
      ddr3_ila_basic            : out   std_logic_vector(119 downto 0);
      ddr3_vio_sync_out         : in    std_logic_vector(13 downto 0);


      dbg_byte_sel              : in    std_logic_vector(2 downto 0);
      dbg_sel_pi_incdec         : in    std_logic;
      dbg_pi_f_inc              : in    std_logic;
      dbg_pi_f_dec              : in    std_logic;
      dbg_sel_po_incdec         : in    std_logic;
      dbg_po_f_inc              : in    std_logic;
      dbg_po_f_stg23_sel        : in    std_logic;
      dbg_po_f_dec              : in    std_logic;
      dbg_pi_counter_read_val   : out   std_logic_vector(5 downto 0);
      dbg_po_counter_read_val   : out   std_logic_vector(8 downto 0);
      
      -- System Clock Ports
      sys_clk_p                      : in    std_logic;
      sys_clk_n                      : in    std_logic;
      
      -- Reference Clock Ports
      clk_ref_p                                : in    std_logic;
      clk_ref_n                                : in    std_logic;

    sys_rst                     : in    std_logic
  );

end component mig_7series_DDR;

-- ==============================================
--          Signal definitions
-- ==============================================

------ User Interface signals --------------------------------------------- -- Description ------------------------------------------------
signal TB_app_addr             : std_logic_vector(29 downto 0);             -- Indicates the address for the current request
signal TB_app_cmd              : std_logic_vector(2 downto 0);              -- Set read or write for the memory
signal TB_app_en               : std_logic;                                 -- Active high enable for the memory
signal TB_app_rdy              : std_logic;                                 -- Indicates if the User Interface is ready for commands
signal TB_app_rd_data          : std_logic_vector(255 downto 0);         -- app_rd_data[APP_DATA_WIDTH - 1:0], the data read
signal TB_app_rd_data_end      : std_logic;                                 -- Indicates end of read cycle
signal TB_app_rd_data_valid    : std_logic;                                 -- INdicated valid read data
signal TB_app_wdf_data         : std_logic_vector(255 downto 0);            -- app_rd_data[APP_DATA_WIDTH - 1:0], the write data
signal TB_app_wdf_data_end     : std_logic;                                 -- Indicates last cycle of write
signal TB_app_wdf_rdy          : std_logic;                                 -- Indicates FIFO ready to recieve
signal TB_app_wdf_wren         : std_logic;                                 -- Active high strobe that together with app_wdf_rdy accepts data
signal TB_app_sr_req           : std_logic:='0';                            -- Reserved, should be tied 0
signal TB_app_ref_req          : std_logic;                                 -- Active-high, requests refresh command to be issued to the DRAM
signal TB_app_zq_req           : std_logic;                                 -- Active-high, request that a ZQ calibration command be issued to the DRAM
signal TB_app_sr_active        : std_logic;                                 -- Reserved

------ Application Interface signals -------------------------------------- -- Description ------------------------------------------------
signal TB_app_ref_ack          : std_logic;
signal TB_app_zq_ack           : std_logic;
signal TB_ui_clk               : std_logic;
signal TB_ui_clk_sync_rst      : std_logic;
signal TB_app_wdf_mask         : std_logic_vector(31 downto 0);             -- Mask to be applied to the app_wdf_data
       
------ Debug signals ---------------------------------------------- -- Description ------------------------------------------------
-- For the initial test these will just be set to '0' as to not disturb anything
signal TB_dbg_pi_counter_read_val : std_logic_vector(5 downto 0);
signal TB_dbg_sel_pi_incdec       : std_logic                   := '0';
signal TB_dbg_po_counter_read_val : std_logic_vector(8 downto 0);
signal TB_dbg_sel_po_incdec       : std_logic                   := '0';
signal TB_dbg_byte_sel            : std_logic_vector(2 downto 0):= b"000";
signal TB_dbg_pi_f_inc            : std_logic                   := '0';
signal TB_dbg_pi_f_dec            : std_logic;
signal TB_dbg_po_f_inc            : std_logic                   := '0';
signal TB_dbg_po_f_stg23_sel      : std_logic;
signal TB_dbg_po_f_dec            : std_logic;
       
------ Memory interface ------------------------------------------- -- Description ------------------------------------------------
signal TB_ddr3_dq              : std_logic_vector(31 downto 0);
signal TB_ddr3_dqs_p           : std_logic_vector(3 downto 0);
signal TB_ddr3_dqs_n           : std_logic_vector(3 downto 0);

signal TB_ddr3_addr            : std_logic_vector(15 downto 0);
signal TB_ddr3_ba              : std_logic_vector(2 downto 0);
signal TB_ddr3_cas_n           : std_logic;
signal TB_ddr3_ck_n            : std_logic_vector(0 downto 0);                   
signal TB_ddr3_ck_p            : std_logic_vector(0 downto 0);
signal TB_ddr3_cke             : std_logic_vector(1 downto 0);                   
signal TB_ddr3_ras_n           : std_logic;
signal TB_ddr3_reset_n         : std_logic;                
signal TB_ddr3_we_n            : std_logic;
signal TB_init_calib_complete  : std_logic;
signal TB_ddr3_dm              : std_logic_vector(3 downto 0);
signal TB_ddr3_odt             : std_logic_vector(1 downto 0);

signal TB_ddr3_ila_basic       :  std_logic_vector(119 downto 0);
signal TB_ddr3_ila_wrpath      :  std_logic_vector(390 downto 0);
signal TB_ddr3_ila_rdpath      :  std_logic_vector(1023 downto 0); 
signal TB_ddr3_vio_sync_out    :  std_logic_vector(13 downto 0);

signal TB_sys_clk_p            : std_logic:='1';
signal TB_sys_clk_n            : std_logic:='0';
signal TB_clk_ref_p            : std_logic:='1';
signal TB_clk_ref_n            : std_logic:='0';
signal TB_sys_rst              : std_logic:='1';

-- ==============================================
--          End of Signal definitions
-- ==============================================

begin

u_mig_7series_DDR : mig_7series_DDR
 port map (
       -- Memory interface ports
       ddr3_addr                      => TB_ddr3_addr,
       ddr3_ba                        => TB_ddr3_ba,
       ddr3_cas_n                     => TB_ddr3_cas_n,
       ddr3_ck_n                      => TB_ddr3_ck_n,
       ddr3_ck_p                      => TB_ddr3_ck_p,
       ddr3_cke                       => TB_ddr3_cke,
       ddr3_ras_n                     => TB_ddr3_ras_n,
       ddr3_reset_n                   => TB_ddr3_reset_n,
       ddr3_we_n                      => TB_ddr3_we_n,
       ddr3_dq                        => TB_ddr3_dq,
       ddr3_dqs_n                     => TB_ddr3_dqs_n,
       ddr3_dqs_p                     => TB_ddr3_dqs_p,
       init_calib_complete            => TB_init_calib_complete,
       ddr3_dm                        => TB_ddr3_dm,
       ddr3_odt                       => TB_ddr3_odt,

       -- Application interface ports
       app_addr                       => TB_app_addr,
       app_cmd                        => TB_app_cmd,
       app_en                         => TB_app_en,
       app_wdf_data                   => TB_app_wdf_data,
       app_wdf_end                    => TB_app_wdf_data_end,
       app_wdf_mask                   => TB_app_wdf_mask,    --tying the mask high so that nothing is masked away
       app_wdf_wren                   => TB_app_wdf_wren,
       app_rd_data                    => TB_app_rd_data,
       app_rd_data_end                => TB_app_rd_data_end,
       app_rd_data_valid              => TB_app_rd_data_valid,

       app_rdy                        => TB_app_rdy,
       app_wdf_rdy                    => TB_app_wdf_rdy,
       app_sr_req                     => TB_app_sr_req,
       app_ref_req                    => TB_app_ref_req,
       app_zq_req                     => TB_app_zq_req,
       app_sr_active                  => TB_app_sr_active,
       app_ref_ack                    => TB_app_ref_ack,
       app_zq_ack                     => TB_app_zq_ack,
       ui_clk                         => TB_ui_clk,
       ui_clk_sync_rst                => TB_ui_clk_sync_rst,
       
       -- Debug Ports
       ddr3_ila_basic                 => TB_ddr3_ila_basic,
       ddr3_ila_wrpath                => TB_ddr3_ila_wrpath,
       ddr3_ila_rdpath                => TB_ddr3_ila_rdpath,
       ddr3_vio_sync_out              => TB_ddr3_vio_sync_out,
       
       dbg_pi_counter_read_val        => TB_dbg_pi_counter_read_val,
       dbg_sel_pi_incdec              => TB_dbg_sel_pi_incdec,
       dbg_po_counter_read_val        => TB_dbg_po_counter_read_val,
       dbg_sel_po_incdec              => TB_dbg_sel_po_incdec,
       dbg_byte_sel                   => TB_dbg_byte_sel,
       dbg_pi_f_inc                   => TB_dbg_pi_f_inc,
       dbg_pi_f_dec                   => TB_dbg_pi_f_dec,
       dbg_po_f_inc                   => TB_dbg_po_f_inc,
       dbg_po_f_stg23_sel             => TB_dbg_po_f_stg23_sel,
       dbg_po_f_dec                   => TB_dbg_po_f_dec,

       -- System Clock Ports    
       sys_clk_p                       => TB_sys_clk_p,
       sys_clk_n                       => TB_sys_clk_n,

       -- Reference Clock Ports
       clk_ref_p                       => TB_clk_ref_p,
       clk_ref_n                       => TB_clk_ref_n,

      sys_rst                          => TB_sys_rst
    );

-- Setting up clocks
TB_sys_clk_p <= NOT TB_sys_clk_p AFTER (PERIOD/2);
TB_sys_clk_n <= NOT TB_sys_clk_n AFTER (PERIOD/2);
      
TB_clk_ref_p <= NOT TB_clk_ref_p AFTER (PERIOD/2);
TB_clk_ref_n <= NOT TB_clk_ref_n AFTER (PERIOD/2);

TB_sys_rst   <= '1', '0' AFTER PERIOD*4;



end Behavioral;
