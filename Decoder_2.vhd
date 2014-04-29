LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;

ENTITY Decoder IS
  
  PORT( IF_ID   : IN  std_logic_vector(63 downto 0);  --IF_ID REGISTER
        IC_hit  : IN  std_logic;                      --IC hit
        DC_hit  : IN  std_logic;                      --DC hit
        clk     : IN  std_logic;                      
        reset   : IN  std_logic;                      
	      CC	     : IN  std_logic_vector(3 downto 0);	      --Condition codes from CPSR or forwarding
	      stall   : IN  std_logic;                       --from hazard detection unit
	      Dec_out : OUT std_logic_vector(76 downto 0));  --Decoder output

END Decoder;

ARCHITECTURE Decoder_behav OF Decoder IS
  type state_type is (basic,Mul_2,Swp_2,Swi_2,Br_2,Lm_2);  --States.
  signal current_s,next_s: state_type;  --current and next state declaration.
  signal count,count_reg,count_mem,count_mem_reg: std_logic_vector(3 downto 0);
  signal Prior_enc_reg,Prior_enc: std_logic_vector(15 downto 0);
  signal Mul_st2,Swp_st2,Swi_st2,Br_st2,LS_cnt_en,Lm_st2,Prior_en: std_logic:='0';
  --Dec_out(68 downto 65)=Swap_inst,hwsbyte_inst,wusbyte_inst,ls_mul
  
  begin
    Dec_out(72 downto 69) <= count;
    Instruction: PROCESS(IF_ID,IC_hit,DC_hit,current_s,count,stall,Prior_enc_reg)
    variable VA_out: std_logic;
    begin

      case IF_ID(31 downto 28) is
      when "0000" =>
        VA_out:=CC(2);
      when "0001" =>
        VA_out:=NOT CC(2);
      when "0010" =>
        VA_out:=CC(0);
      when "0011" =>
        VA_out:=NOT CC(0);
      when "0100" =>
        VA_out:=CC(3);
      when "0101" =>
        VA_out:=NOT CC(3);
      when "0110" =>
        VA_out:=CC(1);
      when "0111" =>
        VA_out:=NOT CC(1);
      when "1000" =>
        VA_out:=CC(0)AND(NOT CC(2));
      when "1001" =>
        VA_out:=(NOT CC(0))OR CC(2);
      when "1010" =>
        VA_out:=CC(3)XNOR CC(1);
      when "1011" =>
        VA_out:=CC(3)XOR CC(1);
      when "1100" =>
        VA_out:=(NOT CC(2))AND(CC(3)XNOR CC(1));
      when "1101" =>
        VA_out:=CC(2)OR(CC(3)XOR CC(1));
      when "1110" =>
        VA_out:='1';
      when others=>
        VA_out:='0';
      end case;

    --unused signals
      Dec_out(46)<='0';                    --MemW1
      Dec_out(47)<='0';                    --MemW2
      Dec_out(48)<='0';                    --MemW3
      Dec_out(49)<='0';                    --MemW4
      Dec_out(15)<='0';                    --Unused
      if(IF_ID(27 downto 25) = "101") then
      
      --B/BL Rm  --BLX label(31:28=1111)
        --dummy signals
        Prior_enc <= x"0000";
        Mul_st2 <= '0';
        Swp_st2 <= '0';
        Swi_st2 <= '0';
--        Br_st2 <= '0';
        LS_cnt_en <= '0';
        Lm_st2 <= '0';
        Prior_en <= '0';
            
        Dec_out(76 downto 73) <= "0000";
        Dec_out(68)<='0';                     --Swap instruction indicator
        Dec_out(67)<='0';                     --hwsbyte_inst indicator
        Dec_out(66)<='0';                     --wusbyte_inst indicator
        Dec_out(65)<='0';                     --ls_mul indicator
        if(current_s = basic) then
          Dec_out(3 downto 1)<="000";          --PC_source
          if(VA_out='0') then
            Dec_out(0)<=(NOT stall) AND IC_hit;                     --PC_write
            Br_st2 <= '0';
            Dec_out(29)<=(NOT stall) AND IC_hit;                  --IF/ID write  TO BE CHECKED
          else
            Dec_out(0)<='0';                     --PC_write
            Br_st2 <= '1';                         --Activate FSM --valid branch taken
            Dec_out(29)<='0';                  --IF/ID write  TO BE CHECKED
          end if;
        elsif(current_s = Br_2) then
          if(IF_ID(31 downto 28)="1111")then    --BLX label
            Dec_out(3 downto 1)<="101";          --PC_source
          else
            Dec_out(3 downto 1)<="010";          --PC_source
          end if;
          Dec_out(0)<=(NOT stall) AND IC_hit;                     --PC_write
          Br_st2 <= '0';
          Dec_out(29)<=(NOT stall) AND IC_hit;                  --IF/ID write  TO BE CHECKED
        end if;
          Dec_out(4)<='0';           --RA select
          Dec_out(7 downto 6)<="10";           --WA select
          Dec_out(10 downto 8)<="100";         --DWA select
          Dec_out(13 downto 11)<="011";        --CPSR select
          Dec_out(14)<='0';                    --ALU sourceA select
          Dec_out(17 downto 16)<="00";         --ALU sourceB select
          Dec_out(28)<='0';                     --RC select
          Dec_out(30)<='1';                     --ID/EX write
          Dec_out(31)<='1';                     --EX/MA write
          Dec_out(32)<='1';                     --MA/WB write
          Dec_out(27 downto 26)<="01";          --RB select
          Dec_out(23 downto 22)<="11";        --Shift amount select  
          Dec_out(25 downto 24)<="00";        --Shifter op select 
          Dec_out( 59 downto 58)<="00";       -- Load Store mode select
          Dec_out(36 downto 33)<="0100";        --ALUop
          Dec_out(37)<='0';                      --WB select
          Dec_out(57 downto 56)<="00";           --DWB select
          Dec_out(39)<='0';                    --SPSR select
          Dec_out(40)<=VA_out;                 --COndition code check
          Dec_out(41)<='0';                    --C or S select
          Dec_out(42)<='0';                    --Load PSR select
          Dec_out(50)<='0';                    --Mem Read
          Dec_out(51 downto 50)<="00";         --AccSel
          Dec_out(54 downto 52)<="000";        --Mulop
          Dec_out(55)<=VA_out;                    --BRT
          Dec_out(38)<='0';                --DMA select
          Dec_out(43)<='0';                    --write enable
          if(VA_out='0') then
            Dec_out(18)<='0';                    --RegA write
            Dec_out(19)<='0';                    --CPSR write
            Dec_out(44)<='0';                    --RegB write
            Dec_out(45)<='0';                    --SPSR write
         --   Dec_out(46)<='0';                    --MemW1
         --   Dec_out(47)<='0';                    --MemW2
         --   Dec_out(48)<='0';                    --MemW3
         --   Dec_out(49)<='0';                    --MemW4
          else
            if(IF_ID(31 downto 28)="1111")then    --BLX label
              if(current_s = basic) then
                if(VA_out='0') then
                  Dec_out(19)<='0';                 --CPSR write
                  Dec_out(18)<='0';                    --RegA write
                else
                  Dec_out(19)<='1';                 --CPSR write
                  Dec_out(18)<='1';                    --RegA write
                end if;
              elsif(current_s = Br_2) then
                Dec_out(19)<='0';                 --CPSR write
                Dec_out(18)<='0';                    --RegA write
              end if;
            else                               --B ,BL 
              if(current_s = basic) then
                if(VA_out='0') then
                  Dec_out(18)<='0';                    --RegA write
                else
                  Dec_out(18)<=IF_ID(24);                    --RegA write
                end if;
              elsif(current_s = Br_2) then
                Dec_out(18)<='0';                    --RegA write
              end if;
              Dec_out(19)<='0';                   --CPSR write
            end if;
            Dec_out(45)<='0';                    --SPSR write
          --  Dec_out(46)<='0';                    --MemW1
          --  Dec_out(47)<='0';                    --MemW2
          --  Dec_out(48)<='0';                    --MemW3
          --  Dec_out(49)<='0';                    --MemW4
            Dec_out(44)<='0';                    --RegB write  
          end if;
          Dec_out(21 downto 20)<="10";        --shift data in select
          Dec_out(64 downto 60)<=IF_ID(26)& IF_ID(22)& IF_ID(20)& IF_ID(6)& IF_ID(5);    --22(B/#),20(L),6(S(SH)),5(H(SH))
        
      elsif((IF_ID(27 downto 6)="0001001011111111111100")and(IF_ID(4)='1')) then  
      --BX/BLX Rm
        --dummy signals
        Prior_enc <= x"0000";
        Mul_st2 <= '0';
        Swp_st2 <= '0';
        Swi_st2 <= '0';
        Br_st2 <= '0';
        LS_cnt_en <= '0';
        Lm_st2 <= '0';
        Prior_en <= '0';
            
        Dec_out(76 downto 73) <= "0000";

        Dec_out(68)<='0';                     --Swap instruction indicator
        Dec_out(67)<='0';                     --hwsbyte_inst indicator
        Dec_out(66)<='0';                     --wusbyte_inst indicator
        Dec_out(65)<='0';                     --ls_mul indicator
        Dec_out(0)<=(NOT stall) AND IC_hit;                     --PC_write
        Dec_out(3 downto 1)<="010";          --PC_source
        Dec_out(4)<='0';           --RA select
        Dec_out(7 downto 6)<="10";           --WA select
        Dec_out(10 downto 8)<="100";         --DWA select
        Dec_out(13 downto 11)<="011";        --CPSR select
        Dec_out(14)<='0';                    --ALU sourceA select
        Dec_out(17 downto 16)<="00";         --ALU sourceB select
        Dec_out(28)<='0';                     --RC select
        Dec_out(29)<=(NOT stall) AND IC_hit;                  --IF/ID write  TO BE CHECKED
        Dec_out(30)<='1';                     --ID/EX write
        Dec_out(31)<='1';                     --EX/MA write
        Dec_out(32)<='1';                     --MA/WB write
        Dec_out(27 downto 26)<="01";          --RB select
        Dec_out(23 downto 22)<="11";        --Shift amount select  
        Dec_out(25 downto 24)<="00";        --Shifter op select 
        Dec_out( 59 downto 58)<="00";       -- Load Store mode select
        Dec_out(36 downto 33)<="0100";        --ALUop
       

        Dec_out(37)<='0';                      --WB select
        Dec_out(57 downto 56)<="00";           --DWB select
        Dec_out(39)<='0';                    --SPSR select
        Dec_out(40)<=VA_out;                 --COndition code check
        Dec_out(41)<='0';                    --C or S select
        Dec_out(42)<='0';                    --Load PSR select
        Dec_out(50)<='0';                    --Mem Read
        Dec_out(51 downto 50)<="00";         --AccSel
        Dec_out(54 downto 52)<="000";        --Mulop
        Dec_out(55)<=VA_out;                    --BRT
        Dec_out(38)<='0';                --DMA select
       Dec_out(43)<='0';                    --write enable
        if(VA_out='0') then
          Dec_out(18)<='0';                    --RegA write
          Dec_out(19)<='0';                    --CPSR write
          Dec_out(44)<='0';                    --RegB write
          Dec_out(45)<='0';                    --SPSR write
       --   Dec_out(46)<='0';                    --MemW1
         -- Dec_out(47)<='0';                    --MemW2
        --  Dec_out(48)<='0';                    --MemW3
        --  Dec_out(49)<='0';                    --MemW4
        else
          Dec_out(18)<=IF_ID(5);                    --RegA write
          Dec_out(19)<='1';                   --CPSR write
          Dec_out(45)<='0';                    --SPSR write
        --  Dec_out(46)<='0';                    --MemW1
        --  Dec_out(47)<='0';                    --MemW2
        --  Dec_out(48)<='0';                    --MemW3
        --  Dec_out(49)<='0';                    --MemW4
          Dec_out(44)<='0';                    --RegB write  
        end if;
        Dec_out(21 downto 20)<="10";        --shift data in select
        Dec_out(64 downto 60)<=IF_ID(26)& IF_ID(22)& IF_ID(20)& IF_ID(6)& IF_ID(5);    --22(B/#),20(L),6(S(SH)),5(H(SH))   
      
      elsif(IF_ID(27 downto 24)="1111") then   
      --SWI
        --dummy signals
        Prior_enc <= x"0000";
        Mul_st2 <= '0';
        Swp_st2 <= '0';
--        Swi_st2 <= '0';
        Br_st2 <= '0';
        LS_cnt_en <= '0';
        Lm_st2 <= '0';
        Prior_en <= '0';
            
        Dec_out(76 downto 73) <= "0000";
        Dec_out(68)<='0';                     --Swap instruction indicator
        Dec_out(67)<='0';                     --hwsbyte_inst indicator
        Dec_out(66)<='0';                     --wusbyte_inst indicator
        Dec_out(65)<='0';                     --ls_mul indicator
        if(current_s = basic) then
          Swi_st2 <= '1';                         --Activate FSM
          Dec_out(0)<='0';                  --PC_write
          Dec_out(29)<='0';                  --IF/ID write
          Dec_out(7 downto 6)<="10";           --WA select
          Dec_out(10 downto 8)<="100";         --DWA select
          Dec_out(13 downto 11)<="000";        --CPSR select
          Dec_out(39)<='1';                    --SPSR select
        elsif(current_s = Swi_2) then
          Swi_st2 <= '0';
          Dec_out(0)<=(NOT stall) AND IC_hit;                  --PC_write
          Dec_out(29)<=(NOT stall) AND IC_hit;                  --IF/ID write
          Dec_out(7 downto 6)<="00";           --WA select
          Dec_out(10 downto 8)<="000";         --DWA select
          Dec_out(13 downto 11)<="100";        --CPSR select
          Dec_out(39)<='0';                    --SPSR select
        end if;
        Dec_out(3 downto 1)<="000";          --PC_source
        Dec_out(4)<='0';           --RA select
        
        Dec_out(14)<='0';         --ALU sourceA select
        Dec_out(17 downto 16)<="00";         --ALU sourceB select
        Dec_out(27 downto 26)<="00";          --RB select
        Dec_out(28)<='0';                     --RC select
        Dec_out(30)<='1';                     --ID/EX write
        Dec_out(31)<='1';                     --EX/MA write
        Dec_out(32)<='1';                     --MA/WB write
        Dec_out(36 downto 33)<="0000"; --ALUop
        Dec_out(37)<='0';                      --WB select
        Dec_out(57 downto 56)<="00";                      --DWB select
        Dec_out(40)<=VA_out;                 --COndition code check
        Dec_out(41)<='0';                    --C or S select
        Dec_out(42)<='0';                    --Load PSR select
        Dec_out(50)<='0';                    --Mem Read
        Dec_out(51 downto 50)<="00";         --AccSel
        Dec_out(54 downto 52)<="000";        --Mulop
        Dec_out(55)<='0';                    --BRT
        Dec_out(38)<='0';                    --DMA select
		  Dec_out(43)<='0';                    --write enable
        Dec_out(59 downto 58)<="00";       -- Load Store mode select
        if(VA_out='0') then
          Dec_out(18)<='0';                    --RegA write
          Dec_out(19)<='0';                    --CPSR write
          Dec_out(44)<='0';                    --RegB write
          Dec_out(45)<='0';                    --SPSR write
        --  Dec_out(46)<='0';                    --MemW1
        --  Dec_out(47)<='0';                    --MemW2
        --  Dec_out(48)<='0';                    --MemW3
        --  Dec_out(49)<='0';                    --MemW4
        else
          if(current_s = basic) then
            Dec_out(18)<='1';                    --RegA write
            Dec_out(19)<='0';                 --CPSR write
            Dec_out(45)<='1';                    --SPSR write
          elsif(current_s = Mul_2) then
            Dec_out(18)<='0';                    --RegA write
            Dec_out(19)<='1';                 --CPSR write
            Dec_out(45)<='0';                    --SPSR write
          end if;
            Dec_out(44)<='0';                    --RegB write
          --  Dec_out(46)<='0';                    --MemW1
          --  Dec_out(47)<='0';                    --MemW2
          --Dec_out(48)<='0';                    --MemW3
          --  Dec_out(49)<='0';                    --MemW4
        end if;
        Dec_out(21 downto 20)<="00";          --shift data in select
        Dec_out(25 downto 24)<="00";--Shifter op select  
        Dec_out(23 downto 22)<="00";        --Shift amount select  
        Dec_out(64 downto 60)<=IF_ID(26)& IF_ID(22)& IF_ID(20)& IF_ID(6)& IF_ID(5);    --22(B/#),20(L),6(S(SH)),5(H(SH))

      elsif(IF_ID(27 downto 26)="00") then     --Data Processing
      --Data Processing
        --dummy signals
        Prior_enc <= x"0000";
        Mul_st2 <= '0';
        Swp_st2 <= '0';
        Swi_st2 <= '0';
        Br_st2 <= '0';
        LS_cnt_en <= '0';
        Lm_st2 <= '0';
        Prior_en <= '0';
            
        Dec_out(76 downto 73) <= "0000";
        
        Dec_out(0)<=(NOT stall) AND IC_hit;                     --PC_write
        Dec_out(3 downto 1)<="000";          --PC_source
        Dec_out(4)<='1';           --RA select
        Dec_out(7 downto 6)<="01";           --WA select
        Dec_out(10 downto 8)<="000";         --DWA select
        Dec_out(13 downto 11)<="000";        --CPSR select
        Dec_out(14)<='1';                    --ALU sourceA select
        Dec_out(17 downto 16)<="00";         --ALU sourceB select
        Dec_out(27 downto 26)<="00";          --RB select
        Dec_out(28)<='0';                     --RC select
        Dec_out(29)<=(NOT stall) AND IC_hit;                  --IF/ID write
        Dec_out(30)<='1';                     --ID/EX write
        Dec_out(31)<='1';                     --EX/MA write
        Dec_out(32)<='1';                     --MA/WB write
        Dec_out(36 downto 33)<=IF_ID(24 downto 21); --ALUop
        Dec_out(37)<='0';                      --WB select
        Dec_out(57 downto 56)<="00";                      --DWB select
        Dec_out(39)<='0';                    --SPSR select
        Dec_out(40)<=VA_out;                 --COndition code check
        Dec_out(41)<='0';                    --C or S select
        Dec_out(42)<='0';                    --Load PSR select
        Dec_out(50)<='0';                    --Mem Read
        Dec_out(51 downto 50)<="00";         --AccSel
        Dec_out(54 downto 52)<="000";        --Mulop
        Dec_out(55)<='0';                    --BRT
        Dec_out(38)<='0';                    --DMA select
        Dec_out(43)<='0';                    --write enable
        Dec_out(59 downto 58)<="00";       -- Load Store mode select
        if(VA_out='0') then
          Dec_out(18)<='0';                    --RegA write
          Dec_out(19)<='0';                    --CPSR write
          Dec_out(44)<='0';                    --RegB write
          Dec_out(45)<='0';                    --SPSR write
       --   Dec_out(46)<='0';                    --MemW1
       --   Dec_out(47)<='0';                    --MemW2
       --   Dec_out(48)<='0';                    --MemW3
       --   Dec_out(49)<='0';                    --MemW4
        else
          Dec_out(18)<='1';                    --RegA write
          Dec_out(19)<=IF_ID(20);                 --CPSR write
          Dec_out(44)<='0';                    --RegB write
          Dec_out(45)<='0';                    --SPSR write
       -- Dec_out(46)<='0';                    --MemW1
       -- Dec_out(47)<='0';                    --MemW2
       -- Dec_out(48)<='0';                    --MemW3
       -- Dec_out(49)<='0';                    --MemW4
        end if;
        if(IF_ID(25)='1') then                 --immediate
          Dec_out(21 downto 20)<="01";        --shift data in select
          Dec_out(23 downto 22)<="00";        --Shift amount select  
          Dec_out(25 downto 24)<="11";        --Shifter op select 
        else
          Dec_out(21 downto 20)<="00";          --shift data in select
          Dec_out(25 downto 24)<=IF_ID(6 downto 5);--Shifter op select  
          if(IF_ID(4)='0') then             --immediate shift length
            Dec_out(23 downto 22)<="01";        --Shift amount select  
          elsif(IF_ID(7)='0') then          --Reg shift length
            Dec_out(23 downto 22)<="10";        --Shift amount select  
          end if;
        end if;
        Dec_out(64 downto 60)<=IF_ID(26)& IF_ID(22)& IF_ID(20)& IF_ID(6)& IF_ID(5);    --22(B/#),20(L),6(S(SH)),5(H(SH))
        Dec_out(68)<='0';                     --Swap instruction indicator
        Dec_out(67)<='0';                     --hwsbyte_inst indicator
        Dec_out(66)<='0';                     --wusbyte_inst indicator
        Dec_out(65)<='0';                     --ls_mul indicator
        
      --Multiply
      elsif((IF_ID(27 downto 24)="0000")and(IF_ID(7 downto 4)="1001")) then  --Multiply
        --FSM output logic
        --dummy signals
        Prior_enc <= x"0000";
--        Mul_st2 <= '0';
        Swp_st2 <= '0';
        Swi_st2 <= '0';
        Br_st2 <= '0';
        LS_cnt_en <= '0';
        Lm_st2 <= '0';
        Prior_en <= '0';
            
        Dec_out(76 downto 73) <= "0000";
        
        if(current_s = basic) then
          if((IF_ID(23)='1')and(IF_ID(21)='1')) then          --state transition activate logic
            Mul_st2 <= '1';                         --Activate FSM
          else
            Mul_st2 <= '0';                         --Activate FSM
          end if;
          Dec_out(0)<='0';                     --PC_write
          Dec_out(27 downto 26)<="01";          --RB select
          Dec_out(29)<='0';                  --IF/ID write
        elsif(current_s = Mul_2) then
          Mul_st2 <= '0';
          Dec_out(0)<=(NOT stall) AND IC_hit;                     --PC_write
          Dec_out(27 downto 26)<="10";          --RB select
          Dec_out(29)<=(NOT stall) AND IC_hit;                  --IF/ID write
        end if;
        Dec_out(3 downto 1)<="000";          --PC_source
        Dec_out(4)<='0';           --RA select
        if((IF_ID(23 downto 21)="000")or(IF_ID(23 downto 21)="001"))then
          Dec_out(7 downto 6)<="00";           --WA select
        else
          Dec_out(7 downto 6)<="01";           --WA select
        end if;
        Dec_out(10 downto 8)<="011";         --DWA select
        Dec_out(13 downto 11)<="001";        --CPSR select
        Dec_out(14)<='1';                    --ALU sourceA select
        Dec_out(17 downto 16)<="00";         --ALU sourceB select
        Dec_out(28)<='0';                     --RC select
        Dec_out(30)<='1';                     --ID/EX write
        Dec_out(31)<='1';                     --EX/MA write
        Dec_out(32)<='1';                     --MA/WB write
        Dec_out(36 downto 33)<="0000";        --ALUop
        Dec_out(37)<='0';                     --WB select
        Dec_out(57 downto 56)<="00";                     --DWB select
        Dec_out(39)<='0';                    --SPSR select
        Dec_out(40)<=VA_out;                 --COndition code check
        Dec_out(41)<='0';                    --C or S select
        Dec_out(42)<='0';                    --Load PSR select
        Dec_out(50)<='0';                    --Mem Read
        if((IF_ID(23 downto 21)="000")or(IF_ID(23 downto 21)="100")or(IF_ID(23 downto 21)="110")) then
          Dec_out(51 downto 50)<="00";         --AccSel
        elsif(IF_ID(23 downto 21)="001") then
          Dec_out(51 downto 50)<="01";         --AccSel
        else
          Dec_out(51 downto 50)<="10";         --AccSel
        end if;
        
        Dec_out(54 downto 52)<=IF_ID(23 downto 21);        --Mulop
        Dec_out(55)<='0';                    --BRT
        Dec_out(38)<='0';                    --DMA select
        Dec_out(43)<='0';                    --write enable
        --flush
        if(VA_out='0') then
          Dec_out(18)<='0';                    --RegA write
          Dec_out(44)<='0';                    --RegB write
          Dec_out(19)<='0';                    --CPSR write
          Dec_out(45)<='0';                    --SPSR write
      --    Dec_out(46)<='0';                    --MemW1
      --  Dec_out(47)<='0';                    --MemW2
      --  Dec_out(48)<='0';                    --MemW3
      --  Dec_out(49)<='0';                    --MemW4
        else
          if(current_s = basic) then
            if((IF_ID(23)='1')and(IF_ID(21)='1')) then
              Dec_out(18)<='0';                    --RegA write
              Dec_out(44)<='0';                    --RegB write
              Dec_out(19)<='0';                   --CPSR write
            else
              Dec_out(18)<='1';                    --RegA write
              Dec_out(19)<=IF_ID(20);                 --CPSR write
              if((IF_ID(23 downto 21)="000")or(IF_ID(23 downto 21)="001")) then
                Dec_out(44)<='0';                    --RegB write
              else
                Dec_out(44)<='1';                    --RegB write
              end if;              
            end if;
          elsif(current_s = Mul_2) then
              Dec_out(18)<='1';                    --RegA write
              Dec_out(44)<='1';                    --RegB write
              Dec_out(19)<=IF_ID(20);                 --CPSR write
          end if;

          Dec_out(45)<='0';                    --SPSR write
        --  Dec_out(46)<='0';                    --MemW1
        --  Dec_out(47)<='0';                    --MemW2
         --Dec_out(48)<='0';                    --MemW3
          --Dec_out(49)<='0';                    --MemW4
        end if;
        Dec_out(21 downto 20)<="01";        --shift data in select
        Dec_out(23 downto 22)<="00";        --Shift amount select  
        Dec_out(25 downto 24)<="11";        --Shifter op select 
        Dec_out(59 downto 58)<="00";       -- Load Store mode select
        Dec_out(64 downto 60)<=IF_ID(26)& IF_ID(22)& IF_ID(20)& IF_ID(6)& IF_ID(5);    --22(B/#),20(L),6(S(SH)),5(H(SH))
        Dec_out(68)<='0';                     --Swap instruction indicator
        Dec_out(67)<='0';                     --hwsbyte_inst indicator
        Dec_out(66)<='0';                     --wusbyte_inst indicator
        Dec_out(65)<='0';                     --ls_mul indicator
      --end of multiply
      
      elsif(IF_ID(27 downto 26)="01") then             
      --word and unsigned byte data transfer
        --dummy signals
        Prior_enc <= x"0000";
        Mul_st2 <= '0';
        Swp_st2 <= '0';
        Swi_st2 <= '0';
        Br_st2 <= '0';
        LS_cnt_en <= '0';
        Lm_st2 <= '0';
        Prior_en <= '0';
            
        Dec_out(76 downto 73) <= "0000";
        
        Dec_out(68)<='0';                     --Swap instruction indicator
        Dec_out(67)<='0';                     --hwsbyte_inst indicator
        Dec_out(66)<='1';                     --wusbyte_inst indicator
        Dec_out(65)<='0';                     --ls_mul indicator
        if(IF_ID(20)='0') then         --Store
          Dec_out(0)<=(NOT stall) AND IC_hit;                     --PC_write
          Dec_out(3 downto 1)<="000";          --PC_source
          Dec_out(4)<='1';          			  --RA select
          Dec_out(7 downto 6)<="00";           --WA select
          Dec_out(10 downto 8)<="000";         --DWA select
          Dec_out(13 downto 11)<="000";        --CPSR select
          Dec_out(14)<='1';                    --ALU sourceA select
          Dec_out(17 downto 16)<="01";         --ALU sourceB select
          Dec_out(28)<='1';                     --RC select
          Dec_out(29)<=(NOT stall) AND IC_hit;                  --IF/ID write  TO BE CHECKED
          Dec_out(30)<='1';                     --ID/EX write
          Dec_out(31)<='1';                     --EX/MA write
          Dec_out(32)<='1';                     --MA/WB write
          Dec_out(27 downto 26)<="00";          --RB select
          Dec_out(23 downto 22)<="01";        --Shift amount select  
          if(IF_ID(25)='1') then                   --
            Dec_out( 59 downto 58)<="11";       -- Load Store mode select
            Dec_out(25 downto 24)<=IF_ID(6 downto 5);        --Shifter op select 
          else
            Dec_out( 59 downto 58)<="10";       -- Load Store mode select
            Dec_out(25 downto 24)<="00";        --Shifter op select 
          end if;              
          if(IF_ID(23)= '1') then
             Dec_out(36 downto 33)<="0100";        --ALUop
          else
             Dec_out(36 downto 33)<="0010";
          end if;
          Dec_out(37)<='0';                      --WB select
          Dec_out(57 downto 56)<="10";           --DWB select
          Dec_out(39)<='0';                    --SPSR select
          Dec_out(40)<=VA_out;                 --COndition code check
          Dec_out(41)<='0';                    --C or S select
          Dec_out(42)<='0';                    --Load PSR select
          Dec_out(50)<='0';                    --Mem Read
          Dec_out(21 downto 20)<="11";        --shift data in select

          Dec_out(51 downto 50)<="00";         --AccSel
          Dec_out(54 downto 52)<="000";        --Mulop
          Dec_out(55)<='0';                    --BRT
          Dec_out(38)<=IF_ID(24);                --DMA select
        
          Dec_out(64 downto 60)<=IF_ID(26)& IF_ID(22)& IF_ID(20)& IF_ID(6)& IF_ID(5);    --22(B/#),20(L),6(S(SH)),5(H(SH))
          if(VA_out='0') then
            Dec_out(18)<='0';                    --RegA write
            Dec_out(44)<='0';                    --RegB write
            Dec_out(19)<='0';                    --CPSR write
            Dec_out(45)<='0';                    --SPSR write
				Dec_out(43)<='0';                    --write enable
            --To be done
          --  Dec_out(46)<='0';                    --MemW1
         --   Dec_out(47)<='0';                    --MemW2
         --   Dec_out(48)<='0';                    --MemW3
         --   Dec_out(49)<='0';                    --MemW4
            --To be done
          else
            Dec_out(18)<='0';                    --RegA write
            Dec_out(19)<='0';                    --CPSR write
            Dec_out(45)<='0';                    --SPSR write
				Dec_out(43)<='1';                    --write enable
            --To be done
           -- Dec_out(46)<='0';                    --MemW1
          --  Dec_out(47)<='0';                    --MemW2
          --  Dec_out(48)<='0';                    --MemW3
          --  Dec_out(49)<='0';                    --MemW4
            --To be done
            if(( IF_ID(24)='1' and IF_ID(21)='1' ) or ( IF_ID(24)='0')) then
              Dec_out(44)<='1';                    --RegB write
            else
              Dec_out(44)<='0';                    --RegB write
            end if;
          end if;
        
        
        else                        
        --Load

          Dec_out(0)<=(NOT stall) AND IC_hit;                     --PC_write
          Dec_out(3 downto 1)<="000";          --PC_source
          Dec_out(4)<='1';                     --RA select
          Dec_out(7 downto 6)<="01";           --WA select
          Dec_out(10 downto 8)<="001";         --DWA select
          Dec_out(13 downto 11)<="000";        --CPSR select
          Dec_out(14)<='1';                    --ALU sourceA select
          Dec_out(17 downto 16)<="01";         --ALU sourceB select
          Dec_out(28)<='0';                     --RC select
          Dec_out(29)<=(NOT stall) AND IC_hit;                  --IF/ID write  TO BE CHECKED
          Dec_out(30)<='1';                     --ID/EX write
          Dec_out(31)<='1';                     --EX/MA write
          Dec_out(32)<='1';                     --MA/WB write
          if(IF_ID(25)='1') then                   --
            Dec_out(27 downto 26)<="01";          --RB select
            Dec_out(23 downto 22)<="01";        --Shift amount select  
            Dec_out( 59 downto 58)<="11";       -- Load Store mode select
            Dec_out(25 downto 24)<=IF_ID(6 downto 5);        --Shifter op select 
          else
            Dec_out(27 downto 26)<="00";          --RB select
            Dec_out(23 downto 22)<="00";        --Shift amount select  
            Dec_out( 59 downto 58)<="10";       -- Load Store mode select
            Dec_out(25 downto 24)<="00";        --Shifter op select 
          end if;              
          if(IF_ID(23)= '1') then
            Dec_out(36 downto 33)<="0100";        --ALUop
          else
            Dec_out(36 downto 33)<="0010";
          end if;
          Dec_out(37)<='0';                      --WB select
          Dec_out(57 downto 56)<="10";           --DWB select
          Dec_out(39)<='0';                    --SPSR select
          Dec_out(40)<=VA_out;                 --COndition code check
          Dec_out(41)<='0';                    --C or S select
          Dec_out(42)<='0';                    --Load PSR select
          Dec_out(50)<='1';                    --Mem Read
          Dec_out(51 downto 50)<="00";         --AccSel
          Dec_out(54 downto 52)<="000";        --Mulop
          Dec_out(55)<='0';                    --BRT
          Dec_out(38)<=IF_ID(24);                --DMA select
			 Dec_out(43)<='0';                    --write enable
          if(VA_out='0') then
            Dec_out(18)<='0';                    --RegA write
            Dec_out(19)<='0';                    --CPSR write
            Dec_out(44)<='0';                    --RegB write
            Dec_out(45)<='0';                    --SPSR write
         --   Dec_out(46)<='0';                    --MemW1
         --   Dec_out(47)<='0';                    --MemW2
         --   Dec_out(48)<='0';                    --MemW3
         --   Dec_out(49)<='0';                    --MemW4
          else
            Dec_out(18)<='1';                    --RegA write
            Dec_out(19)<='0';                 --CPSR write
            Dec_out(45)<='0';                    --SPSR write
         --   Dec_out(46)<='0';                    --MemW1
         --   Dec_out(47)<='0';                    --MemW2
           -- Dec_out(48)<='0';                    --MemW3
            --Dec_out(49)<='0';                    --MemW4
            if(( IF_ID(24)='1' and IF_ID(21)='1' ) or ( IF_ID(24)='0')) then
              Dec_out(44)<='1';                    --RegB write
            else
              Dec_out(44)<='0';                    --RegB write
            end if;
          end if;
          Dec_out(21 downto 20)<="00";        --shift data in select
          Dec_out(64 downto 60)<=IF_ID(26)& IF_ID(22)& IF_ID(20)& IF_ID(6)& IF_ID(5);    --22(B/#),20(L),6(S(SH)),5(H(SH))
        end if;
        
      elsif((IF_ID(27 downto 25)="000")and(IF_ID(7)='1')and(IF_ID(4)='1')) then  
      --HW and signed byte data trans
        --dummy signals
        Prior_enc <= x"0000";
        Mul_st2 <= '0';
        Swp_st2 <= '0';
        Swi_st2 <= '0';
        Br_st2 <= '0';
        LS_cnt_en <= '0';
        Lm_st2 <= '0';
        Prior_en <= '0';
            
        Dec_out(76 downto 73) <= "0000";
        
        Dec_out(68)<='0';                     --Swap instruction indicator
        Dec_out(67)<='1';                     --hwsbyte_inst indicator
        Dec_out(66)<='0';                     --wusbyte_inst indicator
        Dec_out(65)<='0';                     --ls_mul indicator
        if(IF_ID(20)='0') then         --Store
          Dec_out(0)<=(NOT stall) AND IC_hit;                     --PC_write
          Dec_out(3 downto 1)<="000";          --PC_source
          Dec_out(4)<='1';                     --RA select
          Dec_out(7 downto 6)<="00";           --WA select
          Dec_out(10 downto 8)<="000";         --DWA select
          Dec_out(13 downto 11)<="000";        --CPSR select
          Dec_out(14)<='1';         --ALU sourceA select
          
          if(IF_ID(22)='1') then
            Dec_out(17 downto 16)<="01";         --ALU sourceB select
          else
            Dec_out(17 downto 16)<="11";         --ALU sourceB select
          end if;
          
          Dec_out(28)<='1';                     --RC select
          Dec_out(29)<=(NOT stall) AND IC_hit;                  --IF/ID write  TO BE CHECKED
          Dec_out(30)<='1';                     --ID/EX write
          Dec_out(31)<='1';                     --EX/MA write
          Dec_out(32)<='1';                     --MA/WB write
          Dec_out(27 downto 26)<="10";          --RB select
          Dec_out(23 downto 22)<="00";        --Shift amount select  
            Dec_out( 59 downto 58)<="00";       -- Load Store mode select
            Dec_out(25 downto 24)<="00";        --Shifter op select 

          if(IF_ID(23)= '1') then
             Dec_out(36 downto 33)<="0100";        --ALUop
          else
             Dec_out(36 downto 33)<="0010";
          end if;

          Dec_out(37)<='0';                      --WB select
          Dec_out(57 downto 56)<="10";           --DWB select
          Dec_out(39)<='0';                    --SPSR select
          Dec_out(40)<=VA_out;                 --COndition code check
          Dec_out(41)<='0';                    --C or S select
          Dec_out(42)<='0';                    --Load PSR select
          Dec_out(50)<='0';                    --Mem Read
          Dec_out(21 downto 20)<="00";        --shift data in select
          Dec_out(51 downto 50)<="00";         --AccSel
          Dec_out(54 downto 52)<="000";        --Mulop
          Dec_out(55)<='0';                    --BRT
          Dec_out(38)<=IF_ID(24);                --DMA select
          
          Dec_out(64 downto 60)<=IF_ID(26)& IF_ID(22)& IF_ID(20)& IF_ID(6)& IF_ID(5);    --22(B/#),20(L),6(S(SH)),5(H(SH))
          if(VA_out='0') then
            Dec_out(18)<='0';                    --RegA write
            Dec_out(44)<='0';                    --RegB write
            Dec_out(19)<='0';                    --CPSR write
            Dec_out(45)<='0';                    --SPSR write
				Dec_out(43)<='0';                    --write enable
            --To be done
            --Dec_out(46)<='0';                    --MemW1
          --  Dec_out(47)<='0';                    --MemW2
          --  Dec_out(48)<='0';                    --MemW3
          --  Dec_out(49)<='0';                    --MemW4
            --To be done
          else
            Dec_out(18)<='0';                    --RegA write
            Dec_out(19)<='0';                    --CPSR write
            Dec_out(45)<='0';                    --SPSR write
				Dec_out(43)<='1';                    --write enable
            --To be done
           -- Dec_out(46)<='0';                    --MemW1
          --  Dec_out(47)<='0';                    --MemW2
          --  Dec_out(48)<='0';                    --MemW3
           -- Dec_out(49)<='0';                    --MemW4
            --To be done
            if(( IF_ID(24)='1' and IF_ID(21)='1' ) or ( IF_ID(24)='0')) then
              Dec_out(44)<='1';                    --RegB write
            else
              Dec_out(44)<='0';                    --RegB write
            end if;
          end if;

        else                        --Load
          Dec_out(0)<=(NOT stall) AND IC_hit;                     --PC_write
          Dec_out(3 downto 1)<="000";          --PC_source
          Dec_out(4)<='1';           --RA select
          Dec_out(7 downto 6)<="01";           --WA select
          Dec_out(10 downto 8)<="001";         --DWA select
          Dec_out(13 downto 11)<="000";        --CPSR select
          Dec_out(14)<='1';         --ALU sourceA select
          Dec_out(17 downto 16)<="01";         --ALU sourceB select
          Dec_out(28)<='0';                     --RC select
          Dec_out(29)<=(NOT stall) AND IC_hit;                  --IF/ID write  TO BE CHECKED
          Dec_out(30)<='1';                     --ID/EX write
          Dec_out(31)<='1';                     --EX/MA write
          Dec_out(32)<='1';                     --MA/WB write
          Dec_out(27 downto 26)<="01";          --RB select
          Dec_out(23 downto 22)<="00";        --Shift amount select  
          Dec_out(25 downto 24)<="00";        --Shifter op select 

          if(IF_ID(22)='1') then
            Dec_out( 59 downto 58)<="00";       -- Load Store mode select
          else
            Dec_out( 59 downto 58)<="01";       -- Load Store mode select
          end if;

          if(IF_ID(23)= '1') then
            Dec_out(36 downto 33)<="0100";        --ALUop
          else
            Dec_out(36 downto 33)<="0010";
          end if;

          Dec_out(37)<='0';                      --WB select
          Dec_out(57 downto 56)<="10";           --DWB select
          Dec_out(39)<='0';                    --SPSR select
          Dec_out(40)<=VA_out;                 --COndition code check
          Dec_out(41)<='0';                    --C or S select
          Dec_out(42)<='0';                    --Load PSR select
          Dec_out(50)<='1';                    --Mem Read
          Dec_out(51 downto 50)<="00";         --AccSel
          Dec_out(54 downto 52)<="000";        --Mulop
          Dec_out(55)<='0';                    --BRT
          Dec_out(38)<=IF_ID(24);                --DMA select
          Dec_out(43)<='0';                    --write enable
          if(VA_out='0') then
            Dec_out(18)<='0';                    --RegA write
            Dec_out(19)<='0';                    --CPSR write
            Dec_out(44)<='0';                    --RegB write
            Dec_out(45)<='0';                    --SPSR write
--            Dec_out(46)<='0';                    --MemW1
--            Dec_out(47)<='0';                    --MemW2
--            Dec_out(48)<='0';                    --MemW3
--            Dec_out(49)<='0';                    --MemW4
          else
            Dec_out(18)<='1';                    --RegA write
            Dec_out(19)<='0';                   --CPSR write
            Dec_out(45)<='0';                    --SPSR write
        --    Dec_out(46)<='0';                    --MemW1
        --    Dec_out(47)<='0';                    --MemW2
        --    Dec_out(48)<='0';                    --MemW3
        --    Dec_out(49)<='0';                    --MemW4
            if(( IF_ID(24)='1' and IF_ID(21)='1' ) or ( IF_ID(24)='0')) then
              Dec_out(44)<='1';                    --RegB write
            else
              Dec_out(44)<='0';                    --RegB write
            end if;
          end if;
          Dec_out(21 downto 20)<="00";        --shift data in select
          Dec_out(64 downto 60)<=IF_ID(26)& IF_ID(22)& IF_ID(20)& IF_ID(6)& IF_ID(5);    --22(B/#),20(L),6(S(SH)),5(H(SH))
        end if;


      elsif(IF_ID(27 downto 25)="100") then     --Multiple register transfer
        --dummy signals
--        Prior_enc <= x"0000";
        Mul_st2 <= '0';
        Swp_st2 <= '0';
        Swi_st2 <= '0';
        Br_st2 <= '0';
--        LS_cnt_en <= '0';
--        Lm_st2 <= '0';
--        Prior_en <= '0';
            
--        Dec_out(76 downto 69) <= "00000000";
--        Dec_out(72 downto 69) <= "0000";
        
        Dec_out(68)<='0';                     --Swap instruction indicator
        Dec_out(67)<='0';                     --hwsbyte_inst indicator
        Dec_out(66)<='0';                     --wusbyte_inst indicator
        Dec_out(65)<='1';                     --ls_mul indicator
        if(IF_ID(20)='0') then         
        --Store
          LS_cnt_en<='1';

          if(current_s = basic) then
            Prior_en <= '1';
          else
            Prior_en <= '0';
          end if;
            
            if(Prior_enc_reg(0)='1') then
              Dec_out(76 downto 73) <= "0000";                        --LDM_Radd
              Prior_enc <= Prior_enc_reg(15 downto 1)&'0';            --Clear corresponding bit
            elsif (Prior_enc_reg(1)='1') then
              Dec_out(76 downto 73) <= "0001";                                --LDM_Radd
              Prior_enc <= Prior_enc_reg(15 downto 2)&'0'&Prior_enc_reg(0);            --Clear corresponding bit
            elsif (Prior_enc_reg(2)='1') then
              Dec_out(76 downto 73) <= "0010";                                --LDM_Radd
              Prior_enc <= Prior_enc_reg(15 downto 3)&'0'&Prior_enc_reg(1 downto 0);            --Clear corresponding bit
            elsif (Prior_enc_reg(3)='1') then
              Dec_out(76 downto 73) <= "0011";                                --LDM_Radd
              Prior_enc <= Prior_enc_reg(15 downto 4)&'0'&Prior_enc_reg(2 downto 0);            --Clear corresponding bit
            elsif (Prior_enc_reg(4)='1') then
              Dec_out(76 downto 73) <= "0100";                                --LDM_Radd
              Prior_enc <= Prior_enc_reg(15 downto 5)&'0'&Prior_enc_reg(3 downto 0);            --Clear corresponding bit
            elsif (Prior_enc_reg(5)='1') then
              Dec_out(76 downto 73) <= "0101";                                --LDM_Radd
              Prior_enc <= Prior_enc_reg(15 downto 6)&'0'&Prior_enc_reg(4 downto 0);            --Clear corresponding bit
            elsif (Prior_enc_reg(6)='1') then
              Dec_out(76 downto 73) <= "0110";                                --LDM_Radd
              Prior_enc <= Prior_enc_reg(15 downto 7)&'0'&Prior_enc_reg(5 downto 0);            --Clear corresponding bit
            elsif (Prior_enc_reg(7)='1') then
              Dec_out(76 downto 73) <= "0111";                                --LDM_Radd
              Prior_enc <= Prior_enc_reg(15 downto 8)&'0'&Prior_enc_reg(6 downto 0);            --Clear corresponding bit
            elsif (Prior_enc_reg(8)='1') then
              Dec_out(76 downto 73) <= "1000";                                --LDM_Radd
              Prior_enc <= Prior_enc_reg(15 downto 9)&'0'&Prior_enc_reg(7 downto 0);            --Clear corresponding bit
            elsif (Prior_enc_reg(9)='1') then
              Dec_out(76 downto 73) <= "1001";                                --LDM_Radd
              Prior_enc <= Prior_enc_reg(15 downto 10)&'0'&Prior_enc_reg(8 downto 0);            --Clear corresponding bit
            elsif (Prior_enc_reg(10)='1') then
              Dec_out(76 downto 73) <= "1010";                                --LDM_Radd
              Prior_enc <= Prior_enc_reg(15 downto 11)&'0'&Prior_enc_reg(9 downto 0);            --Clear corresponding bit
            elsif (Prior_enc_reg(11)='1') then
              Dec_out(76 downto 73) <= "1011";                                --LDM_Radd
              Prior_enc <= Prior_enc_reg(15 downto 12)&'0'&Prior_enc_reg(10 downto 0);            --Clear corresponding bit
            elsif (Prior_enc_reg(12)='1') then
              Dec_out(76 downto 73) <= "1100";                                --LDM_Radd
              Prior_enc <= Prior_enc_reg(15 downto 13)&'0'&Prior_enc_reg(11 downto 0);            --Clear corresponding bit
            elsif (Prior_enc_reg(13)='1') then
              Dec_out(76 downto 73) <= "1101";                                --LDM_Radd
              Prior_enc <= Prior_enc_reg(15 downto 14)&'0'&Prior_enc_reg(12 downto 0);            --Clear corresponding bit
            elsif (Prior_enc_reg(14)='1') then
              Dec_out(76 downto 73) <= "1110";                                --LDM_Radd
              Prior_enc <= Prior_enc_reg(15)&'0'&Prior_enc_reg(13 downto 0);            --Clear corresponding bit
            elsif (Prior_enc_reg(15)='1') then
              Dec_out(76 downto 73) <= "1111";                                --LDM_Radd
              Prior_enc <= '0'&Prior_enc_reg(14 downto 0);            --Clear corresponding bit
            end if;

          if(current_s = basic) then
            Dec_out(14)<='1';         --ALU sourceA select
            if(count>"0001") then
              Lm_st2<='1';
              Dec_out(0)<='0';                     --PC_write
              Dec_out(29)<='0';                  --IF/ID write  TO BE CHECKED
            else
              Lm_st2<='0';
              Dec_out(0)<=(NOT stall) AND IC_hit;                     --PC_write
              Dec_out(29)<=(NOT stall) AND IC_hit;                  --IF/ID write  TO BE CHECKED
            end if;
          elsif(current_s = Lm_2) then
            Lm_st2<='0';
            Dec_out(14)<='1';         --ALU sourceA select
            if(count="0000") then
              Dec_out(0)<=(NOT stall) AND IC_hit;                     --PC_write
              Dec_out(29)<=(NOT stall) AND IC_hit;                  --IF/ID write  TO BE CHECKED
            else
              Dec_out(0)<='0';                     --PC_write
              Dec_out(29)<='0';                  --IF/ID write  TO BE CHECKED
            end if;
          end if;
          Dec_out(3 downto 1)<="000";          --PC_source
          Dec_out(4)<='1';           --RA select
          Dec_out(7 downto 6)<="00";           --WA select
          Dec_out(10 downto 8)<="000";         --DWA select
          Dec_out(13 downto 11)<="000";        --CPSR select
          if((IF_ID(22)='1')and(IF_ID(15)='1')) then
          else
          end if;
          Dec_out(17 downto 16)<="10";         --ALU sourceB select
          Dec_out(28)<='0';                     --RC select
          Dec_out(30)<='1';                     --ID/EX write
          Dec_out(31)<='1';                     --EX/MA write
          Dec_out(32)<='1';                     --MA/WB write
          Dec_out(27 downto 26)<="11";          --RB select
          Dec_out(23 downto 22)<="00";        --Shift amount select  
          Dec_out(25 downto 24)<="00";        --Shifter op select 

          Dec_out( 59 downto 58)<="00";       -- Load Store mode select

          if(IF_ID(23)= '1') then
            Dec_out(36 downto 33)<="0100";        --ALUop
          else
            Dec_out(36 downto 33)<="0010";
          end if;

          Dec_out(37)<='0';                      --WB select
          Dec_out(57 downto 56)<="00";           --DWB select
          Dec_out(39)<='0';                    --SPSR select
          Dec_out(40)<=VA_out;                 --COndition code check
          Dec_out(41)<='0';                    --C or S select
          Dec_out(42)<='0';                    --Load PSR select
          Dec_out(50)<='0';                    --Mem Read
          Dec_out(51 downto 50)<="00";         --AccSel
          Dec_out(54 downto 52)<="000";        --Mulop
          Dec_out(55)<='0';                    --BRT
          Dec_out(38)<='1';                     --DMA select
         
          if(VA_out='0') then
            Dec_out(18)<='0';                    --RegA write
            Dec_out(19)<='0';                    --CPSR write
            Dec_out(44)<='0';                    --RegB write
            Dec_out(45)<='0';                    --SPSR write
				Dec_out(43)<='0';                    --write enable
            --Dec_out(46)<='0';                    --MemW1
            --Dec_out(47)<='0';                    --MemW2
            --Dec_out(48)<='0';                    --MemW3
           -- Dec_out(49)<='0';                    --MemW4
          else
          if(current_s = basic) then
            if(count="0001") then
              if(( IF_ID(24)='1' and IF_ID(21)='1' ) or ( IF_ID(24)='0')) then
                Dec_out(18)<='1';                    --RegA write
              else
                Dec_out(18)<='0';                    --RegA write
              end if;
            elsif(count="0000") then
              Dec_out(18)<='0';                    --RegA write
            else
              Dec_out(18)<='0';                    --RegA write
            end if;
          elsif(current_s = Lm_2) then
            if(count="0000") then
              if(( IF_ID(24)='1' and IF_ID(21)='1' ) or ( IF_ID(24)='0')) then
                Dec_out(18)<='1';                    --RegA write
              else
                Dec_out(18)<='0';                    --RegA write
              end if;
            else
              Dec_out(18)<='0';                    --RegA write
            end if;
          end if;
            Dec_out(19)<='0';                   --CPSR write
            Dec_out(45)<='0';                    --SPSR write
				Dec_out(43)<='1';                    --write enable
           -- Dec_out(46)<='1';                    --MemW1
           -- Dec_out(47)<='1';                    --MemW2
           -- Dec_out(48)<='1';                    --MemW3
           -- Dec_out(49)<='1';                    --MemW4
            Dec_out(44)<='0';                    --RegB write
          end if;
          Dec_out(21 downto 20)<="00";        --shift data in select
          Dec_out(64 downto 60)<=IF_ID(26)& IF_ID(22)& IF_ID(20)& IF_ID(6)& IF_ID(5);    --22(B/#),20(L),6(S(SH)),5(H(SH))


        else                        --LDM
          LS_cnt_en<='1';
          
          if(current_s = basic) then
            Prior_en <= '1';
          else
            Prior_en <= '0';
          end if;
            
            if(Prior_enc_reg(0)='1') then
              Dec_out(76 downto 73) <= "0000";                        --LDM_Radd
              Prior_enc <= Prior_enc_reg(15 downto 1)&'0';            --Clear corresponding bit
            elsif (Prior_enc_reg(1)='1') then
              Dec_out(76 downto 73) <= "0001";                                --LDM_Radd
              Prior_enc <= Prior_enc_reg(15 downto 2)&'0'&Prior_enc_reg(0);            --Clear corresponding bit
            elsif (Prior_enc_reg(2)='1') then
              Dec_out(76 downto 73) <= "0010";                                --LDM_Radd
              Prior_enc <= Prior_enc_reg(15 downto 3)&'0'&Prior_enc_reg(1 downto 0);            --Clear corresponding bit
            elsif (Prior_enc_reg(3)='1') then
              Dec_out(76 downto 73) <= "0011";                                --LDM_Radd
              Prior_enc <= Prior_enc_reg(15 downto 4)&'0'&Prior_enc_reg(2 downto 0);            --Clear corresponding bit
            elsif (Prior_enc_reg(4)='1') then
              Dec_out(76 downto 73) <= "0100";                                --LDM_Radd
              Prior_enc <= Prior_enc_reg(15 downto 5)&'0'&Prior_enc_reg(3 downto 0);            --Clear corresponding bit
            elsif (Prior_enc_reg(5)='1') then
              Dec_out(76 downto 73) <= "0101";                                --LDM_Radd
              Prior_enc <= Prior_enc_reg(15 downto 6)&'0'&Prior_enc_reg(4 downto 0);            --Clear corresponding bit
            elsif (Prior_enc_reg(6)='1') then
              Dec_out(76 downto 73) <= "0110";                                --LDM_Radd
              Prior_enc <= Prior_enc_reg(15 downto 7)&'0'&Prior_enc_reg(5 downto 0);            --Clear corresponding bit
            elsif (Prior_enc_reg(7)='1') then
              Dec_out(76 downto 73) <= "0111";                                --LDM_Radd
              Prior_enc <= Prior_enc_reg(15 downto 8)&'0'&Prior_enc_reg(6 downto 0);            --Clear corresponding bit
            elsif (Prior_enc_reg(8)='1') then
              Dec_out(76 downto 73) <= "1000";                                --LDM_Radd
              Prior_enc <= Prior_enc_reg(15 downto 9)&'0'&Prior_enc_reg(7 downto 0);            --Clear corresponding bit
            elsif (Prior_enc_reg(9)='1') then
              Dec_out(76 downto 73) <= "1001";                                --LDM_Radd
              Prior_enc <= Prior_enc_reg(15 downto 10)&'0'&Prior_enc_reg(8 downto 0);            --Clear corresponding bit
            elsif (Prior_enc_reg(10)='1') then
              Dec_out(76 downto 73) <= "1010";                                --LDM_Radd
              Prior_enc <= Prior_enc_reg(15 downto 11)&'0'&Prior_enc_reg(9 downto 0);            --Clear corresponding bit
            elsif (Prior_enc_reg(11)='1') then
              Dec_out(76 downto 73) <= "1011";                                --LDM_Radd
              Prior_enc <= Prior_enc_reg(15 downto 12)&'0'&Prior_enc_reg(10 downto 0);            --Clear corresponding bit
            elsif (Prior_enc_reg(12)='1') then
              Dec_out(76 downto 73) <= "1100";                                --LDM_Radd
              Prior_enc <= Prior_enc_reg(15 downto 13)&'0'&Prior_enc_reg(11 downto 0);            --Clear corresponding bit
            elsif (Prior_enc_reg(13)='1') then
              Dec_out(76 downto 73) <= "1101";                                --LDM_Radd
              Prior_enc <= Prior_enc_reg(15 downto 14)&'0'&Prior_enc_reg(12 downto 0);            --Clear corresponding bit
            elsif (Prior_enc_reg(14)='1') then
              Dec_out(76 downto 73) <= "1110";                                --LDM_Radd
              Prior_enc <= Prior_enc_reg(15)&'0'&Prior_enc_reg(13 downto 0);            --Clear corresponding bit
            elsif (Prior_enc_reg(15)='1') then
              Dec_out(76 downto 73) <= "1111";                                --LDM_Radd
              Prior_enc <= '0'&Prior_enc_reg(14 downto 0);            --Clear corresponding bit
            end if;
          
          if(current_s = basic) then
            Dec_out(14)<='1';         --ALU sourceA select
            if(count>"0001") then
              Lm_st2<='1';
              Dec_out(0)<='0';                     --PC_write
              Dec_out(29)<='0';                  --IF/ID write  TO BE CHECKED
            else
              Lm_st2<='0';
              Dec_out(0)<=(NOT stall) AND IC_hit;                     --PC_write
              Dec_out(29)<=(NOT stall) AND IC_hit;                  --IF/ID write  TO BE CHECKED
            end if;
          elsif(current_s = Lm_2) then
            Lm_st2<='0';
            Dec_out(14)<='1';                      --ALU SOURCEA SELECT
            if(count="0000") then
              Dec_out(0)<=(NOT stall) AND IC_hit;                     --PC_write
              Dec_out(29)<=(NOT stall) AND IC_hit;                  --IF/ID write  TO BE CHECKED
            else
              Dec_out(0)<='0';                     --PC_write
              Dec_out(29)<='0';                  --IF/ID write  TO BE CHECKED
            end if;
          end if;
          Dec_out(3 downto 1)<="000";          --PC_source
          Dec_out(4)<='1';           --RA select
          Dec_out(7 downto 6)<="00";           --WA select
          Dec_out(10 downto 8)<="000";         --DWA select
          Dec_out(13 downto 11)<="101";        --CPSR select
          if((IF_ID(22)='1')and(IF_ID(15)='1')) then
          else
          end if;
          Dec_out(17 downto 16)<="10";         --ALU sourceB select
          Dec_out(28)<='0';                     --RC select
          Dec_out(30)<='1';                     --ID/EX write
          Dec_out(31)<='1';                     --EX/MA write
          Dec_out(32)<='1';                     --MA/WB write
          Dec_out(27 downto 26)<="00";          --RB select
          Dec_out(23 downto 22)<="00";        --Shift amount select  
          Dec_out(25 downto 24)<="00";        --Shifter op select 

          Dec_out( 59 downto 58)<="00";       -- Load Store mode select

          if(IF_ID(23)= '1') then
            Dec_out(36 downto 33)<="0100";        --ALUop
          else
            Dec_out(36 downto 33)<="0010";
          end if;

          Dec_out(37)<='1';                      --WB select
          Dec_out(57 downto 56)<="01";           --DWB select
          Dec_out(39)<='0';                    --SPSR select
          Dec_out(40)<=VA_out;                 --COndition code check
          Dec_out(41)<='0';                    --C or S select
          Dec_out(42)<='0';                    --Load PSR select
          Dec_out(50)<='1';                    --Mem Read
          Dec_out(51 downto 50)<="00";         --AccSel
          Dec_out(54 downto 52)<="000";        --Mulop
          Dec_out(55)<='0';                    --BRT
          Dec_out(38)<='1';                --DMA select
          Dec_out(43)<='0';                    --write enable
          if(VA_out='0') then
            Dec_out(18)<='0';                    --RegA write
            Dec_out(19)<='0';                    --CPSR write
            Dec_out(44)<='0';                    --RegB write
            Dec_out(45)<='0';                    --SPSR write
            --Dec_out(46)<='0';                    --MemW1
           -- Dec_out(47)<='0';                    --MemW2
           -- Dec_out(48)<='0';                    --MemW3
           -- Dec_out(49)<='0';                    --MemW4
          else
          if(current_s = basic) then
            if(count="0001") then
              if(( IF_ID(24)='1' and IF_ID(21)='1' ) or ( IF_ID(24)='0')) then
                Dec_out(18)<='1';                    --RegA write
              else
                Dec_out(18)<='0';                    --RegA write
              end if;
              if((IF_ID(15)='1')and(IF_ID(22)='1')) then
                Dec_out(19)<='1';                   --CPSR write
              else
                Dec_out(19)<='0';                   --CPSR write
              end if;
            elsif(count="0000") then
              Dec_out(18)<='0';                    --RegA write
              Dec_out(19)<='0';                   --CPSR write
            else
              Dec_out(18)<='0';                    --RegA write
              Dec_out(19)<='0';                   --CPSR write
            end if;
          elsif(current_s = Lm_2) then
            if(count="0000") then
              if(( IF_ID(24)='1' and IF_ID(21)='1' ) or ( IF_ID(24)='0')) then
                Dec_out(18)<='1';                    --RegA write
              else
                Dec_out(18)<='0';                    --RegA write
              end if;
              if((IF_ID(15)='1')and(IF_ID(22)='1')) then
                Dec_out(19)<='1';                   --CPSR write
              else
                Dec_out(19)<='0';                   --CPSR write
              end if;
            else
              Dec_out(18)<='0';                    --RegA write
              Dec_out(19)<='0';                   --CPSR write
            end if;
          end if;
            Dec_out(45)<='0';                    --SPSR write
           -- Dec_out(46)<='0';                    --MemW1
          --  Dec_out(47)<='0';                    --MemW2
          --  Dec_out(48)<='0';                    --MemW3
          --  Dec_out(49)<='0';                    --MemW4
            Dec_out(44)<='1';                    --RegB write
          end if;
          Dec_out(21 downto 20)<="00";        --shift data in select
          Dec_out(64 downto 60)<=IF_ID(26)& IF_ID(22)& IF_ID(20)& IF_ID(6)& IF_ID(5);    --22(B/#),20(L),6(S(SH)),5(H(SH))
        end if;

        
      elsif((IF_ID(27 downto 23)& IF_ID(21 downto 20)& IF_ID(11 downto 4))="000100000001001") then  
      --Swap memory and reg
        --dummy signals
        Prior_enc <= x"0000";
        Mul_st2 <= '0';
--        Swp_st2 <= '0';
        Swi_st2 <= '0';
        Br_st2 <= '0';
        LS_cnt_en <= '0';
        Lm_st2 <= '0';
        Prior_en <= '0';
            
        Dec_out(76 downto 73) <= "0000";

        Dec_out(68)<='1';                     --Swap instruction indicator
        Dec_out(67)<='0';                     --hwsbyte_inst indicator
        Dec_out(66)<='0';                     --wusbyte_inst indicator
        Dec_out(65)<='0';                     --ls_mul indicator
        Dec_out(3 downto 1)<="000";          --PC_source
        Dec_out(4)<='1';           --RA select
        Dec_out(7 downto 6)<="01";           --WA select
        Dec_out(10 downto 8)<="001";         --DWA select
        Dec_out(13 downto 11)<="000";        --CPSR select
        Dec_out(14)<='0';         --ALU sourceA select
        Dec_out(17 downto 16)<="00";         --ALU sourceB select
        Dec_out(28)<='0';                     --RC select
        Dec_out(30)<='1';                     --ID/EX write
        Dec_out(31)<='1';                     --EX/MA write
        Dec_out(32)<='1';                     --MA/WB write
        Dec_out(27 downto 26)<="01";          --RB select
        Dec_out(23 downto 22)<="00";        --Shift amount select  
        Dec_out(25 downto 24)<="00";        --Shifter op select 
        Dec_out( 59 downto 58)<="00";       -- Load Store mode select
        Dec_out(36 downto 33)<="0000";        --ALUop
        Dec_out(37)<='0';                      --WB select
        Dec_out(57 downto 56)<="00";           --DWB select
        Dec_out(39)<='0';                    --SPSR select
        Dec_out(40)<=VA_out;                 --COndition code check
        Dec_out(41)<='0';                 --C or S select
        Dec_out(42)<='0';                    --Load PSR select(will take
        -- care of immediate operand or Rm)
        Dec_out(51 downto 50)<="00";         --AccSel
        Dec_out(54 downto 52)<="000";        --Mulop
        Dec_out(55)<='0';                    --BRT
        Dec_out(38)<='0';                --DMA select
        
        if(current_s = basic) then
          Swp_st2 <= '1';                         --Activate FSM
          Dec_out(50)<='1';                    --Mem Read
          Dec_out(29)<='0';                  --IF/ID write  TO BE CHECKED
          Dec_out(0)<='0';                     --PC_write
        elsif(current_s = Swp_2) then
          Swp_st2 <= '0';
          Dec_out(50)<='0';                    --Mem Read
          Dec_out(29)<=(NOT stall) AND IC_hit;                  --IF/ID write  TO BE CHECKED
          Dec_out(0)<=(NOT stall) AND IC_hit;                     --PC_write
        end if;
        
        if(VA_out='0') then
          Dec_out(18)<='0';                    --RegA write
          Dec_out(19)<='0';                    --CPSR write
          Dec_out(44)<='0';                    --RegB write
          Dec_out(45)<='0';                    --SPSR write
			 Dec_out(43)<='0';                    --write enable
          --Dec_out(46)<='0';                    --MemW1
         -- Dec_out(47)<='0';                    --MemW2
         -- Dec_out(48)<='0';                    --MemW3
         -- Dec_out(49)<='0';                    --MemW4
        else
          if(current_s = basic) then
              Dec_out(18)<='1';                    --RegA write
				  Dec_out(43)<='0';                    --write enable
             -- Dec_out(46)<='0';                    --MemW1
            --  Dec_out(47)<='0';                    --MemW2
            --  Dec_out(48)<='0';                    --MemW3
            --  Dec_out(49)<='0';                    --MemW4
          elsif(current_s = Swp_2) then
              Dec_out(18)<='0';                    --RegA write
				  Dec_out(43)<='1';                    --write enable
              --to be done
           --   Dec_out(46)<='0';                    --MemW1
           --   Dec_out(47)<='0';                    --MemW2
            --  Dec_out(48)<='0';                    --MemW3
           --   Dec_out(49)<='0';                    --MemW4
              --to be done
          end if;
          Dec_out(19)<='1';                   --CPSR write
          Dec_out(45)<='0';                    --SPSR write 
          Dec_out(44)<='0';                    --RegB write  
        end if;
        Dec_out(21 downto 20)<="00";        --shift data in select
        Dec_out(64 downto 60)<=IF_ID(26)& IF_ID(22)& IF_ID(20)& IF_ID(6)& IF_ID(5);    --22(B/#),20(L),6(S(SH)),5(H(SH))
        
      elsif((IF_ID(27 downto 23)="00010")and(IF_ID(21 downto 16)="001111")and(IF_ID(11 downto 0)=x"000")) then
      --Status reg to general reg
        --dummy signals
        Prior_enc <= x"0000";
        Mul_st2 <= '0';
        Swp_st2 <= '0';
        Swi_st2 <= '0';
        Br_st2 <= '0';
        LS_cnt_en <= '0';
        Lm_st2 <= '0';
        Prior_en <= '0';
            
        Dec_out(76 downto 73) <= "0000";

        Dec_out(0)<=(NOT stall) AND IC_hit;                     --PC_write
        Dec_out(3 downto 1)<="000";          --PC_source
        Dec_out(4)<='0';           --RA select
        Dec_out(7 downto 6)<="01";           --WA select
        Dec_out(10 downto 8)<="010";         --DWA select
        Dec_out(13 downto 11)<="000";        --CPSR select
        Dec_out(14)<='0';                    --ALU sourceA select
        Dec_out(17 downto 16)<="00";         --ALU sourceB select
        Dec_out(28)<='0';                     --RC select
        Dec_out(29)<=(NOT stall) AND IC_hit;                  --IF/ID write  TO BE CHECKED
        Dec_out(30)<='1';                     --ID/EX write
        Dec_out(31)<='1';                     --EX/MA write
        Dec_out(32)<='1';                     --MA/WB write
        Dec_out(27 downto 26)<="00";          --RB select
        Dec_out(23 downto 22)<="00";        --Shift amount select  
        Dec_out(25 downto 24)<="00";        --Shifter op select 
        Dec_out( 59 downto 58)<="00";       -- Load Store mode select
        Dec_out(36 downto 33)<="0000";        --ALUop
        Dec_out(37)<='0';                      --WB select
        Dec_out(57 downto 56)<="00";           --DWB select
        Dec_out(39)<='0';                    --SPSR select
        Dec_out(40)<=VA_out;                 --COndition code check
        Dec_out(41)<=IF_ID(22);                    --C or S select
        Dec_out(42)<='0';                    --Load PSR select
        Dec_out(50)<='0';                    --Mem Read
        Dec_out(51 downto 50)<="00";         --AccSel
        Dec_out(54 downto 52)<="000";        --Mulop
        Dec_out(55)<='0';                    --BRT
        Dec_out(38)<='0';                --DMA select
        Dec_out(43)<='0';                    --write enable
        if(VA_out='0') then
          Dec_out(18)<='0';                    --RegA write
          Dec_out(19)<='0';                    --CPSR write
          Dec_out(44)<='0';                    --RegB write
          Dec_out(45)<='0';                    --SPSR write
         -- Dec_out(46)<='0';                    --MemW1
         -- Dec_out(47)<='0';                    --MemW2
        --  Dec_out(48)<='0';                    --MemW3
        --  Dec_out(49)<='0';                    --MemW4
        else
          Dec_out(18)<='1';                    --RegA write
          Dec_out(19)<='0';                   --CPSR write
          Dec_out(45)<='0';                    --SPSR write
         -- Dec_out(46)<='0';                    --MemW1
         -- Dec_out(47)<='0';                    --MemW2
         -- Dec_out(48)<='0';                    --MemW3
         -- Dec_out(49)<='0';                    --MemW4
          Dec_out(44)<='0';                    --RegB write  
        end if;
        Dec_out(21 downto 20)<="00";        --shift data in select
        Dec_out(64 downto 60)<=IF_ID(26)& IF_ID(22)& IF_ID(20)& IF_ID(6)& IF_ID(5);    --22(B/#),20(L),6(S(SH)),5(H(SH))   
        Dec_out(68)<='0';                     --Swap instruction indicator
        Dec_out(67)<='0';                     --hwsbyte_inst indicator
        Dec_out(66)<='0';                     --wusbyte_inst indicator
        Dec_out(65)<='0';                     --ls_mul indicator


      elsif((IF_ID(27 downto 26)& IF_ID(24 downto 23)& IF_ID(21 downto 20)& IF_ID(15 downto 12))="0010101111") then
        --general reg to status reg
        --dummy signals
        Prior_enc <= x"0000";
        Mul_st2 <= '0';
        Swp_st2 <= '0';
        Swi_st2 <= '0';
        Br_st2 <= '0';
        LS_cnt_en <= '0';
        Lm_st2 <= '0';
        Prior_en <= '0';
            
        Dec_out(76 downto 73) <= "0000";
        
        Dec_out(0)<=(NOT stall) AND IC_hit;                     --PC_write
        Dec_out(3 downto 1)<="000";          --PC_source
        Dec_out(4)<='0';           --RA select
        Dec_out(7 downto 6)<="01";           --WA select
        Dec_out(10 downto 8)<="010";         --DWA select
        Dec_out(13 downto 11)<="010";        --CPSR select
        Dec_out(14)<='0';                    --ALU sourceA select
        Dec_out(17 downto 16)<="00";         --ALU sourceB select
        Dec_out(28)<='0';                     --RC select
        Dec_out(29)<=(NOT stall) AND IC_hit;                  --IF/ID write  TO BE CHECKED
        Dec_out(30)<='1';                     --ID/EX write
        Dec_out(31)<='1';                     --EX/MA write
        Dec_out(32)<='1';                     --MA/WB write
        Dec_out(27 downto 26)<="01";          --RB select
        Dec_out(23 downto 22)<="00";        --Shift amount select  
        Dec_out(25 downto 24)<="11";        --Shifter op select 
        Dec_out( 59 downto 58)<="00";       -- Load Store mode select
        Dec_out(36 downto 33)<="0000";        --ALUop
        Dec_out(37)<='0';                      --WB select
        Dec_out(57 downto 56)<="00";           --DWB select
        Dec_out(39)<='0';                    --SPSR select
        Dec_out(40)<=VA_out;                 --COndition code check
        Dec_out(41)<=IF_ID(22);                 --C or S select
        Dec_out(42)<=IF_ID(25);                    --Load PSR select(will take
        -- care of immediate operand or Rm)
        Dec_out(50)<='0';                    --Mem Read
        Dec_out(51 downto 50)<="00";         --AccSel
        Dec_out(54 downto 52)<="000";        --Mulop
        Dec_out(55)<='0';                    --BRT
        Dec_out(38)<='0';                --DMA select
        Dec_out(43)<='0';                    --write enable
        if(VA_out='0') then
          Dec_out(18)<='0';                    --RegA write
          Dec_out(19)<='0';                    --CPSR write
          Dec_out(44)<='0';                    --RegB write
          Dec_out(45)<='0';                    --SPSR write
        --  Dec_out(46)<='0';                    --MemW1
        --  Dec_out(47)<='0';                    --MemW2
        --  Dec_out(48)<='0';                    --MemW3
        --  Dec_out(49)<='0';                    --MemW4
        else
          Dec_out(18)<='0';                    --RegA write
          if(IF_ID(22)='0') then                  --CPSRWrite
          Dec_out(19)<='1';                   --CPSR write
          Dec_out(45)<='0';                    --SPSR write
          elsif(IF_ID(22)='1') then                  --SPSRWrite
          
          Dec_out(19)<='0';                   --CPSR write
          Dec_out(45)<='1';                    --SPSR write
          end if;
          
          --Dec_out(46)<='0';                    --MemW1
          --Dec_out(47)<='0';                    --MemW2
          --Dec_out(48)<='0';                    --MemW3
          --Dec_out(49)<='0';                    --MemW4
          Dec_out(44)<='0';                    --RegB write  
        end if;
        Dec_out(21 downto 20)<="01";        --shift data in select
        Dec_out(64 downto 60)<=IF_ID(26)& IF_ID(22)& IF_ID(20)& IF_ID(6)& IF_ID(5);    --22(B/#),20(L),6(S(SH)),5(H(SH))   
        Dec_out(68)<='0';                     --Swap instruction indicator
        Dec_out(67)<='0';                     --hwsbyte_inst indicator
        Dec_out(66)<='0';                     --wusbyte_inst indicator
        Dec_out(65)<='0';                     --ls_mul indicator
      end if;
    end process;
    

    Clk_event: PROCESS (clk,reset)
    begin
      if (reset='1') then
        current_s <= basic;  --default state on reset.
      elsif clk'event and clk='1' then
        current_s <= next_s;   --state change.
      END if;
    END PROCESS Clk_event;

    FSM_mul: PROCESS(current_s,count,Mul_st2,Swp_st2,Swi_st2,Br_st2,Lm_st2)
    begin
      case current_s is
      when basic =>
        if(Mul_st2='1') then
          next_s <= Mul_2;
        elsif(Swp_st2='1') then
          next_s <= Swp_2;
        elsif(Swi_st2='1') then
          next_s <= Swi_2;
        elsif(Br_st2='1') then
          next_s <= Br_2;
        elsif(Lm_st2='1') then
          next_s <= Lm_2;
        else
          next_s <= basic;
        end if;
      when Mul_2 =>
        next_s <= basic;
      when Swp_2 =>
        next_s <= basic;
      when Swi_2 =>
        next_s <= basic;
      when Br_2 =>
        next_s <= basic;
      when Lm_2 =>
        if(count = "0000") then
          next_s <= basic;
        end if;
      end case;
    end process FSM_mul;
    
    Clk_cntr: PROCESS (clk,reset)
    begin
      if (reset='1') then
        count_reg <= "0000";  --default state on reset.
      elsif clk'event and clk='1' then
        count_reg <= count;  --saving previous count.
      END if;
    END PROCESS Clk_cntr;

    Prior_reg: PROCESS (Prior_en,clk)
    begin
      if (Prior_en='1') then
        Prior_enc_reg <= IF_ID(15 downto 0);  --default state on LDM/SDM occurence.
      elsif clk'event and clk='1' then
        Prior_enc_reg <= Prior_enc;  --Reassign.
      END if;
    END PROCESS Prior_reg;

    LS_counter: PROCESS(LS_cnt_en,current_s,count_reg)
    begin
      if(LS_cnt_en = '1') then
        if(current_s = basic) then
          count <= ("000"& IF_ID(15))+("000"& IF_ID(14))+("000"& IF_ID(13))+("000"& IF_ID(12))
                  +("000"& IF_ID(11))+("000"& IF_ID(10))+("000"& IF_ID(9))+("000"& IF_ID(8))
                  +("000"& IF_ID(7))+("000"& IF_ID(6))+("000"& IF_ID(5))+("000"& IF_ID(4))
                  +("000"& IF_ID(3))+("000"& IF_ID(2))+("000"& IF_ID(1))+("000"& IF_ID(0));
        elsif(current_s = Lm_2) then
          count <= count_reg - 1;
        end if;
      else
        count <= "0000";
      end if;
      
      --Sending signal to mux depending on basic and LM_2 state
        if(current_s = basic) then
          Dec_out(5) <= '0';      --LDM_state
        elsif(current_s = Lm_2) then
          Dec_out(5) <= '1';      --LDM_state
        end if;
    end process LS_counter;
      
    
--    Condition: PROCESS (CC,IF_ID(31 downto 28))
--    begin
--      case IF_ID(31 downto 28) is
--      when "0000" =>
--        VA_out<=CC(2);
--      when "0001" =>
--        VA_out<=NOT CC(2);
--      when "0010" =>
--        VA_out<=CC(0);
--      when "0011" =>
--        VA_out<=NOT CC(0);
--      when "0100" =>
--        VA_out<=CC(3);
--      when "0101" =>
--        VA_out<=NOT CC(3);
--      when "0110" =>
--        VA_out<=CC(1);
--      when "0111" =>
--        VA_out<=NOT CC(1);
--      when "1000" =>
--        VA_out<=CC(0)AND(NOT CC(2));
--      when "1001" =>
--        VA_out<=(NOT CC(0))OR CC(2);
--      when "1010" =>
--        VA_out<=CC(3)XNOR CC(1);
--      when "1011" =>
--        VA_out<=CC(3)XOR CC(1);
--      when "1100" =>
--        VA_out<=(NOT CC(2))AND(CC(3)XNOR CC(1));
--      when "1101" =>
--        VA_out<=CC(2)OR(CC(3)XOR CC(1));
--      when others=>
--        VA_out<='0';
--      end case;
--    end process Condition;
  end Decoder_behav;
