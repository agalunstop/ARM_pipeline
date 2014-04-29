-- Testbench of Decoder--


library ieee;
use ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity TEST_DEC is
end TEST_DEC;

architecture tb of TEST_DEC is
  constant clk_period: time := 10 ns;
  signal Dec_out: std_logic_vector(76 downto 0);
  signal IF_ID: std_logic_vector(63 downto 0);
  signal CC: std_logic_vector(3 downto 0);
  signal IC_hit,DC_hit,clk,reset,stall : std_logic;
  
  BEGIN
    dut:  entity work.Decoder(Decoder_behav)
          port map(IF_ID,IC_hit,DC_hit,clk,reset,CC,stall,Dec_out);

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
      IC_hit<='1';
      DC_hit<='1';
		CC<=x"F";
		
		--SINGLE CYCLE INST.
      stall<='0';
     
--      IF_ID(31 downto 0)<=x"02945225"; --data processing rotate immediate
--      IF_ID(63 DOWNTO 32)<=X"00000004";
--      WAIT FOR clk_period;
--		IF_ID(31 downto 0)<=x"00945282"; --data processing shift & Rm
--      IF_ID(63 DOWNTO 32)<=X"00000008";
--		WAIT FOR clk_period;
--		IF_ID(31 downto 0)<=x"00945112";  --data processing Rs & Rm
--      IF_ID(63 DOWNTO 32)<=X"0000000C";
--		WAIT FOR clk_period;
--		IF_ID(31 downto 0)<=x"00854192";  --UMULL
--      IF_ID(63 DOWNTO 32)<=X"00000010";
--		WAIT FOR clk_period;
--		IF_ID(31 downto 0)<=x"05F45442";  --LOAD, PREINCR BYTE , UP,12 BIT IMMediate
--      IF_ID(63 DOWNTO 32)<=X"00000014";
--		WAIT FOR clk_period;
--		IF_ID(31 downto 0)<=x"05245442";  --STORE, PREINCR, DOWN , 12BIT IMM,WORD
--      IF_ID(63 DOWNTO 32)<=X"00000018";
--		WAIT FOR clk_period;	
--		IF_ID(31 downto 0)<=x"06B45282";  --LOAD FROM Rm, POST INC, WORD,UP
--      IF_ID(63 DOWNTO 32)<=X"0000001C";
--		WAIT FOR clk_period;	
--		IF_ID(31 downto 0)<=x"01F452B1";  --LOAD PREINCR,UP,IMM,UNSIGNED HALFWORD
--      IF_ID(63 DOWNTO 32)<=X"00000020";
--		WAIT FOR clk_period;
--		IF_ID(31 downto 0)<=x"004456D1";  --STORE POSTINCR,DOWN,IMM,SIGNED BYTE
--      IF_ID(63 DOWNTO 32)<=X"00000024";
--		WAIT FOR clk_period;
--		IF_ID(31 downto 0)<=x"001450F2";  --LOAD POST INCR, DOWN RM , SIGNED HALFWORD
--      IF_ID(63 DOWNTO 32)<=X"00000028";
--		WAIT FOR clk_period;
--		IF_ID(31 downto 0)<=x"014F5000";  --GPR <--SPSR
--      IF_ID(63 DOWNTO 32)<=X"0000002C";
--		WAIT FOR clk_period;
--		IF_ID(31 downto 0)<=x"010F5000";   --GPR<--CPSR
--      IF_ID(63 DOWNTO 32)<=X"00000030";
--		WAIT FOR clk_period;
--		IF_ID(31 downto 0)<=x"0366F258";  --SPSR<--GPR --ROTATE
--      IF_ID(63 DOWNTO 32)<=X"00000034";
--		WAIT FOR clk_period;
--		IF_ID(31 downto 0)<=x"0127F002";  --CPSR<--GPR --Rm
--      IF_ID(63 DOWNTO 32)<=X"00000038";
--		WAIT FOR clk_period;
--		--2 CYCLE INSTRUCTION
--		STAll <= '1';
		IF_ID(31 downto 0)<=x"03B54192";  --UMLAL
      IF_ID(63 DOWNTO 32)<=X"0000003C";
		STAll <= '1';
		WAIT FOR clk_period;
		STAll <= '0';
		WAIT FOR clk_period;
--		IF_ID(31 downto 0)<=x"03B54192";  --UMLAL
--      IF_ID(63 DOWNTO 32)<=X"0000003C";
--		WAIT FOR clk_period;
--		STALL <= '1';
--		IF_ID(31 downto 0)<=x"01045092";  --SWAP
--      IF_ID(63 DOWNTO 32)<=X"00000040";
--		WAIT FOR clk_period;
--		STALL <= '0';
--		IF_ID(31 downto 0)<=x"01045092";  --SWAP
--      IF_ID(63 DOWNTO 32)<=X"00000040";
--		WAIT FOR clk_period;
--		STALL <= '1';
		IF_ID(31 downto 0)<=x"0F4C7213";  --SWI
      IF_ID(63 DOWNTO 32)<=X"00000044";
		WAIT FOR clk_period;
		WAIT FOR clk_period;
--		STALL <= '0';
--		IF_ID(31 downto 0)<=x"0F4C7213";  --SWI
--      IF_ID(63 DOWNTO 32)<=X"00000044";
--		WAIT FOR clk_period;
	
      --BRANCH INSTRUCTION	
		STALL <= '0'; 
		IF_ID(31 downto 0)<=x"0B4C7213";  --BL
      IF_ID(63 DOWNTO 32)<=X"00000048";
		WAIT FOR clk_period;
		WAIT FOR clk_period;
		IF_ID(31 downto 0)<=x"012FFF12";  --BX Rm
      IF_ID(63 DOWNTO 32)<=X"0000004C";
		WAIT FOR clk_period;
		WAIT FOR clk_period;
		IF_ID(31 downto 0)<=x"012FFF32";  --BLX Rm
      IF_ID(63 DOWNTO 32)<=X"00000050";
		WAIT FOR clk_period;
		WAIT FOR clk_period;
		IF_ID(31 downto 0) <=X"FB4C7213";  --BLX LABEL
      IF_ID(63 DOWNTO 32)<=X"00000054";
		WAIT FOR clk_period;
		WAIT FOR clk_period;
		
		--MULTIPLE STALL INST(LDM ,STM)
--		STALL <= '1'; --NOT FROM OTHER MODULE
--		
		IF_ID(31 downto 0)<=x"09B42028";  --LDM,PREINCR,UP
      IF_ID(63 DOWNTO 32)<=X"00000058";
		WAIT FOR clk_period*4;
--		STALL <= '0';
--		WAIT FOR clk_period;
--		IF_ID(31 downto 0)<=x"08042028";  --STM, POST INC, DOWN
--      IF_ID(63 DOWNTO 32)<=X"0000005C";
--		WAIT FOR clk_period;
--		STALL <= '0';
--		WAIT FOR clk_period;
wait;
		
      end process stimulus_process;
  end tb;
