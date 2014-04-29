LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;

ENTITY Muxes IS
  
  PORT( IF_ID			 : IN STD_LOgic_vector(63 DOWNTO 0);   --IF/ID REGister OUTPUT
        Dec_out       : IN  std_logic_vector(76 downto 0);  --Instruction Register
        ID_EX         : IN  std_logic_vector(395 downto 0);  --ID/EX register output
        EX_MA         : IN  std_logic_vector(362 downto 0);  --EX/MA register output
        MA_WB         : IN  std_logic_vector(339 downto 0);  --MA/WB register output
        LDM_RADD      : IN  std_logic_vector(3 downto 0);     --Address for LDM generated from Decoder
        PC_plus4       : IN  std_logic_vector(31 downto 0);     --PC value out of PC acc
		  REG_A,REG_B, REG_C,WA,WB : OUT STD_logic_vector(3 DOWNTO 0); --OUTPUT GIVEN AS INPUT TO REG_FILE
     	  DA,DB,DC		 :IN STD_logic_vector(31 DOWNTO 0);  --OUTPUT OF REGISTER FILE
		  SHIFTER_OUTPUT : IN STD_logic_vector(31 DOWNTO 0);  --OUTPUT OF SHIFTER BLOCK TAKEN AS INPUT TO ALU_SRCB_MUX
		  CPSR : IN STD_logic_vector(31 DOWNTO 0); -- OUTPUT VALUE OF CPSR REGISTER
		  ALU_OUT : IN STD_LOgic_vector(31 DOWNTO 0); -- OUTPUT FROM ALU UNIT
		  PC_SOURCE : IN  STD_logic_vector(2 DOWNTO 0); --PC SOURCE SEL MUX
		  MemData_readin  : IN std_logic_vector(31 downto 0);  
		  MemData_readout  :OUT std_logic_vector(31 downto 0);  --load data memory output
		  Datamem_addressOut : OUT std_logic_vector(31 downto 0); -- data mem address
		  MemData_Write1 : OUT std_logic_vector(7 downto 0);   -- write data 7:0 to memory
		  MemData_Write2 : OUT std_logic_vector(7 downto 0);   -- write data 15:8 to memory
		  MemData_Write3 : OUT std_logic_vector(7 downto 0);   -- write data 23:16 to memory
		  MemData_Write4 : OUT std_logic_vector(7 downto 0);   -- write data 31:24 to memory
		  W1,W2,W3,W4: OUT std_logic;                        --write mem enable signals
		  SHIFT_DATAIN,SHIFT_AMT : OUT STD_logic_vector(31 DOWNTO 0);
		  CPSR_MUX_OUTPUT,SPSR_MUX_OUTPUT : OUT STD_logic_vector(31 DOWNTO 0);
		  ALU_SRCA_0UTPUT, ALU_SRCB_0UTPUT : OUT STD_logic_vector(31 DOWNTO 0);
		  ACC_0UTPUT : OUT STD_logic_vector(63 DOWNTO 0);  --OUTPUT OF ACC_SEL_MUX
		  FORWARD_CPSR_OUTPUT : OUT STD_logic_vector(31 DOWNTO 0); --FORWARDED CPSR OUTPUT GIVEN CONDITION CODE CHECK UNIT
		  PC_SOURCE_OUTPUT : OUT STD_logic_vector(31 DOWNTO 0); --OUTPUT OF PC_SOURCE MUX
		  DWA,DWB : OUT std_logic_vector(31 downto 0));  ---OUTPUT IE. DIS IS SENT TO DWA OF REG. FILE 
		  
END Muxes;

ARCHITECTURE Muxes_behav OF Muxes IS
SIGNAL DATamem_rEAD_BUFFER : STD_LOgic_vector(31 DOWNTO 0);
signal Datamem_address : std_logic_vector(31 downto 0);
SIGNAL FORWARD_A_MUX_SELECT,FORWARD_B_MUX_SELECT,FORWARD_C_MUX_SELECT : STD_logic_vector(3 DOWNTO 0); --FORWARDING UNIT OUTPUT
SIGNAL FORWARD_CPSR_MUX_SEL : STD_logic_vector(1 DOWNTO 0); --FORWARDING CPSR UNIT OUTPUT
SIGNAL FORWARD_A_OUTPUT : STD_logic_vector(31 DOWNTO 0);  --OUTPUT OF FORWARDING MUX A
SIGNAL FORWARD_B_OUTPUT : STD_logic_vector(31 DOWNTO 0);  --OUTPUT OF FORWARDING MUX B
SIGNAL FORWARD_C_OUTPUT : STD_logic_vector(31 DOWNTO 0);  --OUTPUT OF FORWARDING MUX C
SIGNAL LOAD_STORE_MODE_SEL_OUTPUT : STD_logic_vector(31 DOWNTO 0);  --OUTPUT OF LOAD/STORE MUX
BEGin

  mode:PROCESS(IF_ID,Dec_out,ID_EX,EX_MA,MA_WB,LDM_RADD,PC_plus4,DA,DB,DC,SHIFTER_OUTPUT,CPSR,PC_SOURCE,MemData_readin)
  begin
	 ------------------------------------------------------------------------------------------
	 --FETCH STAGE
	 CASE PC_SOURCE IS
	 WHEN "000"=> --PC+4 
	 PC_SOURCE_OUTPUT <= IF_ID(63 DOWNTO 32);   
	 WHEN "001"=> --0X00000008--SWI
	 PC_SOURCE_OUTPUT<="00000000000000000000000000001000";
	 WHEN "010"=> --ALU_OUT(5)  --B,BL
	 PC_SOURCE_OUTPUT <= MA_WB(31 DOWNTO 0);
	 WHEN "100"=> --BX,BLX SRC--BX,BLX RM INSTRUCTION RM ADDRESSED BY RB
	 IF(ID_EX(43)='1')THEN  --RM(0) ---DB:FROM RM-ID_EX(74:43)
		PC_SOURCE_OUTPUT <= ID_EX(74 DOWNTO 44) & '0';
	 ELSE
		PC_SOURCE_OUTPUT <= ID_EX(74 DOWNTO 45) & "00";
	 END IF;
	 WHEN "101"=> --BLX LABEL SRC
		PC_SOURCE_OUTPUT <= ALU_OUT(31 DOWNTO 2) &ID_EX(198) & '0';
	 WHEN OTHERS=>
	 NULL;
	 END CASE;
	 ------------------------------------------------------------------------------
	 ----------------------------------------------------------------------------------
	 --CPSR_FORWARDING_UNIT:DECODER STAGE
	 
	 --FORWARD_CPSR_MUX_SEL
	 IF(ID_EX(377)='1')THEN     --CPSR_WRITE(3)
		FORWARD_CPSR_MUX_SEL <= "11";
	 ELSIF(EX_MA(349)='1')THEN   --CPSR_WRITE(4)
		FORWARD_CPSR_MUX_SEL <= "01";
	 ELSIF(MA_WB(310)='1')THEN   --CPSR_WRITE(5)
		FORWARD_CPSR_MUX_SEL <= "10";
	 ELSE     --ORIGINAL
		FORWARD_CPSR_MUX_SEL <= "00";
	 END IF;
	 
	 --FOR FINDING CPSR FORWARDED OUTPUT
	 CASE FORWARD_CPSR_MUX_SEL IS
	 WHEN "00"=>  --ORIGINAL
	 FORWARD_CPSR_OUTPUT <= CPSR;
	 WHEN "01"=>  --CPSR_OUT(4)
	 FORWARD_CPSR_OUTPUT <= EX_MA(310 DOWNTO 279);
	 WHEN "10"=>  --CPSR_OUT(5)
	 FORWARD_CPSR_OUTPUT <= MA_WB(271 DOWNTO 240);
	 WHEN "11"=>  --CPSR_OUT(3)
	 FORWARD_CPSR_OUTPUT <= ID_EX(277 DOWNTO 246);
	 WHEN OTHERS=>
	 NULL;
	 END CASE;
	 ------------------------------------------------------------------------------------
	 --DECODER STAGE MUXes
	 
	 CASE Dec_out(4) is   --RA_SEL_MUX
	 when '0'=>
	 REG_A <= IF_ID(15 DOWNTO 12); 
	 when '1'=>
	 REG_A <= IF_ID(19 DOWNTO 16);
	 WHEN OTHERS=>
	 NULL;
	 END CASE;
	 
	 CASE Dec_out(27 DOWNTO 26) is   --RB_SEL_MUX
	 when "00"=>
	 REG_B <= IF_ID(15 DOWNTO 12); 
	 when "01"=>
	 REG_B <= IF_ID(3 DOWNTO 0);
	 when "10"=>
	 REG_B <= IF_ID(19 DOWNTO 16); 
	 when "11"=>
	 REG_B <= Dec_out(76 DOWNTO 73); 
	 WHEN OTHERS=>
	 NULL;
	 END CASE;
	 
	 CASE Dec_out(28) is   --RC_SEL_MUX
	 when '0'=>
	 REG_C <= IF_ID(11 DOWNTO 8); 
	 when '1'=>
	 REG_C <= IF_ID(3 DOWNTO 0);
	 WHEN OTHERS=>
	 NULL;
	 END CASE;
	 
	 CASE Dec_out(7 DOWNTO 6) is   --WA_SEL_MUX
	 when "00"=>
	 WA <= IF_ID(19 DOWNTO 16); 
	 when "01"=>
	 WA <= IF_ID(15 DOWNTO 12);
	 when "10"=>
	 WA <= "1110"; 
	 WHEN OTHERS=>
	 NULL;
	 END CASE;
	 
	 CASE Dec_out(37) is   --WB_SEL_MUX
	 when '0'=>
	 WB <= IF_ID(19 DOWNTO 16); 
	 when '1'=>
	 WB <= Dec_out(76 downto 73);     --Address generated in decoder stage for LDM  
	 WHEN OTHERS=>
	 NULL;
	 END CASE;
	 
	 CASE Dec_out(21 DOWNTO 20) is   --SHIFT_DATAIN_SEL_MUX
	 when "00"=>   --DB
	 SHIFT_DATAIN <= DB; 
	 when "01"=>   --7:0(ZEXT)
	 SHIFT_DATAIN <= "000000000000000000000000" & IF_ID(7 DOWNTO 0);
	 when "10"=>   --23:0(SEXT)
	 SHIFT_DATAIN <= "00000000" & IF_ID(23 DOWNTO 0);
	 when "11"=>   --DC
	 SHIFT_DATAIN <= DC;
	 WHEN OTHERS=>
	 NULL;
	 END CASE;
	 
	 CASE Dec_out(23 DOWNTO 22) is   --SHIFT_AMT_SEL_MUX
	 when "00"=>   --11:8
	 SHIFT_AMT <= "000000000000000000000000000" & IF_ID(11 DOWNTO 8) &'0'; 
	 when "01"=>   --11:7
	 SHIFT_AMT <= "000000000000000000000000000" & IF_ID(11 DOWNTO 7);
	 when "10"=>   --DC
	 SHIFT_AMT <= DC;
	 when "11"=>   --2
	 SHIFT_AMT <= "00000000000000000000000000000010";
	 WHEN OTHERS=>
	 NULL;
	 END CASE;
---------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
--WRITEBACK STAGE MUXES
	 
	 CASE MA_WB(332 DOWNTO 330) is   --DWA_SEL_MUX
	 when "000"=>   --ALU_OUT,DATamem_address
	 DWA <= MA_WB(31 DOWNTO 0); 
	 when "001"=>   --DATA READ
	 DWA <= MA_WB(143 DOWNTO 112);
	 when "010"=>   --C OR S
	 IF(MA_WB(312)='0') THEN--COPY CPSR TO GPR
	 DWA <= MA_WB(271 DOWNTO 240);   --CPSR_OUT
	 ELSE
	 DWA <= MA_WB(303 DOWNTO 272);   --SPSR_OUT
	 END IF;
	 when "011"=>   --MUL_L
	 DWA <= MA_WB(207 DOWNTO 176);
	 when "100"=>  --PC+4
	 DWA <= MA_WB(111 DOWNTO 80);
	 WHEN OTHERS=>
	 NULL;
	 END CASE;
	 
	 CASE MA_WB(334 DOWNTO 333) is   --DWB_SEL_MUX
	 when "00"=>   --MUL_M
	 DWB <= MA_WB(239 DOWNTO 208); 
	 when "01"=>   --DATA READ
	 DWB <= MA_WB(143 DOWNTO 112);
	 when "10"=>   --ALU_OUT
	 DWB <= MA_WB(31 DOWNTO 0);
	 WHEN OTHERS=>
	 NULL;
	 END CASE;
	 
	 
	 CASE MA_WB(337 DOWNTO 335) is   --CPSR_SEL_MUX  
	 --MA_WB: CPSR_OUT:271:240 SPSR_OUT:303:272
	 --DB:63:32
	 when "000"=>   --ALUS
	 CPSR_MUX_OUTPUT<= MA_WB(271 DOWNTO 244) & MA_WB(75 DOWNTO 72); 
	 when "001"=>   --MULS
	 CPSR_MUX_OUTPUT<= MA_WB(271 DOWNTO 244) & MA_WB(307 DOWNTO 304); 
	 when "010"=>   --CPSR_LOAD
	 IF(MA_WB(339)='0')THEN   --LOAD PSR SELECT _DEC_OUT(42)
		IF(MA_WB(68)='1')THEN    --UPDATE FROM FIELD
			CPSR_MUX_OUTPUT(7 DOWNTO 0) <= MA_WB(39 DOWNTO 32);
		ELSE
			CPSR_MUX_OUTPUT(7 DOWNTO 0) <= MA_WB(247 DOWNTO 240);
		END IF;
		IF(MA_WB(69)='1')THEN    --UPDATE FROM FIELD
			CPSR_MUX_OUTPUT(15 DOWNTO 8) <= MA_WB(47 DOWNTO 40);
		ELSE
			CPSR_MUX_OUTPUT(15 DOWNTO 8) <= MA_WB(255 DOWNTO 248);
		END IF;
		IF(MA_WB(70)='1')THEN    --UPDATE FROM FIELD
			CPSR_MUX_OUTPUT(23 DOWNTO 16) <= MA_WB(55 DOWNTO 48);
		ELSE
			CPSR_MUX_OUTPUT(23 DOWNTO 16) <= MA_WB(263 DOWNTO 256);
		END IF;
		IF(MA_WB(71)='1')THEN    --UPDATE FROM FIELD
			CPSR_MUX_OUTPUT(31 DOWNTO 24) <= MA_WB(63 DOWNTO 56);
		ELSE
			CPSR_MUX_OUTPUT(31 DOWNTO 24) <= MA_WB(271 DOWNTO 264);
		END IF;
	 ELSE    --SHIFTER_OUTPUT --MA_WB :175:144
	  IF(MA_WB(68)='1')THEN    --UPDATE FROM FIELD 
			CPSR_MUX_OUTPUT(7 DOWNTO 0) <= MA_WB(151 DOWNTO 144);
		ELSE
			CPSR_MUX_OUTPUT(7 DOWNTO 0) <= MA_WB(247 DOWNTO 240);
		END IF;
		
		IF(MA_WB(69)='1')THEN    --UPDATE FROM FIELD
			CPSR_MUX_OUTPUT(15 DOWNTO 8) <= MA_WB(159 DOWNTO 152);
		ELSE
			CPSR_MUX_OUTPUT(15 DOWNTO 8) <= MA_WB(255 DOWNTO 248);
		END IF;
		
		IF(MA_WB(70)='1')THEN    --UPDATE FROM FIELD
			CPSR_MUX_OUTPUT(23 DOWNTO 16) <= MA_WB(167 DOWNTO 160);
		ELSE
			CPSR_MUX_OUTPUT(23 DOWNTO 16) <= MA_WB(263 DOWNTO 256);
		END IF;
		
		IF(MA_WB(71)='1')THEN    --UPDATE FROM FIELD
			CPSR_MUX_OUTPUT(31 DOWNTO 24) <= MA_WB(175 DOWNTO 168);
		ELSE
			CPSR_MUX_OUTPUT(31 DOWNTO 24) <= MA_WB(271 DOWNTO 264);
		END IF; 
	 END IF;
	 
	 when "011"=>   --MASKOUT  --BLX,BX RM
	 CPSR_MUX_OUTPUT <= MA_WB(271 DOWNTO 246) & MA_WB(32)& MA_WB(244 DOWNTO 240); 
	 when "100"=>  --CPSR_SWI
	 CPSR_MUX_OUTPUT <= MA_WB(271 DOWNTO 248) & '1' & MA_WB(246 DOWNTO 245) & "10011";
	 when "101"=>  --SPSR
	 CPSR_MUX_OUTPUT <= MA_WB(303 DOWNTO 272);
	 WHEN OTHERS=>
	 NULL;
	 END CASE;
	 
	 CASE MA_WB(338) is   --SPSR_SEL_MUX SPSR_OUT: MA_WB:303:272
	 when '0'=>  --SPSR_LOAD
	 IF(MA_WB(339)='0')THEN   --LOAD PSR SELECT _DEC_OUT(42)
		IF(MA_WB(68)='1')THEN    --UPDATE FROM FIELD
			SPSR_MUX_OUTPUT(7 DOWNTO 0) <= MA_WB(39 DOWNTO 32);
		ELSE
			SPSR_MUX_OUTPUT(7 DOWNTO 0) <= MA_WB(279 DOWNTO 272);
		END IF;
		IF(MA_WB(69)='1')THEN    --UPDATE FROM FIELD
			SPSR_MUX_OUTPUT(15 DOWNTO 8) <= MA_WB(47 DOWNTO 40);
		ELSE
			SPSR_MUX_OUTPUT(15 DOWNTO 8) <= MA_WB(287 DOWNTO 280);
		END IF;
		IF(MA_WB(70)='1')THEN    --UPDATE FROM FIELD
			SPSR_MUX_OUTPUT(23 DOWNTO 16) <= MA_WB(55 DOWNTO 48);
		ELSE
			SPSR_MUX_OUTPUT(23 DOWNTO 16) <= MA_WB(295 DOWNTO 288);
		END IF;
		IF(MA_WB(71)='1')THEN    --UPDATE FROM FIELD
			SPSR_MUX_OUTPUT(31 DOWNTO 24) <= MA_WB(63 DOWNTO 56);
		ELSE
			SPSR_MUX_OUTPUT(31 DOWNTO 24) <= MA_WB(303 DOWNTO 296);
		END IF;
	 ELSE    --SHIFTER_OUTPUT --MA_WB :175:144
	  IF(MA_WB(68)='1')THEN    --UPDATE FROM FIELD 
			SPSR_MUX_OUTPUT(7 DOWNTO 0) <= MA_WB(151 DOWNTO 144);
		ELSE
			SPSR_MUX_OUTPUT(7 DOWNTO 0) <= MA_WB(279 DOWNTO 272);
		END IF;
		
		IF(MA_WB(69)='1')THEN    --UPDATE FROM FIELD
			SPSR_MUX_OUTPUT(15 DOWNTO 8) <= MA_WB(159 DOWNTO 152);
		ELSE
			SPSR_MUX_OUTPUT(15 DOWNTO 8) <=  MA_WB(287 DOWNTO 280);
		END IF;
		
		IF(MA_WB(70)='1')THEN    --UPDATE FROM FIELD
			SPSR_MUX_OUTPUT(23 DOWNTO 16) <= MA_WB(167 DOWNTO 160);
		ELSE
			SPSR_MUX_OUTPUT(23 DOWNTO 16) <= MA_WB(295 DOWNTO 288);
		END IF;
		
		IF(MA_WB(71)='1')THEN    --UPDATE FROM FIELD
			SPSR_MUX_OUTPUT(31 DOWNTO 24) <= MA_WB(175 DOWNTO 168);
		ELSE
			SPSR_MUX_OUTPUT(31 DOWNTO 24) <= MA_WB(303 DOWNTO 296);
		END IF; 
	 END IF;
	 when '1'=>  --CPSR(SWI)
	 SPSR_MUX_OUTPUT <= MA_WB(271 DOWNTO 240);
	 WHEN OTHERS=>
	 NULL;
	 END CASE;
	 ---------------------------------------------------------------------------------------
	 ----------------------------------------------------------------------------------------
	 --EXECUTION STAGE MUXES
	 ---------------------------------------------------------------------------------------------
	 --FORWARDING UNIT MUXES
	 
	 --FOR FINDING VALUE OF FORWARD_A_MUX_SELECT
	IF((ID_EX(174 DOWNTO 171) = EX_MA(139 DOWNTO 136)) AND (EX_MA(347)='1'))THEN   --RA(3)==WA(4) & REGA WRITE(4) = '1'
		CASE EX_MA(356 DOWNTO 354) IS    --DWA_SEL(4)
		WHEN "000"=>
		FORWARD_A_MUX_SELECT<="0001";   --ALU(4)
		WHEN "010"=>
		FORWARD_A_MUX_SELECT<="0101";   --CORS(4) --EITHER CPSR_OUT(4) OR SPSR_OUT(4) WLL BE SENT AS I/P 
		--TO FORWARDING UNIT DEPENDING ON B[22](C OR S SELECT)
		WHEN "011"=>
		FORWARD_A_MUX_SELECT<="0010";   --MUL_L(4)
		WHEN "100"=>
		FORWARD_A_MUX_SELECT<="0100";   --PC+4(4)
		WHEN OTHERS=>
		NULL;
		END CASE;
	ELSIF((ID_EX(174 DOWNTO 171) = EX_MA(139 DOWNTO 136)) AND (EX_MA(348)='1'))THEN  --RA(3)=WB(4) & REGB WRIE(4) ='1'
		CASE EX_MA(358 DOWNTO 357) IS    --DWB_SEL(4)
		WHEN "00"=>
		FORWARD_A_MUX_SELECT<="0011";   --MUL_M(4)
		WHEN "10"=>
		FORWARD_A_MUX_SELECT<="0001";   --ALU(4) 
		WHEN OTHERS=>
		NULL;
		END CASE;
	ELSIF((ID_EX(174 DOWNTO 171) = MA_WB(328 DOWNTO 325))AND (MA_WB(308)='1'))THEN  --RA(3)=WA(5) & REGA WRITE(5) = '1'
		CASE MA_WB(332 DOWNTO 330) IS    --DWA_SEL(5)
		WHEN "000"=>
		FORWARD_A_MUX_SELECT<="0110";   --ALU(5)
		WHEN "010"=>
		FORWARD_A_MUX_SELECT<="1001";   --CORS(5) --EITHER CPSR_OUT(4) OR SPSR_OUT(4) WLL BE SENT AS I/P 
		--TO FORWARDING UNIT DEPENDING ON B[22](C OR S SELECT)
		WHEN "011"=>
		FORWARD_A_MUX_SELECT<="0111";   --MUL_L(5)
		WHEN "100"=>
		FORWARD_A_MUX_SELECT<="1010";   --PC+4(5)
		WHEN "001"=>
		FORWARD_A_MUX_SELECT<="1011";   --DATA_READ(5)
		WHEN OTHERS=>
		NULL;
		END CASE;
	ELSIF((ID_EX(174 DOWNTO 171) = MA_WB(332 DOWNTO 329))AND (MA_WB(309)='1'))THEN  --RA(3)=WB(5)  & REGB WRITE(5) = '1'
		CASE EX_MA(334 DOWNTO 333) IS    --DWB_SEL(5)
		WHEN "00"=>
		FORWARD_A_MUX_SELECT<="1000";   --MUL_M(5)
		WHEN "10"=>
		FORWARD_A_MUX_SELECT<="0110";   --ALU(5) 
		WHEN OTHERS=>
		NULL;
		END CASE;	
	 ELSE
	 FORWARD_A_MUX_SELECT<="0000";
	 END IF;
 
 
  --FOR FINDING VALUE OF FORWARD_B_MUX_SELECT

	IF((ID_EX(178 DOWNTO 175) = EX_MA(139 DOWNTO 136)) AND (EX_MA(347)='1'))THEN   --RB(3)==WA(4) & REGA WRITE(4) = '1'
		CASE EX_MA(356 DOWNTO 354) IS    --DWA_SEL(4)
		WHEN "000"=>
		FORWARD_B_MUX_SELECT<="0001";   --ALU(4)
		WHEN "010"=>
		FORWARD_B_MUX_SELECT<="0101";   --CORS(4) --EITHER CPSR_OUT(4) OR SPSR_OUT(4) WLL BE SENT AS I/P 
		--TO FORWARDING UNIT DEPENDING ON B[22](C OR S SELECT)
		WHEN "011"=>
		FORWARD_B_MUX_SELECT<="0010";   --MUL_L(4)
		WHEN "100"=>
		FORWARD_B_MUX_SELECT<="0100";   --PC+4(4)
		WHEN OTHERS=>
		NULL;
		END CASE;
	ELSIF((ID_EX(178 DOWNTO 175) = EX_MA(139 DOWNTO 136)) AND (EX_MA(348)='1'))THEN  --RB(3)=WB(4) & REGB WRIE(4) ='1'
		CASE EX_MA(358 DOWNTO 357) IS    --DWB_SEL(4)
		WHEN "00"=>
		FORWARD_B_MUX_SELECT<="0011";   --MUL_M(4)
		WHEN "10"=>
		FORWARD_B_MUX_SELECT<="0001";   --ALU(4) 
		WHEN OTHERS=>
		NULL;
		END CASE;
	ELSIF((ID_EX(178 DOWNTO 175) = MA_WB(328 DOWNTO 325))AND (MA_WB(308)='1'))THEN  --RB(3)=WA(5) & REGA WRITE(5) = '1'
		CASE MA_WB(332 DOWNTO 330) IS    --DWA_SEL(5)
		WHEN "000"=>
		FORWARD_B_MUX_SELECT<="0110";   --ALU(5)
		WHEN "010"=>
		FORWARD_B_MUX_SELECT<="1001";   --CORS(5) --EITHER CPSR_OUT(4) OR SPSR_OUT(4) WLL BE SENT AS I/P 
		--TO FORWARDING UNIT DEPENDING ON B[22](C OR S SELECT)
		WHEN "011"=>
		FORWARD_B_MUX_SELECT<="0111";   --MUL_L(5)
		WHEN "100"=>
		FORWARD_B_MUX_SELECT<="1010";   --PC+4(5)
		WHEN "001"=>
		FORWARD_B_MUX_SELECT<="1011";   --DATA_READ(5)
		WHEN OTHERS=>
		NULL;
		END CASE;
	ELSIF((ID_EX(178 DOWNTO 175) = MA_WB(332 DOWNTO 329))AND (MA_WB(309)='1'))THEN  --RB(3)=WB(5)  & REGB WRITE(5) = '1'
		CASE EX_MA(334 DOWNTO 333) IS    --DWB_SEL(5)
		WHEN "00"=>
		FORWARD_B_MUX_SELECT<="1000";   --MUL_M(5)
		WHEN "10"=>
		FORWARD_B_MUX_SELECT<="0110";   --ALU(5) 
		WHEN OTHERS=>
		NULL;
		END CASE;
	ELSE
		FORWARD_B_MUX_SELECT<="0000";   --DEFAULT VALUE
	END IF;
	

 
	 --FOR FINDING VALUE OF FORWARD_C_MUX_SELECT
	IF((ID_EX(182 DOWNTO 179) = EX_MA(139 DOWNTO 136)) AND (EX_MA(347)='1'))THEN   --RC(3)==WA(4) & REGA WRITE(4) = '1'
		CASE EX_MA(356 DOWNTO 354) IS    --DWA_SEL(4)
		WHEN "000"=>
		FORWARD_C_MUX_SELECT<="0001";   --ALU(4)
		WHEN "010"=>
		FORWARD_C_MUX_SELECT<="0101";   --CORS(4) --EITHER CPSR_OUT(4) OR SPSR_OUT(4) WLL BE SENT AS I/P 
		--TO FORWARDING UNIT DEPENDING ON B[22](C OR S SELECT)
		WHEN "011"=>
		FORWARD_C_MUX_SELECT<="0010";   --MUL_L(4)
		WHEN "100"=>
		FORWARD_C_MUX_SELECT<="0100";   --PC+4(4)
		WHEN OTHERS=>
		NULL;
		END CASE;
	ELSIF((ID_EX(182 DOWNTO 179) = EX_MA(139 DOWNTO 136)) AND (EX_MA(348)='1'))THEN  --RC(3)=WB(4) & REGB WRIE(4) ='1'
		CASE EX_MA(358 DOWNTO 357) IS    --DWB_SEL(4)
		WHEN "00"=>
		FORWARD_C_MUX_SELECT<="0011";   --MUL_M(4)
		WHEN "10"=>
		FORWARD_C_MUX_SELECT<="0001";   --ALU(4) 
		WHEN OTHERS=>
		NULL;
		END CASE;
	ELSIF((ID_EX(174 DOWNTO 171) = MA_WB(328 DOWNTO 325))AND (MA_WB(308)='1'))THEN  --RC(3)=WA(5) & REGA WRITE(5) = '1'
		CASE MA_WB(332 DOWNTO 330) IS    --DWA_SEL(5)
		WHEN "000"=>
		FORWARD_C_MUX_SELECT<="0110";   --ALU(5)
		WHEN "010"=>
		FORWARD_C_MUX_SELECT<="1001";   --CORS(5) --EITHER CPSR_OUT(4) OR SPSR_OUT(4) WLL BE SENT AS I/P 
		--TO FORWARDING UNIT DEPENDING ON B[22](C OR S SELECT)
		WHEN "011"=>
		FORWARD_C_MUX_SELECT<="0111";   --MUL_L(5)
		WHEN "100"=>
		FORWARD_C_MUX_SELECT<="1010";   --PC+4(5)
		WHEN "001"=>
		FORWARD_C_MUX_SELECT<="1011";   --DATA_READ(5)
		WHEN OTHERS=>
		NULL;
		END CASE;
		
	ELSIF((ID_EX(174 DOWNTO 171) = MA_WB(332 DOWNTO 329))AND (MA_WB(309)='1'))THEN  --RC(3)=WB(5)  & REGB WRITE(5) = '1'
		CASE EX_MA(334 DOWNTO 333) IS    --DWB_SEL(5)
		WHEN "00"=>
		FORWARD_C_MUX_SELECT<="1000";   --MUL_M(5)
		WHEN "10"=>
		FORWARD_C_MUX_SELECT<="0110";   --ALU(5) 
		WHEN OTHERS=>
		NULL;
		END CASE;
	ELSE
	FORWARD_C_MUX_SELECT<="0000";
	END IF;
 
 ------------------------------------------------------------------------------------------------------
	 
	  --FINDING FORWARD_A_OUTPUT
	 CASE FORWARD_A_MUX_SELECT is   --FORWARD_A_MUX_SELECT
	 when "0000"=>   --DA(3)
	 FORWARD_A_OUTPUT <= ID_EX(42 DOWNTO 11); 
	 when "0001"=>   --ALU(4)
	 FORWARD_A_OUTPUT <= EX_MA(36 DOWNTO 5); 
	 when "0010"=>   --MUL_L(4)
	 FORWARD_A_OUTPUT <= EX_MA(246 DOWNTO 215);
	 when "0011"=>   --MUL_M(4)
	 FORWARD_A_OUTPUT <= EX_MA(278 DOWNTO 247);
	 when "0100"=>   --PC+4(4)
	 FORWARD_A_OUTPUT <= EX_MA(182 DOWNTO 151);
	 when "0101"=>   --C OR S(4)
	 IF(EX_MA(144)='0')THEN --CORS SELECT
		FORWARD_A_OUTPUT <= EX_MA(310 DOWNTO 279);   --CPSR_OUT(4)
	 ELSE
		FORWARD_A_OUTPUT <= EX_MA(342 DOWNTO 311);   --SPSR_OUT(4)
	 END IF;
	 when "0110"=>   --ALU(5)
	 FORWARD_A_OUTPUT <= MA_WB(31 DOWNTO 0);
	 when "0111"=>   --MUL_L(5)
	 FORWARD_A_OUTPUT <= MA_WB(207 DOWNTO 176);
	 when "1000"=>   --MUL_M(5)
	 FORWARD_A_OUTPUT <= ID_EX(239 DOWNTO 208);
	 when "1001"=>   --C OR S(5)
	 IF(MA_WB(312)='0')THEN --CORS SELECT
		FORWARD_A_OUTPUT <= MA_WB(271 DOWNTO 240);   --CPSR_OUT(5)
	 ELSE
		FORWARD_A_OUTPUT <= MA_WB(303 DOWNTO 272);   --SPSR_OUT(5)
	 END IF;
	 when "1010"=>   --PC+4(5)
	 FORWARD_A_OUTPUT <= ID_EX(111 DOWNTO 80);
	 when "1011"=>   --DATAREAD(5)
	 FORWARD_A_OUTPUT <= ID_EX(143 DOWNTO 112); 
	 WHEN OTHERS=>
	 NULL;
	 END CASE;
	 
	   --FINDING FORWARD_B_OUTPUT
	 CASE FORWARD_B_MUX_SELECT is   --FORWARD_B_MUX_SELECT
	 when "0000"=>   --DB(3)
	 FORWARD_B_OUTPUT <= ID_EX(74 DOWNTO 43); 
	 when "0001"=>   --ALU(4)
	 FORWARD_B_OUTPUT <= EX_MA(36 DOWNTO 5); 
	 when "0010"=>   --MUL_L(4)
	 FORWARD_B_OUTPUT <= EX_MA(246 DOWNTO 215);
	 when "0011"=>   --MUL_M(4)
	 FORWARD_B_OUTPUT <= EX_MA(278 DOWNTO 247);
	 when "0100"=>   --PC+4(4)
	 FORWARD_B_OUTPUT <= EX_MA(182 DOWNTO 151);
	 when "0101"=>   --C OR S(4)
	 IF(EX_MA(144)='0')THEN --CORS SELECT
		FORWARD_B_OUTPUT <= EX_MA(310 DOWNTO 279);   --CPSR_OUT(4)
	 ELSE
		FORWARD_B_OUTPUT <= EX_MA(342 DOWNTO 311);   --SPSR_OUT(4)
	 END IF;
	 when "0110"=>   --ALU(5)
	 FORWARD_B_OUTPUT <= MA_WB(31 DOWNTO 0);
	 when "0111"=>   --MUL_L(5)
	 FORWARD_B_OUTPUT <= MA_WB(207 DOWNTO 176);
	 when "1000"=>   --MUL_M(5)
	 FORWARD_B_OUTPUT <= ID_EX(239 DOWNTO 208);
	 when "1001"=>   --C OR S(5)
	 IF(MA_WB(312)='0')THEN --CORS SELECT
		FORWARD_B_OUTPUT <= MA_WB(271 DOWNTO 240);   --CPSR_OUT(5)
	 ELSE
		FORWARD_B_OUTPUT <= MA_WB(303 DOWNTO 272);   --SPSR_OUT(5)
	 END IF;
	 when "1010"=>   --PC+4(5)
	 FORWARD_B_OUTPUT <= ID_EX(111 DOWNTO 80);
	 when "1011"=>   --DATAREAD(5)
	 FORWARD_B_OUTPUT <= ID_EX(143 DOWNTO 112); 
	 WHEN OTHERS=>
	 NULL;
	 END CASE;
	 
	   --FINDING FORWARD_C_OUTPUT
	 CASE FORWARD_C_MUX_SELECT is   --FORWARD_C_MUX_SELECT
	 when "0000"=>   --DC(3)
	 FORWARD_C_OUTPUT <= ID_EX(114 DOWNTO 83); 
	 when "0001"=>   --ALU(4)
	 FORWARD_C_OUTPUT <= EX_MA(36 DOWNTO 5); 
	 when "0010"=>   --MUL_L(4)
	 FORWARD_C_OUTPUT <= EX_MA(246 DOWNTO 215);
	 when "0011"=>   --MUL_M(4)
	 FORWARD_C_OUTPUT <= EX_MA(278 DOWNTO 247);
	 when "0100"=>   --PC+4(4)
	 FORWARD_C_OUTPUT <= EX_MA(182 DOWNTO 151);
	 when "0101"=>   --C OR S(4)
	 IF(EX_MA(144)='0')THEN --CORS SELECT
		FORWARD_C_OUTPUT <= EX_MA(310 DOWNTO 279);   --CPSR_OUT(4)
	 ELSE
		FORWARD_C_OUTPUT <= EX_MA(342 DOWNTO 311);   --SPSR_OUT(4)
	 END IF;
	 when "0110"=>   --ALU(5)
	 FORWARD_C_OUTPUT <= MA_WB(31 DOWNTO 0);
	 when "0111"=>   --MUL_L(5)
	 FORWARD_C_OUTPUT <= MA_WB(207 DOWNTO 176);
	 when "1000"=>   --MUL_M(5)
	 FORWARD_C_OUTPUT <= ID_EX(239 DOWNTO 208);
	 when "1001"=>   --C OR S(5)
	 IF(MA_WB(312)='0')THEN --CORS SELECT
		FORWARD_C_OUTPUT <= MA_WB(271 DOWNTO 240);   --CPSR_OUT(5)
	 ELSE
		FORWARD_C_OUTPUT <= MA_WB(303 DOWNTO 272);   --SPSR_OUT(5)
	 END IF;
	 when "1010"=>   --PC+4(5)
	 FORWARD_C_OUTPUT <= ID_EX(111 DOWNTO 80);
	 when "1011"=>   --DATAREAD(5)
	 FORWARD_C_OUTPUT <= ID_EX(143 DOWNTO 112); 
	 WHEN OTHERS=>
	 NULL;
	 END CASE;
	 
	 
	 -----------------------------------------------------------------------------------------------
	 --EXECUTION STAGE OTHER MUXES
	 
	 CASE ID_EX(197) is   --ALU_SRCA_SEL_MUX
	 when '0'=>  --PC+8
	 ALU_SRCA_0UTPUT <= PC_plus4; 
	 when '1'=>  --DA (FORWARED DA VALUE)
	 ALU_SRCA_0UTPUT <= FORWARD_A_OUTPUT;
	 WHEN OTHERS=> 
	 NULL;
	 END CASE;
	 
	 CASE ID_EX(204 DOWNTO 203) is   --LOAD_STORE_MODE_SEL_MUX
	 when "00"=>  --11:8-3:0 ZEXT
	 LOAD_STORE_MODE_SEL_OUTPUT <= "000000000000000000000000" & ID_EX(170 DOWNTO 163);
	 when "01"=>  --DB
	 LOAD_STORE_MODE_SEL_OUTPUT <= FORWARD_B_OUTPUT;
	 when "10"=>  --11:0 ZEXT
	 LOAD_STORE_MODE_SEL_OUTPUT <= "00000000000000000000" & ID_EX(162 DOWNTO 151);
	 when "11"=>  --SHIFTER_OUTPUT
	 LOAD_STORE_MODE_SEL_OUTPUT <= SHIFTER_OUTPUT;
	 WHEN OTHERS=> 
	 NULL;
	 END CASE;
	 
	 CASE ID_EX(202 DOWNTO 201) is   --ALU_SRCB_SEL_MUX
	 when "00"=>  --SHIFTER_OUTPUT
	 ALU_SRCB_0UTPUT <= SHIFTER_OUTPUT;
	 when "01"=>  --LOAD/STORE_MODE_SEL_OUTPUT
	 ALU_SRCB_0UTPUT <= LOAD_STORE_MODE_SEL_OUTPUT;
	 when "10"=>  --LDM/SDM
	 if(ID_EX(213)='0') then
	   ALU_SRCB_0UTPUT <= x"00000000";        --LDM state
	 else
	   ALU_SRCB_0UTPUT <= x"11111111";        --LDM state
   end if;	   
	 when "11"=>  --DC
	 ALU_SRCB_0UTPUT <= FORWARD_C_OUTPUT;
	 WHEN OTHERS=> 
	 NULL;
	 END CASE;
	 
	  
	 CASE ID_EX(200 DOWNTO 199) is   --ACC_SEL_MUX
	 when "00"=>  --0
	 ACC_0UTPUT <= "00000000000000000000000000000000"&"00000000000000000000000000000000";
	 when "01"=>  --DA_ZEXT
	 ACC_0UTPUT <= "00000000000000000000000000000000"&FORWARD_A_OUTPUT;
	 when "10"=>  --RDHI:RDLO (DA:DB)
	 ACC_0UTPUT <= FORWARD_A_OUTPUT & FORWARD_B_OUTPUT;
	 WHEN OTHERS=> 
	 NULL;
	 END CASE;
	 
	 
	---------------------------------------------------------------------------------------------------
	---------------------------------------------------------------------------------------------------	
	 --MEM STAGE MUXES
	 IF(EX_MA(75) = '1')THEN  	--DMA_SELECT_MUX
		 Datamem_address <=EX_MA(36 downto 5);    --alu_op
	 else
		 Datamem_address(31 downto 0) <=EX_MA(73 downto 42);    --DA
	 end if;
	 Datamem_addressOut<= datamem_address;
	 -----------------------------------------------------------------------------------------------
	 --LOAD_STORE_MODULE
	 
	 if(EX_MA(2)= '1')THEN           --LOAD 
		 --Load Word access
		 if((EX_MA(41 DOWNTO 38)="0010")and (EX_MA(4)='1')and(EX_MA(3)='0'))THEN            --WUBYTE
				case Datamem_address(1 downto 0) is
				when "01" =>
				  MemData_readout(31 downto 0)<= MemData_readin(7 downto 0) & MemData_readin(31 downto 8);
				when "10" =>
				  MemData_readout(31 downto 0)<= MemData_readin(15 downto 0) & MemData_readin(31 downto 16);
				when "11" =>
				  MemData_readout(31 downto 0)<= MemData_readin(23 downto 0) & MemData_readin(31 downto 24);
				when others =>
				  MemData_readout <= MemData_readin;
				end case;
		 ELSIF((EX_MA(41 DOWNTO 38)="1000") OR (EX_MA(41 DOWNTO 38)="0001" ))THEN  --SWAP OR LOAD/STORE MULTIPLE
			MemData_readout <= MemData_readin;
		 END IF;
		 
		 --LOAD HALFBYTE
		 IF((EX_MA(41 DOWNTO 38)="0100") and (EX_MA(4)='0')and(EX_MA(0)='1'))THEN   --HWSBYTE		
				IF(Datamem_address(1)='0')THEN   -- addr 00, 01
					MemData_readout(15 downto 0)<=MemData_readin(15 downto 0);
					DATamem_rEAD_BUFFER(15 downto 0)<=MemData_readin(15 downto 0);
				else                   --addr 10,11
					MemData_readout(15 downto 0)<=MemData_readin(31 downto 16);
					DATamem_rEAD_BUFFER(15 downto 0)<=MemData_readin(31 downto 16);
				end if;
				IF(EX_MA(1)='1')then
					if(DATamem_rEAD_BUFFER(15)='1')then
						MemData_readout(31 downto 16) <= "1111111111111111";
					else
						MemData_readout(31 downto 16) <= "0000000000000000";
					end if;
				else
					MemData_readout(31 downto 16) <= "0000000000000000";
				end if;
		 END IF;
		 
		 --LOAD BYTE
		 IF((EX_MA(41 DOWNTO 38)="0010") and (EX_MA(4)='1')and(EX_MA(3)='1'))THEN  --WUSbyte
				case Datamem_address(1 downto 0) is
				when "01" =>
				  MemData_readout(31 downto 0)<= "000000000000000000000000" & MemData_readin(15 downto 8);
				when "10" =>
				  MemData_readout(31 downto 0)<= "000000000000000000000000" & MemData_readin(23 downto 16);
				when "11" =>
				  MemData_readout(31 downto 0)<= "000000000000000000000000" & MemData_readin(31 downto 24);
				when others =>
				  MemData_readout <= "000000000000000000000000" & MemData_readin(7 downto 0);
				end case;	
		 ELSIF((EX_MA(41 DOWNTO 38)="0100") and (EX_MA(4)='0')and(EX_MA(0)='0'))THEN --HWSBYTE	
				case Datamem_address(1 downto 0) is
					when "01" =>
					  MemData_readout(7 downto 0)<= MemData_readin(15 downto 8);
					  DATamem_rEAD_BUFFER(7 downto 0)<= MemData_readin(15 downto 8);
					when "10" =>
					  MemData_readout(7 downto 0)<= MemData_readin(23 downto 16);
					  DATamem_rEAD_BUFFER(7 downto 0)<= MemData_readin(23 downto 16);
					when "11" =>
					  MemData_readout(7 downto 0)<= MemData_readin(31 downto 24);
					  DATamem_rEAD_BUFFER(7 downto 0)<= MemData_readin(31 downto 24);
					when others =>
					  MemData_readout(7 downto 0) <= MemData_readin(7 downto 0);
					  DATamem_rEAD_BUFFER(7 downto 0)<= MemData_readin(7 downto 0);
				end case;
				if(DATamem_rEAD_BUFFER(7)='1') then
					MemData_readout(31 downto 8) <= "111111111111111111111111";
				else
					MemData_readout(31 downto 8) <= "000000000000000000000000";
				end if;
		 END IF;
		 
	 ELSE
		if(EX_MA(74)='1')then
			 --Store Word access
			 if(((EX_MA(41 DOWNTO 38)="0010") and (EX_MA(4)='1') and (EX_MA(2)= '0')) or (EX_MA(41 DOWNTO 38)="1000") OR (EX_MA(41 DOWNTO 38)="0001"))THEN     
			 --WUBYTE or SWAP OR LOAD/STORE MULTIPLE
				MemData_Write1 <= EX_MA(83 downto 76);      --DB (7:0)
				MemData_Write2 <= EX_MA(91 downto 84);      --DB (15:8)
				MemData_Write3 <= EX_MA(99 downto 92);      --DB (23:16)
				MemData_Write4 <= EX_MA(107 downto 100);    --DB (32:24)
				W1<= '1' ; --address 00
				W2<= '1' ; --address 01
				W3<= '1' ; --address 10
				W4<= '1' ; --address 11
			 END IF;
			 
			 --Store HALFBYTE
			 IF((EX_MA(41 DOWNTO 38)="0100") and (EX_MA(4)='0')and(EX_MA(0)='1'))THEN   --HWSBYTE
				IF(Datamem_address(1)='0')THEN   -- addr 00, 01
					MemData_Write1 <= EX_MA(83 downto 76);      --DB (7:0)
					MemData_Write2 <= EX_MA(91 downto 84);      --DB (15:8)
					W1<= '1' ; --address 00
					W2<= '1' ; --address 01
					W3<= '0' ; --address 10
					W4<= '0' ; --address 11	
				else                   --addr 10,11
					MemData_Write3 <=  EX_MA(83 downto 76);      --DB (7:0)
					MemData_Write4 <=  EX_MA(91 downto 84);      --DB (15:8)
					W1<= '0' ; --address 00
					W2<= '0' ; --address 01
					W3<= '1' ; --address 10
					W4<= '1' ; --address 11
				end if;					
			 END IF;
			 
			 --STORE BYTE
			 IF((EX_MA(41 DOWNTO 38)="0010")and (EX_MA(4)='1')and(EX_MA(3)='1'))THEN  --WUSbyte	
				case Datamem_address(1 downto 0) is
				when "01" =>
					MemData_Write2 <= EX_MA(83 downto 76);      --DB (7:0)
					W1<= '0' ; --address 00
					W2<= '1' ; --address 01
					W3<= '0' ; --address 10
					W4<= '0' ; --address 11
				when "10" =>
					MemData_Write3 <= EX_MA(83 downto 76);      --DB (7:0)
					W1<= '0' ; --address 00
					W2<= '0' ; --address 01
					W3<= '1' ; --address 10
					W4<= '0' ; --address 11
				when "11" =>
					MemData_Write4 <= EX_MA(83 downto 76);      --DB (7:0)
					W1<= '0' ; --address 00
					W2<= '0' ; --address 01
					W3<= '0' ; --address 10
					W4<= '1' ; --address 11
				when others =>
					MemData_Write1 <= EX_MA(83 downto 76);      --DB (7:0)
					W1<= '1' ; --address 00
					W2<= '0' ; --address 01
					W3<= '0' ; --address 10
					W4<= '0' ; --address 11
				end case;	
			 END IF;
			 
		else   --not write enable
		NULL;
		end if;
	 
	 END IF;
	 
	 
end process;
end Muxes_behav;
	 
	 
      
        
    