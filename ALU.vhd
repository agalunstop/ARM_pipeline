LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;

ENTITY ALU IS
  
  PORT( ALU_op  : IN  std_logic_vector(3 downto 0);  
        Rn      : IN  std_logic_vector(31 downto 0);  --ALU_SRCA OUTPUT VL COME HERE
        Op2     : IN  std_logic_vector(31 downto 0);
        shiftC  : IN  std_logic;    --Carry bit from the shifter
        clk     : IN  std_logic;    --clk
        reset   : IN  std_logic;    --reset
        N       : OUT std_logic;
        Z       : OUT std_logic;
        C_o     : OUT std_logic;
        V_o     : OUT std_logic;
        Rd      : OUT std_logic_vector(31 downto 0));
END ALU;

ARCHITECTURE ALU_behav OF ALU IS
  signal C_reg,V_reg,V_int,C_int: std_logic;
  begin

    Operation: PROCESS(ALU_op,Rn,Op2,ShiftC,V_reg)
    variable Rar: std_logic_vector(32 downto 0);
    variable Rt: std_logic_vector(31 downto 0);
    variable Comp: std_logic_vector(31 downto 0);
    variable addC: std_logic_vector(32 downto 0);
    variable V,C: std_logic;
    begin
      case ALU_op is
      when x"0" =>          --AND
--        addC <= x"00000000" & '0';
        Rt := Rn AND Op2;
        C := ShiftC;
        V := V_reg;
        Rd <= Rt;
      when x"1" =>          --EOR
--        addC <= x"00000000" & '0';
        Rt := Rn XOR Op2;    
        C := ShiftC;
        V := V_reg;
        Rd <= Rt;
      when x"2" =>          --SUB
--        addC <= x"00000000" & '0';
        Rar:= ('0'&Rn)-('0'&Op2);
        Comp := NOT(Op2);
        C := Rar(32);
        V := Rn(30) XOR (Comp(30) XOR Rar(30));  --Overflow from 30 to 31
        Rd <= Rar(31 downto 0);
      when x"3" =>          --RSB
--        addC <= x"00000000" & '0';
        Rar:= ('0'&Op2)-('0'&Rn);
        Comp := NOT(Rn);
        C := Rar(32);
        V := Comp(30) XOR (Op2(30) XOR Rar(30));  --Overflow from 30 to 31
        Rd <= Rar(31 downto 0);
      when x"4" =>          --ADD 
--        addC <= x"00000000" & '0';
        Rar:= ('0'&Rn)+('0'&Op2);
        C := Rar(32);
        V := Rn(30) XOR (Op2(30) XOR Rar(30));  --Overflow from 30 to 31
        Rd <= Rar(31 downto 0);
      when x"5" =>          --ADC
        addC := x"00000000" & C_reg;
        Rar:= ('0'&Rn)+('0'&Op2)+addC;
        C := Rar(32);
        V := Rn(30) XOR (Op2(30) XOR Rar(30));  --Overflow from 30 to 31
        Rd <= Rar(31 downto 0);
      when x"6" =>          --SBC
        addC := x"00000000" & C_reg;
        Rar:= ('0'&Rn)-('0'&Op2)-(NOT addC);
        C := Rar(32);
        V := Rn(30) XOR (Op2(30) XOR Rar(30));  --Overflow from 30 to 31
        Rd <= Rar(31 downto 0);
      when x"7" =>          --RSC
        addC := x"00000000" & C_reg;
        Rar:= ('0'&Op2)-('0'&Rn)-(NOT addC);
        C := Rar(32);
        V := Rn(30) XOR (Op2(30) XOR Rar(30));  --Overflow from 30 to 31
        Rd <= Rar(31 downto 0);
      when x"8" =>          --TST
--        addC <= x"00000000" & '0';
        Rt := Rn AND Op2;
        C := ShiftC;
        V := V_reg;  --Overflow from 30 to 31
        Rd <= Rt;
      when x"9" =>          --TEQ
--        addC <= x"00000000" & '0';
        Rt := Rn XOR Op2;
        C := ShiftC;
        V := V_reg;  --Overflow from 30 to 31
        Rd <= Rt;
      when x"A" =>          --CMP
--        addC <= x"00000000" & '0';
        Rar:= ('0'&Rn)-('0'&Op2);
        C := Rar(32);
        V := Rn(30) XOR (Op2(30) XOR Rar(30));  --Overflow from 30 to 31
        Rd <= Rar(31 downto 0);
      when x"B" =>          --CMN
--        addC <= x"00000000" & '0';
        Rar:= ('0'&Rn)+('0'&Op2);
        C := Rar(32);
        V := Rn(30) XOR (Op2(30) XOR Rar(30));  --Overflow from 30 to 31
        Rd <= Rar(31 downto 0);
      when x"C" =>          --ORR
--        addC <= x"00000000" & '0';
        Rt := Rn OR Op2;
        C := ShiftC;
        V := V_reg;  --Overflow from 30 to 31
        Rd <= Rt;
      when x"D" =>          --MOV
--        addC <= x"00000000" & '0';
        Rt := Op2;
        C := ShiftC;
        V := V_reg;  --Overflow from 30 to 31
        Rd <= Rt;
      when x"E" =>          --BIC
--        addC <= x"00000000" & '0';
        Rt := Rn AND (NOT Op2);
        C := C_reg;
        V := V_reg;  --Overflow from 30 to 31
        Rd <= Rt;
      when x"F" =>          --MVN
--        addC <= x"00000000" & '0';
        Rt := NOT Op2;
        C := ShiftC;
        V := V_reg;  --Overflow from 30 to 31
        Rd <= Rt;
      when others => 
--        addC <= x"00000000" & '0';
        Rt := x"00000000";
        C := '0';
        V := '0';  --Overflow from 30 to 31
        Rd <= Rt;
      end case;
      V_o <= V;
      C_o <= C;
      V_int <= V;
      C_int <= C;
      N <= Rt(31);
      if(Rt = x"00000000") then
        Z <= '1';
      else
        Z <= '0';
      end if;
    end process Operation;

    Clk_event: PROCESS (clk,reset)
    begin
      if (reset='1') then
        V_reg <= '0';
        C_reg <= '0';
      elsif clk'event and clk='1' then
        V_reg <= V_int;
        C_reg <= C_int;
      END if;
    END PROCESS Clk_event;

  end ALU_behav;
   