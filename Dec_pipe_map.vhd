LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;

ENTITY Dec_pipe_map IS
  
  PORT( IR  : IN  std_logic_vector(31 downto 0); --INSTRUCTION REG.
        Dec_out : IN  std_logic_vector(76 downto 0);  
        clk     : IN  std_logic;
        RA      : IN  std_logic_vector(3 downto 0);  --From Register File
        RB      : IN  std_logic_vector(3 downto 0);  --From Register File
        RC      : IN  std_logic_vector(3 downto 0);  --From Register File
        WA      : IN  std_logic_vector(3 downto 0);  --From MUXES
        WB      : IN  std_logic_vector(3 downto 0);  --From MUXES
        DA      : IN  std_logic_vector(31 downto 0);  --From Register File
        DB      : IN  std_logic_vector(31 downto 0);  --From Register File
        DC      : IN  std_logic_vector(31 downto 0);  --From Register File
        PC_plus4: IN  std_logic_vector(31 downto 0);  --From Register File
        SHIFT_DATAIN: IN std_logic_vector(31 downto 0);-- output from shift data mux
        SHIFT_AMT: IN std_logic_vector(31 downto 0);-- output from shift AMT mux
        CPSR: IN std_logic_vector(31 downto 0);--FROM REG. FILE
        SPSR: IN std_logic_vector(31 downto 0);-- FROM REG. FILE
        ALU_out: IN std_logic_vector(31 downto 0);-- output from ALU UNIT
        mem_data_read: IN std_logic_vector(31 downto 0);-- output from DATA MEMORY
        ALU_S: IN std_logic_vector(3 downto 0);-- status bits
        Mul_S: IN std_logic_vector(3 downto 0);-- status bits
        IF_ID   : OUT std_logic_vector(63 downto 0);  
        ID_EX   : OUT std_logic_vector(395 downto 0);  --ID/EX register output
        EX_MA   : OUT std_logic_vector(362 downto 0);  --EX/MA register output
        MA_WB   : OUT std_logic_vector(339 downto 0);  --MA/WB register output
		  SHIFTER_OUTPUT : IN STD_logic_vector(31 DOWNTO 0); --SHIFTER OUTPUT
		  MUL_L : IN STD_logic_vector(31 DOWNTO 0);  --MULTIPLIER OUTPUT
		  MUL_M : IN STD_logic_vector(31 DOWNTO 0));  --MULTIPLIER OUTPUT
end Dec_pipe_map;

ARCHITECTURE Dec_pipe_map_behav OF Dec_pipe_map IS
  signal IF_ID_int,IF_ID_map: std_logic_vector(63 downto 0);
  signal ID_EX_map,ID_EX_int: std_logic_vector(395 downto 0);
  signal EX_MA_map,EX_MA_int: std_logic_vector(362 downto 0);
  signal MA_WB_map,MA_WB_int: std_logic_vector(339 downto 0);

  begin
    Clk_event: PROCESS(clk)
    begin
      if clk'event and clk='1' then
        IF_ID_int <= IF_ID_map;
        ID_EX_int <= ID_EX_map;
        EX_MA_int <= EX_MA_map;
        MA_WB_int <= MA_WB_map;
		  --DONE NOW---
		  
		    IF_ID <= IF_ID_map;
        ID_EX <= ID_EX_map;
        EX_MA <= EX_MA_map;
        MA_WB <= MA_WB_map;
		  --END NW----
      END if;
    end process Clk_event;

    Mapping: PROCESS(IR,Dec_out,clk,RA,RB,RC,WA,WB,
        DA,DB,DC,PC_plus4,SHIFT_DATAIN,SHIFT_AMT,CPSR,SPSR,ALU_out,mem_data_read,ALU_S,Mul_S,SHIFTER_OUTPUT,MUL_L ,MUL_M)
    begin
      --IF_ID mapping
      IF_ID_map(31 downto 0) <= IR;   --state change.
      IF_ID_map(63 downto 32) <= PC_plus4;   --state change.

      --ID_EX mapping
      ID_EX_map(4 downto 0) <= Dec_out(64 downto 60);
      ID_EX_map(8 downto 5) <= Dec_out(68 downto 65);
      ID_EX_map(9) <= Dec_out(43);
      ID_EX_map(10) <= Dec_out(38);
      ID_EX_map(42 downto 11) <= DA;
      ID_EX_map(74 downto 43) <= DB;
      ID_EX_map(82 downto 75) <= IF_ID_int(19 downto 12);
      ID_EX_map(114 downto 83) <= DC;
      ID_EX_map(118 downto 115) <= Dec_out(76 downto 73);
      ID_EX_map(150 downto 119) <= SHIFT_DATAIN;
      ID_EX_map(162 downto 151) <= IF_ID_int(11 downto 0);
      ID_EX_map(170 downto 163) <= IF_ID_int(11 downto 8)& IF_ID_int(3 downto 0);
      ID_EX_map(174 downto 171) <= RA;
      ID_EX_map(178 downto 175) <= RB;
      ID_EX_map(182 downto 179) <= RC;
      ID_EX_map(186 downto 183) <= WA;
      ID_EX_map(190 downto 187) <= WB;
      ID_EX_map(191) <= Dec_out(41);
      ID_EX_map(192) <= Dec_out(42);
      ID_EX_map(196 downto 193) <= Dec_out(72 downto 69);
      ID_EX_map(197) <= Dec_out(14);
      ID_EX_map(198) <= IF_ID_int(24);
      ID_EX_map(200 downto 199) <= Dec_out(51 downto 50);
      ID_EX_map(202 downto 201) <= Dec_out(17 downto 16);
      ID_EX_map(204 downto 203) <= Dec_out(59 downto 58);
      ID_EX_map(207 downto 205) <= Dec_out(54 downto 52);
      ID_EX_map(211 downto 208) <= Dec_out(36 downto 33);
      ID_EX_map(212) <= Dec_out(50);
      ID_EX_map(213) <= Dec_out(5);
      ID_EX_map(245 downto 214) <= IF_ID_int(63 downto 32);
      ID_EX_map(277 downto 246) <= CPSR;
      ID_EX_map(309 downto 278) <= SPSR;
      ID_EX_map(374 downto 343) <= SHIFT_AMT;
      ID_EX_map(375) <= Dec_out(18);
      ID_EX_map(376) <= Dec_out(44);
      ID_EX_map(377) <= Dec_out(19);
      ID_EX_map(378) <= Dec_out(45);
      ID_EX_map(380 downto 379) <= Dec_out(51 downto 50);
      ID_EX_map(386 downto 384) <= Dec_out(10 downto 8);
      ID_EX_map(388 downto 387) <= Dec_out(57 downto 56);
      ID_EX_map(389) <= Dec_out(55);
      ID_EX_map(390) <= Dec_out(39);
      ID_EX_map(393 downto 391) <= Dec_out(13 downto 11);
      ID_EX_map(395 downto 394) <= Dec_out(25 downto 24);

      --EX_MA mapping      
      EX_MA_map(4 downto 0) <= ID_EX_int(4 downto 0);
      EX_MA_map(36 downto 5) <= ALU_out;
      EX_MA_map(41 downto 38) <= ID_EX_int(8 downto 5);
      EX_MA_map(73 downto 42) <= ID_EX_int(42 downto 11);
      EX_MA_map(74) <= ID_EX_int(9);
      EX_MA_map(75) <= ID_EX_int(10);
      EX_MA_map(107 downto 76) <= ID_EX_int(74 downto 43);
      EX_MA_map(115 downto 108) <= ID_EX_int(82 downto 75);
      EX_MA_map(119 downto 116) <= ALU_S;
      EX_MA_map(123 downto 120) <= ID_EX_int(118 downto 115); 
      EX_MA_map(127 downto 124) <= ID_EX_int(174 downto 171); 
      EX_MA_map(131 downto 128) <= ID_EX_int(178 downto 175); 
      EX_MA_map(135 downto 132) <= ID_EX_int(182 downto 179); 
      EX_MA_map(139 downto 136) <= ID_EX_int(186 downto 183); 
      EX_MA_map(143 downto 140) <= ID_EX_int(190 downto 187); 
      EX_MA_map(144) <= ID_EX_int(191);
      EX_MA_map(145) <= ID_EX_int(192);
      EX_MA_map(149 downto 146) <= ID_EX_int(196 downto 193); 
      EX_MA_map(150) <= ID_EX_int(212);
      EX_MA_map(182 downto 151) <= ID_EX_int(245 downto 214); 
		EX_MA_map(214 DOWNTO 183) <= SHIFTER_OUTPUT;
		EX_MA_map(246 DOWNTO 215) <= MUL_L;
		EX_MA_map(278 DOWNTO 247) <= MUL_M;
      EX_MA_map(342 downto 279) <= ID_EX_int(309 downto 246); 
      EX_MA_map(346 downto 343) <= Mul_S; 
      EX_MA_map(352 downto 347) <= ID_EX_int(380 downto 375);
      EX_MA_map(356 downto 354) <= ID_EX_int(386 downto 384); 
      EX_MA_map(358 downto 357) <= ID_EX_int(388 downto 387); 
      EX_MA_map(361 downto 359) <= ID_EX_int(393 downto 391); 
      EX_MA_map(362) <= ID_EX_int(390);
      
      --MA_WB mapping
      MA_WB_map(31 downto 0) <= EX_MA_int(36 downto 5);
      MA_WB_map(63 downto 32) <= EX_MA_int(107 downto 76);
      MA_WB_map(75 downto 64) <= EX_MA_int(119 downto 108);
      MA_WB_map(79 downto 76) <= EX_MA_int(123 downto 120);
      MA_WB_map(111 downto 80) <= EX_MA_int(182 downto 151);
      MA_WB_map(143 downto 112) <= mem_data_read;
      MA_WB_map(311 downto 144) <= EX_MA_int(350 downto 183);
      MA_WB_map(312) <= EX_MA_int(144);
      MA_WB_map(332 downto 313) <= EX_MA_int(343 downto 324);
      MA_WB_map(334 downto 330) <= EX_MA_int(358 downto 354);
      MA_WB_map(338 downto 335) <= EX_MA_int(362 downto 359);
      MA_WB_map(339) <= EX_MA_int(145);
    end process Mapping;
  end Dec_pipe_map_behav;
      
    
        