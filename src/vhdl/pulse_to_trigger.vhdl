
--*****************************************************************************
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY pulse_to_rigger is
  
  PORT(clk:IN STD_LOGIC;
       reset_n:IN STD_LOGIC;
       start:IN STD_LOGIC;
       trig_pulse:OUT STD_LOGIC);
END pulse_to_rigger;

ARCHITECTURE arch_pulse_to_rigger OF pulse_to_rigger IS
   SIGNAL old_pulse:STD_LOGIC;
   BEGIN
   trigger_proc:
   PROCESS(reset_n,clk)
   BEGIN
      IF (reset_n='0') THEN
         trig_pulse <= '0';
      ELSIF RISING_EDGE(clk) THEN
         IF (start = '1') THEN
            old_pulse <= '1';
            trig_pulse <= '0';
         ELSIF (old_pulse = '1') THEN
            old_pulse <='0';
            trig_pulse <= '1';
         ELSE
            old_pulse <= '0';
            trig_pulse <= '0';
         END IF;
      END IF;
   END PROCESS trigger_proc;
  
END arch_pulse_to_rigger;
