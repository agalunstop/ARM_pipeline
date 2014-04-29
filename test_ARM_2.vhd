-- Testbench of top_arm--


library ieee;
use ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity test_ARM is
end test_ARM;

architecture tb of test_ARM is
  constant clk_period: time := 10 ns;
  signal IC_dat,DC_datin,ARM_DC_datin,IC_add,DC_add,ARM_DC_add,
    DC_datout,ARM_DC_datout: std_logic_vector(31 downto 0);
  signal clk,reset,IC_hit,DC_hit,DC_WE1,DC_WE2,DC_WE3,DC_WE4,
    ARM_DC_WE1,ARM_DC_WE2,ARM_DC_WE3,ARM_DC_WE4,DC_RE,ARM_DC_RE: std_logic;
       

  BEGIN
    dut:  entity work.Top_ARM(Top_ARM_behav)
          port map(reset,clk,IC_dat,IC_hit,ARM_DC_datin,DC_hit,IC_add,
            ARM_DC_add,ARM_DC_datout,ARM_DC_WE1,ARM_DC_WE2,ARM_DC_WE3,
            ARM_DC_WE4,ARM_DC_RE);
			          
	  datacache: entity work.Data_Cache(Data_Cache_behav)
	             port map(DC_WE1,DC_WE2,DC_WE3,DC_WE4,DC_RE,DC_datin,DC_add,
	               clk,reset,DC_hit,DC_datout);
    
    clk_process: PROCESS
    BEGIN
      clk <= '1';
      wait for clk_period/2;
      clk <= '0';
      wait for clk_period/2;
    END PROCESS;
    stimulus_process: PROCESS
    BEGIN
      IC_hit<= '1';
      reset<='0';
      wait for clk_period;
      reset<='1';
      wait for clk_period;
      reset<='0';
      wait for clk_period;
      
      DC_datin<=x"00000004";
      DC_add <= x"00000000";
      DC_WE1<='1';
      DC_WE2<='1';
      DC_WE3<='1';
      DC_WE4<='1';
      wait for clk_period;
      DC_datin<=x"00000002";
      DC_add <= x"00000004";
      DC_WE1<='1';
      DC_WE2<='1';
      DC_WE3<='1';
      DC_WE4<='1';
      wait for clk_period;
      DC_datin<=x"00000006";
      DC_add <= x"00000008";
      DC_WE1<='1';
      DC_WE2<='1';
      DC_WE3<='1';
      DC_WE4<='1';
      wait for clk_period;
      DC_datin<=x"00000005";
      DC_add <= x"0000000C";
      DC_WE1<='1';
      DC_WE2<='1';
      DC_WE3<='1';
      DC_WE4<='1';
      wait for clk_period;
      DC_datin<=x"00000008";
      DC_add <= x"00000010";
      DC_WE1<='1';
      DC_WE2<='1';
      DC_WE3<='1';
      DC_WE4<='1';
      wait for clk_period;
      DC_add <= x"00000000";
      DC_RE <= '1';
      wait for clk_period;
      DC_add <= x"00000004";
      DC_RE <= '1';
      wait for clk_period;
      DC_add <= x"00000008";
      DC_RE <= '1';
      wait for clk_period;
      DC_add <= x"0000000C";
      DC_RE <= '1';
      wait for clk_period;
      DC_add <= x"00000010";
      DC_RE <= '1';
      wait for clk_period;
      
      DC_add <= ARM_DC_add;
      DC_datin <= ARM_DC_datout;
      ARM_DC_datin <= DC_datout;
      DC_RE <= ARM_DC_RE;
      DC_WE1 <= ARM_DC_WE1;
      DC_WE2 <= ARM_DC_WE2;
      DC_WE3 <= ARM_DC_WE3;
      DC_WE4 <= ARM_DC_WE4;
      
--stimulus
      if(IC_add=x"00000000") then
		    IC_dat <= x"E5901000"; --INSTRUCTION
		  end if;
		  wait until IC_add = x"00000004";
		    IC_dat <= x"E5902004"; --INSTRUCTION
		  wait until IC_add=x"00000008";
		    IC_dat <= x"E5903008"; --INSTRUCTION
		  wait until IC_add=x"0000000C";
		    IC_dat <= x"E590400C"; --INSTRUCTION
		  wait until IC_add=x"00000010";
		    IC_dat <= x"E5905000"; --INSTRUCTION
		  wait until IC_add=x"00000014";
		    IC_dat <= x"E5906004"; --INSTRUCTION
      wait;
      
    end process stimulus_process;
  end tb;
      
 


