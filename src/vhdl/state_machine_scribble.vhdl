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
    GENERIC( ADDR_WIDTH : INTEGER:= 10;
             DATA_WIDTH : INTEGER:= 64
             );
    PORT ( clk :      IN STD_LOGIC;
           reset_p:   IN STD_LOGIC;
           
           app_cmd :  IN STD_LOGIC_VECTOR(2 DOWNTO 0);
           app_addr : IN STD_LOGIC_VECTOR(ADDR_WIDTH-1 DOWNTO 0);
           app_en :   IN STD_LOGIC;
           
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
    
    --Setting up the states that the DDR-controller controller will use
    TYPE STATE_TYPE IS (Done, Ready, Writing, Reading);
    SIGNAL 	state, next_state:	STATE_TYPE;
    
BEGIN
    --pseudo code
    app_addr_upper <= app_addr(ADDR_WIDTH-1 DOWNTO ADDR_WIDTH);
    app_addr_lower <= app_addr(ADDR_WIDTH/2-1 DOWNTO 0);

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
        IF (reset_p ='1') THEN
            state	<= Ready;
        ELSIF rising_edge(clk) then 
            if app_en ='1' THEN
                state <= next_state;
            end if;
        END IF;
	END PROCESS;
	
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
