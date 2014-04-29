-- Testbench of ALU--


library ieee;
use ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity test_ALU is
end test_ALU;

architecture tb of test_ALU is
  constant clk_period: time := 10 ns;
  signal ALU_op: std_logic_vector(3 downto 0);
  signal Rn,Op2,Rd: std_logic_vector(31 downto 0);
  signal shiftC,clk,reset,N,C,Z,V_o: std_logic;
  
  BEGIN
    dut:  entity work.ALU(ALU_behav)
          port map(ALU_op,Rn,Op2,shiftC,clk,reset,N,Z,C,V_o,Rd);
    
    clk_process: PROCESS
    BEGIN
      clk <= '1';
      wait for clk_period/2;
      clk <= '0';
      wait for clk_period/2;
    END PROCESS;
    stimulus_process: PROCESS
    BEGIN
      reset<='0';
      wait for clk_period;
      reset<='1';
      wait for clk_period;
      reset<='0';
      shiftC <= '0';
      Rn<=x"01010101";
      Op2<=x"56432189";
      for I in 0 to 15 loop
        ALU_op <= std_logic_vector(to_unsigned(I, 4)); 
        wait for clk_period;
      end loop;
    end process stimulus_process;
  end tb;
      
 

