-- Testbench of MULTIPLIER--


library ieee;
use ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity TEST_MULT is
end TEST_MULT;

architecture tb of TEST_MULT is
  constant clk_period: time := 10 ns;
  signal MulA,MulB,MulL_o,MulM_o: std_logic_vector(31 downto 0);
  signal Add: std_logic_vector(63 downto 0);
  signal CC_out: std_logic_vector(3 downto 0);
  signal Optn  : std_logic_vector(2 downto 0);  
  signal reset,clk,Stall : std_logic;
  
  
  BEGIN
    dut:  entity work.Multiplier(Multiplier_behav)
          port map( MulA,MulB,Add,Optn,clk,reset,MulM_o,MulL_o,CC_out,Stall);

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
      MulA<=x"01010101";
      MulB<=x"56432189";
		Add <=x"0013425221002040";
      for I in 0 to 7 loop
        Optn <= std_logic_vector(to_unsigned(I, 3)); 
        if((I = 5) or (I= 7))then
          wait for clk_period;
        end if;
        wait for clk_period;
      end loop;
      Optn <= "000"; 
      wait;
    end process stimulus_process;
  end tb;
      
 

