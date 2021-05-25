
--*****************************************************************************
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE IEEE.MATH_REAL.ALL;
USE work.function_package.ALL;

entity read_write_ddr is
  GENERIC(
          APP_DATA_WIDTH:INTEGER:=128;
          DATA_WIDTH:INTEGER:=16;
          ADDR_WIDTH:INTEGER:=27);         
  port (ui_clk:IN STD_LOGIC;
        reset_n:IN STD_LOGIC;
        start_write:IN STD_LOGIC;
        start_read:IN STD_LOGIC;
        loop_flag:OUT STD_LOGIC;
        state:OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        app_cmd:OUT STD_LOGIC_VECTOR(2 DOWNTO 0); -- command 001 = READ, 000 = WRITE
        app_addr_in:IN STD_LOGIC_VECTOR(2 DOWNTO 0); --short user address
        app_addr_out:OUT STD_LOGIC_VECTOR(ADDR_WIDTH-1 DOWNTO 0); --27 bit output address
        app_en:OUT STD_LOGIC; --active strobe for app_addr and app_cmd
        app_rdy:IN STD_LOGIC; --UI is ready o accept commands. Ifv the sigbnal is desserted
                              --when app_en is enabled app_cmd and app_addr command must
                              --retried until app_rdy is asserted 
        app_rd_data_in:IN STD_LOGIC_VECTOR(APP_DATA_WIDTH-1 DOWNTO 0); --output from read command
        app_rd_data_out:OUT STD_LOGIC_VECTOR(7 DOWNTO 0); --read data
        app_rd_data_end:IN STD_LOGIC; -- the current clock cycle the last output data
        app_rd_data_valid:IN STD_LOGIC; --indicates that app_re_data is valid
        app_wdf_data_in:IN STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write
        app_wdf_data_out:OUT STD_LOGIC_VECTOR(APP_DATA_WIDTH-1 DOWNTO 0); --data to DDR
        app_wdf_end:OUT STD_LOGIC; --the clock cycle containd the last data to write
        app_wdf_mask:OUT STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0); --mask for app_wdf_data
                                                       --what bits are to be updated
        app_wdf_rdy:IN STD_LOGIC; --the write data FIFO is ready to recive data
        app_wdf_wren:OUT STD_LOGIC --strobe for app_wdf_data
);
end entity read_write_ddr;

ARCHITECTURE arch_read_write_ddr of read_write_ddr is
   TYPE state_type IS (IDLE,W1,W2,W3,W4,W5,R1,R2,R3,R4,R5,R6);
   SIGNAL state_signal:STATE_TYPE;
   SIGNAL next_state_signal:STATE_TYPE;
   
   --Special data type because it is so shite to load the WDF
   TYPE WDF_WORD IS ARRAY(DATA_WIDTH-1 DOWNTO 0) OF STD_LOGIC;
   TYPE WDF      IS ARRAY(DQS_SIZE_func(DATA_WIDTH)-1 DOWNTO 0) OF WDF_WORD;
   
   CONSTANT DATA_CONST      : STD_LOGIC_VECTOR(55 DOWNTO 0):=(OTHERS=>'0');
   CONSTANT ZERO_FILL_CONST : NATURAL:=NATURAL(LOG2(REAL(DATA_WIDTH)));
   CONSTANT ADDR_HIGH_CONST : STD_LOGIC_VECTOR(ADDR_WIDTH-3-ZERO_FILL_CONST-1 DOWNTO 0):=(OTHERS=>'0');
   CONSTANT ADDR_LOW_CONST  : STD_LOGIC_VECTOR(ZERO_FILL_CONST-1 DOWNTO 0):=(OTHERS=>'0');
   CONSTANT READ_DDR_CONST  : STD_LOGIC_VECTOR(2 DOWNTO 0):= "001";
   CONSTANT WRITE_DDR_CONST : STD_LOGIC_VECTOR(2 DOWNTO 0):= "000";
   BEGIN
   state_transition_proc:
   PROCESS(reset_n,ui_clk)
   BEGIN 
      IF (reset_n='0') THEN
         state_signal<=IDLE; --0001
      ELSIF RISING_EDGE(ui_clk) THEN
            state_signal <= next_state_signal;
      END IF;
   END PROCESS state_transition_proc; 

   stateflow_proc:
   PROCESS(state_signal,ui_clk,start_write,start_read)
   BEGIN
      CASE state_signal IS
         WHEN IDLE => --110
            IF (start_write = '1') THEN
               next_state_signal <= W1; --0001
            ELSIF (start_read = '1') THEN
               next_state_signal <= R1; --0111
            ELSE
               next_state_signal <= IDLE;
            END IF;
         WHEN W1 => --0001
               IF((app_rdy = '0') AND
                  (app_wdf_rdy = '1')) THEN
                  next_state_signal <= W2; --0010
               ELSE
                  next_state_signal <= W1; --0001
               END IF;
         WHEN W2 => --0010
            IF (app_rdy = '0') THEN --AND
               next_state_signal <= W3; --0011
            ELSE
               next_state_signal <= W2; --0010
            END IF;
          WHEN W3 => --0011
             IF ((app_rdy = '0') AND
                 (app_wdf_rdy = '1')) THEN   
                     next_state_signal <= W4; --0100
            ELSE
                next_state_signal <= W3; --0011
             END IF;
          WHEN W4 => --0100
             next_state_signal <= W5; --0101
          WHEN W5 => --0101
              next_state_signal <= IDLE; --1110                
          WHEN R1 => --0110
            IF ((app_rdy = '1') AND 
                (app_rd_data_valid = '0')) THEN -- AND 
               next_state_signal<=R2; --0111
            ELSE
               next_state_signal <= R1; --0110
            END IF;
         WHEN R2 => --0111
            next_state_signal <= R3; --1000
         WHEN R3 => --1000
            next_state_signal <= R4; --1001
         WHEN R4 => --1001
            IF (app_rd_data_valid = '1') THEN --AND
               next_state_signal <= R5; --1010
            ELSE
               next_state_signal <= R4; --1001
            END IF;
         WHEN R5 => --1010
            next_state_signal <= R6; --1011
         WHEN R6 => --1011
            IF (app_rd_data_valid = '0') THEN
               next_state_signal <= IDLE; --1110
            ELSE
               next_state_signal <= R6;
           END IF;
      END CASE;   
   END PROCESS stateflow_proc;

   assignment_proc:
   PROCESS(state_signal,ui_clk)
   BEGIN
      CASE state_signal IS
         WHEN IDLE =>
            state <= "1110";
            app_en<='0';
            app_wdf_wren <= '0';
            app_wdf_end <= '0';
         WHEN W1 =>
            state <= "0001";
            app_addr_out <= ADDR_HIGH_CONST & app_addr_in & ADDR_LOW_CONST;
            app_en <= '0';
            app_wdf_wren <= '0';
            app_wdf_end <= '0';
         WHEN W2 =>
            state <= "0010";
            app_addr_out <= ADDR_HIGH_CONST & app_addr_in & ADDR_LOW_CONST;
            app_cmd <= WRITE_DDR_CONST;
            app_en <= '1';
            -- Here we'll have to experiment a bit
            --app_wdf_data_out <= DATA_CONST & app_wdf_data_in & DATA_CONST & app_wdf_data_in;
            FOR i IN 0 TO DQS_SIZE_func(DATA_WIDTH)-1 LOOP
                app_wdf_data_out((i+1)*DATA_WIDTH-1 DOWNTO i*DATA_WIDTH) <= DATA_CONST & app_wdf_data_in;
            END LOOP;
            app_wdf_wren <= '1';
            app_wdf_end <= '0';
         WHEN W3 =>
            state <= "0011";
            app_addr_out <= ADDR_HIGH_CONST & app_addr_in & ADDR_LOW_CONST;
            app_cmd <= WRITE_DDR_CONST;
            app_en <= '1';
            -- Here we'll have to experiment a bit
            FOR i IN 0 TO DQS_SIZE_func(DATA_WIDTH)-1 LOOP
                app_wdf_data_out((i+1)*DATA_WIDTH-1 DOWNTO i*DATA_WIDTH) <= DATA_CONST & app_wdf_data_in;
            END LOOP;
            app_wdf_wren <= '1';
            app_wdf_end <= '1';
         WHEN W4 =>
            state <= "0100";
            app_addr_out <= ADDR_HIGH_CONST & app_addr_in & ADDR_LOW_CONST;
            app_cmd <= WRITE_DDR_CONST;
            app_en <= '1';
            app_wdf_wren <= '1';
            app_wdf_end <= '1';
         WHEN W5 =>
            state <= "0101";
            app_en <= '0';
            app_wdf_wren <= '0';
            app_wdf_end <= '0';
         WHEN R1 =>
            state <= "0110";
            app_addr_out <= ADDR_HIGH_CONST & app_addr_in & ADDR_LOW_CONST;
            app_cmd <= READ_DDR_CONST;
            app_en <= '0';
         WHEN R2 =>
            state <= "0111";
            app_cmd <= READ_DDR_CONST;
           app_addr_out <= ADDR_HIGH_CONST & app_addr_in & ADDR_LOW_CONST;
            app_en <= '1';
         WHEN R3 =>
            state <= "1000";
            app_addr_out <= ADDR_HIGH_CONST & app_addr_in & ADDR_LOW_CONST;
            app_cmd <= READ_DDR_CONST;
            app_en <= '0';
         WHEN R4 =>
            state <= "1001";
            app_en <= '0';
            app_rd_data_out <= app_rd_data_in(7 DOWNTO 0);
         WHEN R5 =>
            state <= "1010";
         WHEN R6 =>
            state <= "1011";
      END CASE;
   END PROCESS assignment_proc;

end architecture arch_read_write_ddr;
