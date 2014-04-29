LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;

ENTITY Top_ARM IS
  
  PORT( reset     : IN  std_logic;
        clk       : IN  std_logic;
        IC_dat    : IN  std_logic_vector(31 downto 0);
        IC_hit    : IN  std_logic;
        DC_datin  : IN  std_logic_vector(31 downto 0);
        DC_hit    : IN  std_logic;
        IC_add    : OUT std_logic_vector(31 downto 0);
        DC_add    : OUT std_logic_vector(31 downto 0);
        DC_datout : OUT std_logic_vector(31 downto 0);
        DC_WE1    : OUT std_logic;
        DC_WE2    : OUT std_logic;
        DC_WE3    : OUT std_logic;
        DC_WE4    : OUT std_logic;
        DC_RE     : OUT std_logic);
        
end Top_ARM;

ARCHITECTURE Top_ARM_behav OF Top_ARM IS

  --RF signals
  signal WrA,WrB,WrPC,WrCPSR,WrSPSR:std_logic;
  signal RA,RB,RC,WA_WRITEBACK,WB_WRITEBACK: std_logic_vector(3 downto 0);
  signal PCin,CPSRin,SPSRin,DA,DB,DC,PC,CPSR,SPSR: std_logic_vector(31 downto 0);

  --MUX signals
  signal PC_plus4,SHIFTER_OUTPUT,ALU_OUT,
        MemData_readin,MemData_readout,Datamem_addressOut,
        SHIFT_DATAIN,SHIFT_AMT,CPSR_MUX_OUTPUT,SPSR_MUX_OUTPUT,
        ALU_SRCA_0UTPUT, ALU_SRCB_0UTPUT,FORWARD_CPSR_OUTPUT,
        PC_SOURCE_OUTPUT,DWA,DWB: std_logic_vector(31 downto 0);
  signal Dec_out: std_logic_vector(76 downto 0);
  signal ID_EX: std_logic_vector(395 downto 0);
  signal EX_MA: std_logic_vector(362 downto 0);
  signal MA_WB: std_logic_vector(339 downto 0);
  signal LDM_RADD,REG_A,REG_B, REG_C,WA,WB: std_logic_vector(3 downto 0);
  signal PC_SOURCE: std_logic_vector(2 downto 0);
  signal MemData_Write1,MemData_Write2,MemData_Write3,
        MemData_Write4: std_logic_vector(7 downto 0);
  signal W1,W2,W3,W4: std_logic;
  signal ACC_0UTPUT: std_logic_vector(63 DOWNTO 0);
  
  --Shifter
  signal Input,Amnt,Output : std_logic_vector(31 downto 0);  --Input to be shifted
  signal Contrl: std_logic_vector(1 downto 0);   --Control input to specify RR,RL,LLS, A
  signal ShiftC: std_logic;
  
  --Multiplier
  signal MulA,MulB,MulM_o,MulL_o : std_logic_vector(31 downto 0);
  signal Add: std_logic_vector(63 downto 0);
  signal Optn: std_logic_vector(2 downto 0);
  signal CC_out: std_logic_vector(3 downto 0);
  signal stall: std_logic; 
  
  --Hazard_Unit
  signal ID_EX_HDU: std_logic_vector(9 downto 0);
  
  --Decoder_Unit
  signal CC: std_logic_vector(3 downto 0);
  
  --Pipeline map
  signal IR,mem_data_read,MUL_L,MUL_M: std_logic_vector(31 downto 0);
  signal ALU_S,Mul_S: std_logic_vector(3 downto 0);
  signal IF_ID: std_logic_vector(63 downto 0);  
  
  --ALU map
  signal ALU_op: std_logic_vector(3 downto 0);
  signal Rn,Op2,Rd: std_logic_vector(31 downto 0);
  signal N,Z,C,V_o: std_logic;    --Carry bit from the shifter
  
  begin
    RF: entity work.Register_File(RF_behav)
        port map(reset,clk,WrA,WrB,WrPC,WrCPSR,WrSPSR,RA,
          RB,RC,WA_WRITEBACK,WB_WRITEBACK,DWA,DWB,PCin,CPSRin,SPSRin,DA,
          DB,DC,PC,CPSR,SPSR);
			 
	MUX: ENTITY WORK.Muxes(Muxes_behav)
		  PORT MAP(IF_ID,Dec_out,ID_EX,EX_MA,MA_WB ,LDM_RADD,PC_plus4,REG_A,REG_B,REG_C,WA,WB,DA,DB,DC,		
		  SHIFTER_OUTPUT,CPSR,ALU_OUT,PC_SOURCE,MemData_readin,MemData_readout,Datamem_addressOut,MemData_Write1,
		  MemData_Write2 ,MemData_Write3,MemData_Write4,W1,W2,W3,W4,SHIFT_DATAIN,SHIFT_AMT,CPSR_MUX_OUTPUT,SPSR_MUX_OUTPUT,
		  ALU_SRCA_0UTPUT, ALU_SRCB_0UTPUT,ACC_0UTPUT,FORWARD_CPSR_OUTPUT ,PC_SOURCE_OUTPUT ,DWA,DWB );
		  
	SHIFTER:ENTITY WORK.Shifter(Shifter_behav)
		     PORT MAP(Input,Contrl,Amnt,Output,ShiftC);
			  
	MULTIPIER: ENTITY WORK.Multiplier(Multiplier_behav)
				  PORT MAP(MulA,MulB,Add,Optn,clk,reset,MulM_o,MulL_o,CC_out,Stall);
				  
	HAZARD_UNIT:ENTITY WORK.Hazard_DU(Hazard_DU_behav) 
					PORT MAP(RA,RB,RC,ID_EX_HDU,stall);
		
		
	DECODER_UNIT: ENTITY WORK.Decoder(Decoder_behav)
					  PORT MAP(IF_ID,IC_hit,DC_hit,clk,reset,CC,stall,Dec_out );
					  
	PIPELINE_MAP:ENTITY WORK.Dec_pipe_map(Dec_pipe_map_behav)
					 PORT MAP(IR,Dec_out,clk,RA,RB,RC,WA,WB,DA,DB,
                         DC,PC_plus4,SHIFT_DATAIN,SHIFT_AMT,CPSR,SPSR,
								 ALU_out,mem_data_read,ALU_S,Mul_S,IF_ID,ID_EX,EX_MA,MA_WB,SHIFTER_OUTPUT,MUL_L, MUL_M);

	ALU:ENTITY WORK.ALU(ALU_behav)
		 PORT MAP( ALU_op,Rn,Op2,shiftC,clk,reset,N,Z,C,V_o,Rd);
		 
	-------------------------------------------------------------------------------------
	 --BASIC STAGE
    PC_plus4 <= PC + 4;  --Adding value 4 to RF output
    IC_add <= PC;        --Instruction Cache address
    IR <= IC_dat;     --Instruction Cache data
	 -----------------------------------------------------------------------------
	 --DATA MEMORY INTERFACING
    DC_add <= Datamem_addressOut;   --Data mem address from mux
    MemData_readin <= DC_datin;    --Data read in from mem to mux
    DC_datout(7 downto 0) <= MemData_Write1;   --Data to be written to memory 
    DC_datout(15 downto 8) <= MemData_Write2;   --Data to be written to memory 
    DC_datout(23 downto 16) <= MemData_Write3;   --Data to be written to memory 
    DC_datout(31 downto 24) <= MemData_Write4;   --Data to be written to memory 
    DC_WE1 <= W1;                               --Write enable to DC bankwise
    DC_WE2 <= W2;                               --Write enable to DC bankwise
    DC_WE3 <= W3;                               --Write enable to DC bankwise
    DC_WE4 <= W4;                               --Write enable to DC bankwise
    DC_RE <= EX_MA(150);                        --Mem read enable
	 ----------------------------------------------------------------------------
	 --REGISter_File CONNECTIONS
	 --reset : IN  std_logic;
    --clk   : IN  std_logic;                    
	  WrA <=MA_WB(308);  
	  WrB <=MA_WB(309);  
	  WrPC <= DEC_out(0); 
	  WrCPSR <= MA_WB(310);                   
	  WrSPSR <= MA_WB(311);
	  RA <=REG_A;   
	  RB <=REG_B; 
	  RC <=REG_C;
	  WA_WRITEBACK <= MA_WB(328 DOWNTO 325); 
	 WB_WRITEBACK <= MA_WB(332 DOWNTO 329); 
	  --DWA(REG. FILE) <= DWA(MUX OUTPUT);
	  --DWB(REG. FILE) <= DWB(MUX OUTPUT); 
	  PCin <= PC_SOURCE_OUTPUT; 
	  CPSRin <= CPSR_MUX_OUTPUT;
	  SPSRin <= SPSR_MUX_OUTPUT;
	  --DA(DEC_pipe_map OR MUXES)  <= DA(REG. FILE); 
	  --DB(DEC_pipe_map OR MUXES)  <= DB(REG. FILE); 
	  --DC(DEC_pipe_map OR MUXES)  <= DC(REG. FILE);  
	  --PC(WILL BE GIVEN IC ADD PINS) <= PC(FROM REG. FILE)    
	  --CPSR(MUXES FOR INPUT TO FORWARD_CPSR_MUX_SEL OR DEC_Pipe_map)<=CPSR(REG. FILE)
	  --SPSR(DEC_Pipe_map) <= SPSR(REG. FILE);
	  
	 
	 -------------------------------------------------------------------------
	 --SHIFTER BLOCK CONNECTIONS
	 Input <= ID_EX(150 DOWNTO 119); 
	 Contrl <= ID_EX(395 DOWNTO 394);
    Amnt <= ID_EX(374 DOWNTO 343);
	 SHIFTER_OUTPUT <= Output;
   -- SHIFTC(ALU) <=ShiftC(SHIFTER);  
	---------------------------------------------------------------------------
	--ALU BLOCK CONNECTIONS
	ALU_op <= ID_EX(211 DOWNTO 208);
   Rn <=ALU_SRCA_0UTPUT;
   Op2 <= ALU_SRCB_0UTPUT;
	 -- SHIFTC(ALU) <=ShiftC(SHIFTER);
    --    clk     : IN  std_logic;    --clk
    --    reset   : IN  std_logic;    --reset
   ALU_S <= N & Z & C & V_o;     
	ALU_OUT <= Rd;	
	
	--------------------------------------------------------------------------
	--MULTIPIER BLOCK CONNECTIONS
	MulA <= ID_EX(74 DOWNTO 43);   
   MulB <= ID_EX(114 DOWNTO 83);   
   Add  <= ACC_0UTPUT; 
   Optn <=ID_EX(207 DOWNTO 205);
    --clk   : IN  std_logic;
    --    reset : IN  std_logic;
   MUL_M <= MulM_o;
   MUL_L <= MulL_o;
   MUL_S <= CC_out;
    --    Stall : OUT std_logic
	 ---------------------------------------------------------------------------
	 --HAZARD BLOCK CONNECTIONS
	  RA  <= REG_A;    
     RB   <=REG_B;   
     RC <=REG_C;  
     ID_EX_HDU(9 DOWNTO 2) <=ID_EX(190 DOWNTO 183);
	  ID_EX_HDU(1 DOWNTO 0) <=ID_EX(376 DOWNTO 375);
	  --stall     : OUT std_logic
   ---------------------------------------------------------------------------
	--MUXES CONNECTIONS
	--IF_ID(MUXES) <= IF_ID(DEC_Pipe_map);
   --Dec_out(INPUT TO MUX UNIT) <= Dec_out(FROM DECODER_UNIT)    
   --ID_EX(INPUT TO MUX UNIT) <= ID_EX(Dec_pipe_map);
	--EX_MA(INPUT TO MUX UNIT) <= EX_MA(Dec_pipe_map);
	--MA_WB(INPUT TO MUX UNIT) <= MA_WB(Dec_pipe_map);	
   LDM_RADD <=Dec_out(76 DOWNTO 73);  
   --PC_plus4 : DEFINED IN BASIC STAGE; 
   --REG_A,REG_B, REG_C : CONNECTIONS DEFINED IN REG. FILE 
   --WA(DEC_pipe_map) <= WA(MUX OUTPUT FOR WA_SEL);
	--WB(DEC_pipe_map) <= WB(MUX OUTPUT FOR WB_SEL);
   --DA : DEFINED IN REG. FILE;
	--DB : DEFINED IN REG. FILE;
	--DC	: DEFINED IN REG. FILE;
   --SHIFTER_OUTPUT : DEFINED IN SHIFTER BLOCK
	--CPSR : DEFINED IN REG. FILE
   --ALU_OUT : DEFINED IN ALU UNIT
	PC_SOURCE <= Dec_out(3 DOWNTO 1);
	--MemData_readin  : DEFINED DATA CACHE MEMORY INTERFACING 
	Mem_data_read <= MemData_readout;
	--Datamem_addressOut : DEFINED DATA CACHE MEMORY INTERFACING 
	--MemData_Write1 : DEFINED DATA CACHE MEMORY INTERFACING 
	--MemData_Write2 : DEFINED DATA CACHE MEMORY INTERFACING 
	--MemData_Write3 : DEFINED DATA CACHE MEMORY INTERFACING 
	--MemData_Write4 : DEFINED DATA CACHE MEMORY INTERFACING 
	--W1,W2,W3,W4: DEFINED DATA CACHE MEMORY INTERFACING 
	--SHIFT_DATAIN(DEC_Pipe_map) <= SHIFT_DATAIN(MUXES) 
	--SHIFT_AMT(DEC_Pipe_map) <= SHIFT_AMT(MUXES)
	--ID_EX() <= SUM VALUE SHIFT_DATAIN,SHIFT_AMT : DONE IN DE_PIPEMAP
	--CPSR_MUX_OUTPUT,SPSR_MUX_OUTPUT : DEFINED IN REG. FILE
	--ALU_SRCA_0UTPUT, ALU_SRCB_0UTPUT : DEFINED IN ALU UNIT
	--ACC_0UTPUT : DEFINED IN MULTIPIER UNIT
	--FORWARD_CPSR_OUTPUT : DEFINED IN DECODER_UNIT
	--PC_SOURCE_OUTPUT : DEFINED IN REG. FILE
	--DWA,DWB : DEFINED IN REG. FILE  ---OUTPUT IE. DIS IS SENT TO DWA OF REG. FILE 
	--------------------------------------------------------------------------------------------
	--DECODER CONNECTIONS
	--IF_ID(DECODER) <= IF_ID(DEC_Pipe_map);
   --IC_hit  : INPUT GIVEN FROM TEST BENCH
   --DC_hit  : NOT IMPLEMENTED
   --clk  : IN STD_logic;   
   --reset :IN STD_logic;  
	CC	<= FORWARD_CPSR_OUTPUT(31 DOWNTO 28);    
	--stall : IN STD_logic; 
	--Dec_out(DEC_pipe_map) <= Dec_out(DECODER); 
	-------------------------------------------------------------------------------------------
	--DEC_pipe_map CONNECTIONS
	--IR <= DEFINED IN BASIC STAGE
   --Dec_out : DEFINED IN DECODER STAGE;
   --clk     : IN  std_logic;
   --RA : DEFINED IN REG. FILE   
   --RB : DEFINED IN REG. FILE      
   --RC : DEFINED IN REG. FILE      
   --WA(DEC_pipe_map) <= WA(MUX OUTPUT FOR WA_SEL);
   --WB(DEC_pipe_map) <= WB(MUX OUTPUT FOR WB_SEL);
   --DA  : DEFINED IN REG. FILE;
   --DB	: DEFINED IN REG. FILE;
   --DC : DEFINED IN REG. FILE;
	--PC_plus4 : DEFINED IN BASIC STAGE;
   --SHIFT_DATAIN: DEFINED IN MUXES UNIT
   --SHIFT_AMT: DEFINED IN MUXES UNIT
   --CPSR: DEFINED IN REG. FILE
   --SPSR:DEFINED IN REG. FILE
   --ALU_out: DEFINED IN ALU UNIT
   --mem_data_read: DEFINED IN MUXES UNIT
   --ALU_S: DEFINED IN ALU UNIT
   --Mul_S: DEFINED IN MULTIPIER UNIT
   --IF_ID(MUXES) <= IF_ID(DEC_pipe_map);
   --ID_EX(MUXES) <= ID_EX(DEC_pipe_map);
   --EX_MA(MUXES) <= EX_MA(DEC_pipe_map);
   --MA_WB(MUXES) <= MA_WB(DEC_pipe_map);
	--SHIFTER_OUTPUT: DEFINED IN SHIFTER UNIT
	--MUL_M: DEFINED IN MULTIPIER UNIT
	--MUL_L: DEFINED IN MULTIPIER UNIT
	-----------------------------------------------------------------------------------
	
  
END Top_ARM_behav;
