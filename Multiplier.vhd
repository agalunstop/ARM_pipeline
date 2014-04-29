LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all; 

ENTITY Multiplier IS
  
  PORT( MulA  : IN  std_logic_vector(31 downto 0);  --Multiplicand
        MulB  : IN  std_logic_vector(31 downto 0);  --Multiplier
        Add   : IN  std_logic_vector(63 downto 0);  --Input to be added
        Optn  : IN  std_logic_vector(2 downto 0);   --Operation specifier
        clk   : IN  std_logic;
        reset : IN  std_logic;
        MulM_o: OUT std_logic_vector(31 downto 0);  --MSB output
        MulL_o: OUT std_logic_vector(31 downto 0);  --LSB output
        CC_out: OUT std_logic_vector(3 downto 0);   --Condition codes
        Stall : OUT std_logic);
END Multiplier;

ARCHITECTURE Multiplier_behav OF Multiplier IS

  signal MulM_int,MulL_int : std_logic_vector(31 downto 0);
  signal MulL_sig,MulM_sig : std_logic_vector(31 downto 0);
  signal Start,SMact : std_logic;
  type state_type is (stop,op2);  --floor count.
  signal current_s,next_s: state_type;  --current and next state declaration.
  begin
    Operation: PROCESS(MulA,MulB,Add,SMact,Optn,current_s)
    variable MulAs  : SIGNED(31 downto 0);
    variable MulBs  : SIGNED(31 downto 0);
    variable MulAus : UNSIGNED(31 downto 0);
    variable MulBus : UNSIGNED(31 downto 0);
    variable Multemps : SIGNED(63 downto 0);
    variable Multempus : UNSIGNED(63 downto 0);
    variable MulL : std_logic_vector(31 downto 0);
    variable MulM : std_logic_vector(31 downto 0);
    variable Multemp2us : std_logic_vector(31 downto 0);

    begin
      CC_out(1 downto 0) <= "00";
      case Optn is
      when "000" =>         --MUL
        MulAus := unsigned(MulA);
        MulBus := unsigned(MulB);
        Multempus :=  MulAus*MulBus;
        MulM := x"00000000";
        MulL := STD_LOGIC_VECTOR(Multempus(31 downto 0));
        Start <= '0';
        Stall <= '0';
        CC_out(3) <= MulL(31);  --N flag
        if(MulL = x"00000000") then
          CC_out(2) <= '1';     --Z flag
        else
          CC_out(2) <= '0';     --Z flag
        end if;
      when "001" =>         --MLA
        MulAus := unsigned(MulA);
        MulBus := unsigned(MulB);
        Multempus := MulAus*MulBus;
        Multemp2us:= STD_LOGIC_VECTOR(Multempus(31 downto 0)) + Add(31 downto 0);
        MulM := x"00000000";
        MulL := Multemp2us;
        Start <= '0';
        Stall <= '0';
        CC_out(3) <= MulL(31);  --N flag
        if(MulL = x"00000000") then
          CC_out(2) <= '1';     --Z flag
        else
          CC_out(2) <= '0';     --Z flag
        end if;
      when "100" =>         --UMULL
        MulAus := unsigned(MulA);
        MulBus := unsigned(MulB);
        Multempus := MulAus*MulBus;
        MulM := STD_LOGIC_VECTOR(Multempus(63 downto 32));
        MulL := STD_LOGIC_VECTOR(Multempus(31 downto 0));
        Start <= '0';
        CC_out(3) <= MulM(31);  --N flag
        Stall <= '0';
        if((MulM = x"00000000") AND (MulL = x"00000000")) then
          CC_out(2) <= '1';     --Z flag
        else
          CC_out(2) <= '0';     --Z flag
        end if;
      when "110" =>         --SMULL
        MulAs := signed(MulA);
        MulBs := signed(MulB);
        Multemps := MulAs*MulBs;
        MulM := STD_LOGIC_VECTOR(Multemps(63 downto 32));
        MulL := STD_LOGIC_VECTOR(Multemps(31 downto 0));
        Start <= '0';
        CC_out(3) <= MulM(31);  --N flag
        Stall <= '0';
        if((MulM = x"00000000") AND (MulL = x"00000000")) then
          CC_out(2) <= '1';     --Z flag
        else
          CC_out(2) <= '0';     --Z flag
        end if;
      when "101" =>         --UMLAL
        if(current_s = stop) then
          Start <= '1';
          MulAus := unsigned(MulA);
          MulBus := unsigned(MulB);
          Multempus := MulAus*MulBus;
          MulM := STD_LOGIC_VECTOR(Multempus(63 downto 32));
          MulL := STD_LOGIC_VECTOR(Multempus(31 downto 0));
          Stall <= '1';
        else 
          Start <= '0';
          MulAus := unsigned(MulA);
          MulBus := unsigned(MulB);
          Multempus := MulAus*MulBus;
          MulM := MulM_int + Add(63 downto 32);
          MulL := MulL_int + Add(31 downto 0);
          Stall <= '0';
        end if;
        CC_out(3) <= MulM(31);  --N flag
        if((MulM = x"00000000") AND (MulL = x"00000000")) then
          CC_out(2) <= '1';     --Z flag
        else
          CC_out(2) <= '0';     --Z flag
        end if;
      when "111" =>         --SMLAL
        if(current_s = stop) then
          Start <= '1';
          MulAs := signed(MulA);
          MulBs := signed(MulB);
          Multemps := MulAs*MulBs;
          MulM := STD_LOGIC_VECTOR(Multemps(63 downto 32));
          MulL := STD_LOGIC_VECTOR(Multemps(31 downto 0));
          Stall <= '1';
        else 
          Start <= '0';
          MulAs := signed(MulA);
          MulBs := signed(MulB);
          Multemps := MulAs*MulBs;
          MulM := MulM_int + Add(63 downto 32);
          MulL := MulL_int + Add(31 downto 0);
          Stall <= '0';
        end if;
        CC_out(3) <= MulM(31);  --N flag
        if((MulM = x"00000000") AND (MulL = x"00000000")) then
          CC_out(2) <= '1';     --Z flag
        else
          CC_out(2) <= '0';     --Z flag
        end if;
      when others =>
        MulM := x"00000000";
        MulL := x"00000000";
        CC_out(3 downto 2) <= "00";  --N flag
      end case;
      MulM_o <= MulM;
      MulL_o <= MulL;
      MulM_sig <= MulM;
      MulL_sig <= MulL;
    end process Operation;
      
    Clk_event: PROCESS (clk,reset)
    begin
      if (reset='1') then
        current_s <= stop;  --default state on reset.
        MulM_int <= x"00000000";
        MulL_int <= x"00000000";
      elsif clk'event and clk='1' then
        current_s <= next_s;   --state change.
        MulM_int <= MulM_sig;
        MulL_int <= MulL_sig;
      END if;
    END PROCESS Clk_event;
    
    SM: PROCESS(current_s,Start)
    begin
      case current_s is
      when stop =>
        if (Start = '1') then
          next_s <= op2;
        else
          next_s <= stop;
        end if;
      when op2 =>
        next_s <= stop;
      when others =>
        next_s <= stop;
      end case;
    end process SM;
        
        

  end Multiplier_behav;          