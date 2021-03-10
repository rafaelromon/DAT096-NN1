-----------------------------------------------------
-- Title: DDR_controller_state_machine.vhdl        -- 
-- Author: Sebastian Bengtsson/NN-1                --
-- DAT096 - spring 2021                            --
-----------------------------------------------------
-- Description:                                    --
-- A state mahcine that will control the reading/  --
-- writing to the DDR memory
-- TODO:
-- *Check the ADDR_WDITH
-- *Find out if more states are needed
-- *Check 
-----------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

ENTITY state_machine_scribble IS
    GENERIC( ADDR_WIDTH : INTEGER:= 28; -- # = RANK_WIDTH + BANK_WIDTH + ROW_WIDTH + COL_WIDTH;
             DATA_WIDTH : INTEGER:= 64
             );
    PORT ( clk :      IN STD_LOGIC;
           reset_p:   IN STD_LOGIC;
           
           app_cmd :  IN STD_LOGIC_VECTOR(2 DOWNTO 0);
           app_addr : IN STD_LOGIC_VECTOR(ADDR_WIDTH-1 DOWNTO 0);
           app_en :   IN STD_LOGIC;
           app_rdy :  IN STD_LOGIC;
           
           app_full : OUT STD_LOGIC
           );
END state_machine_scribble;

ARCHITECTURE state_machine_scribble_arch OF state_machine_scribble IS
    -- Setting up constants to make reading and writing more readable
    CONSTANT WRITE : STD_LOGIC_VECTOR(2 DOWNTO 0):= "000";
    CONSTANT READ  : STD_LOGIC_VECTOR(2 DOWNTO 0):= "001";
    
    -- Splitting up the address into its upper and lower componenets
    SIGNAL app_addr_upper : STD_LOGIC_VECTOR(ADDR_WIDTH/2-1 DOWNTO 0);
    SIGNAL app_addr_lower : STD_LOGIC_VECTOR(ADDR_WIDTH/2-1 DOWNTO 0);
    
    -- Signals stolen from "mig_7series_v4_2_traffic_gen_top.v". Where i think I've found a state machine on rows 484-590
    SIGNAL rst_remem    :   STD_LOGIC;
    
    SIGNAL memc_cmd_instr : STD_LOGIC_VECTOR(2 DOWNTO 0);
    
    SIGNAL app_rdy_i    :   STD_LOGIC;
    
    SIGNAL app_cmd1     :   STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL app_cmd2     :   STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL app_cmd3     :   STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL app_cmd4     :   STD_LOGIC_VECTOR(2 DOWNTO 0);
    
    --Setting up the states that the DDR-controller controller will use
    TYPE STATE_TYPE IS (Done, Ready, Writing, Reading);
    SIGNAL 	state, next_state:	STATE_TYPE;
    
BEGIN
    --pseudo code
    app_addr_upper <= app_addr(ADDR_WIDTH-1 DOWNTO ADDR_WIDTH);
    app_addr_lower <= app_addr(ADDR_WIDTH/2-1 DOWNTO 0);

    app_rdy_i <= app_rdy;

--    if !reset_p
--        app_en = 1  -- setting app enable ready and then waiting for the app_rdy to go high
--        if app_rdy && app_en -- When app_rdy and app_en are high then commands can be handled
--            if app_cmd == WRITE -- checking if the commandis WRITE (i.e. 000)
                
--                app_wdf_end <= '1' -- setting this if the word is the last to be written
--             else if app_cmd == READ
            
-- StateReg
    stateRegister:	
    PROCESS( clk )
    --
	BEGIN
        IF (rising_edge( clk )) then
            IF ( reset_p ='1' ) THEN
                rst_remem <= '1';
                app_cmd1 <= "000";
                app_cmd2 <= "000";
                app_cmd3 <= "000";
                app_cmd4 <= "000";
            ELSIF ( app_en ='1' AND app_rdy='1' ) THEN  
                app_cmd1 <= app_cmd;
                app_cmd2 <= app_cmd1;
                app_cmd3 <= app_cmd2;
                app_cmd4 <= app_cmd3;
            END IF;
        END IF;
	END PROCESS;
--	         always @(posedge clk) begin
--           if (rst | tg_rst) begin
--             wr_cmd_cnt <= 1'b0;
--           end else if (memc_cmd_en & (!memc_cmd_full)& (memc_cmd_instr == 3'h0)) begin
--             wr_cmd_cnt <= wr_cmd_cnt + 1'b1;
--           end
--         end
	
	
    predictNextState:
    PROCESS( state, app_cmd )
    
	BEGIN
        CASE state IS
        WHEN Done =>
            next_state <= Ready;
            
        WHEN Ready =>
            CASE app_cmd IS
                WHEN READ =>
                    next_state <= Reading;
                WHEN WRITE =>
                    next_state <= Writing;
                WHEN OTHERS =>
                    next_state <= Ready;
            END CASE;
    
        WHEN OTHERS =>
            next_State <= Done;
        END CASE;
	END PROCESS;
	
	-- Output
output_process :
    PROCESS( state, app_cmd )
    
    BEGIN
	   CASE( app_cmd ) IS
	   	   WHEN "000" => next_state <=Ready;
       END CASE;
    END PROCESS;
end state_machine_scribble_arch;
