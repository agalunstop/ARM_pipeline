-- Testbench of Muxes--

library ieee;
use ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity TEST_MUXES is
end TEST_MUXES;

architecture tb of TEST_MUXES is
  constant clk_period: time := 10 ns;
  signal IF_ID  : std_logic_vector(63 DOWNTO 0);   --IF/ID REGister OUTPUT
  signal Dec_out: std_logic_vector(76 downto 0);  --Instruction Register
  signal ID_EX  : std_logic_vector(395 downto 0);  --ID/EX register output
  signal EX_MA  : std_logic_vector(362 downto 0);  --EX/MA register output
  signal MA_WB  : std_logic_vector(339 downto 0);  --MA/WB register output
  signal LDM_RADD: std_logic_vector(3 downto 0);     --Address for LDM generated from Decoder
  signal PC_plus4: std_logic_vector(31 downto 0);     --PC value out of PC acc
  signal DA,DB,DC: std_logic_vector(31 DOWNTO 0);  --OUTPUT OF REGISTER FILE
  signal SHIFTER_OUTPUT: std_logic_vector(31 DOWNTO 0);  --OUTPUT OF SHIFTER BLOCK TAKEN AS INPUT TO ALU_SRCB_MUX
	signal CPSR: std_logic_vector(31 DOWNTO 0); -- OUTPUT VALUE OF CPSR REGISTER
	signal ALU_OUT: std_logic_vector(31 DOWNTO 0); -- OUTPUT FROM ALU UNIT
	signal PC_SOURCE: std_logic_vector(2 DOWNTO 0); --PC SOURCE SEL MUX
  signal MemData_readin: std_logic_vector(31 downto 0);  
	signal REG_A,REG_B,REG_C,WA,WB: std_logic_vector(3 DOWNTO 0); --OUTPUT GIVEN AS INPUT TO REG_FILE
  signal MemData_readout: std_logic_vector(31 downto 0);  --load data memory output
  signal Datamem_addressOut: std_logic_vector(31 downto 0); -- data mem address
  signal MemData_Write1: std_logic_vector(7 downto 0);   -- write data 7:0 to memory
  signal MemData_Write2: std_logic_vector(7 downto 0);   -- write data 15:8 to memory
  signal MemData_Write3: std_logic_vector(7 downto 0);   -- write data 23:16 to memory
  signal MemData_Write4: std_logic_vector(7 downto 0);   -- write data 31:24 to memory
  signal W1,W2,W3,W4: std_logic;                        --write mem enable signals
  signal SHIFT_DATAIN,SHIFT_AMT: std_logic_vector(31 DOWNTO 0);
  signal CPSR_MUX_OUTPUT,SPSR_MUX_OUTPUT: std_logic_vector(31 DOWNTO 0);
  signal ALU_SRCA_0UTPUT, ALU_SRCB_0UTPUT: std_logic_vector(31 DOWNTO 0);
  signal ACC_0UTPUT: std_logic_vector(63 DOWNTO 0);  --OUTPUT OF ACC_SEL_MUX
  signal FORWARD_CPSR_OUTPUT: std_logic_vector(31 DOWNTO 0); --FORWARDED CPSR OUTPUT GIVEN CONDITION CODE CHECK UNIT
  signal PC_SOURCE_OUTPUT: std_logic_vector(31 DOWNTO 0); --OUTPUT OF PC_SOURCE MUX
  signal DWA,DWB: std_logic_vector(31 downto 0);  ---OUTPUT IE. DIS IS SENT TO DWA OF REG. FILE 
 
  BEGIN
    dut:  entity work.Muxes(Muxes_behav)
          port map(IF_ID,Dec_out,ID_EX,EX_MA,MA_WB,LDM_RADD,PC_plus4,
            DA,DB,DC,SHIFTER_OUTPUT,CPSR,ALU_OUT,PC_SOURCE,MemData_readin,
            REG_A,REG_B,REG_C,WA,WB,MemData_readout,Datamem_addressOut,
            MemData_Write1,MemData_Write2,MemData_Write3,MemData_Write4,
            W1,W2,W3,W4,SHIFT_DATAIN,SHIFT_AMT,CPSR_MUX_OUTPUT,SPSR_MUX_OUTPUT,
            ALU_SRCA_0UTPUT, ALU_SRCB_0UTPUT,ACC_0UTPUT,FORWARD_CPSR_OUTPUT,
            PC_SOURCE_OUTPUT,DWA,DWB);

    stimulus_process: PROCESS
    BEGIN
--      reset<='0';
--      wait for clk_period;
--      reset<='1';
--      wait for clk_period;
--      reset<='0';
      wait;

    end process stimulus_process;
  end tb;
