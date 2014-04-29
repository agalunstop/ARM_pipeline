LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;

ENTITY Shifter IS
  
  PORT( Input : IN  std_logic_vector(31 downto 0);  --Input to be shifted
        Contrl: IN  std_logic_vector(1 downto 0);   --Control input to specify RR,RL,LLS, AR
        Amnt  : IN  std_logic_vector(31 downto 0);  --Amount to be shifted by
        Output: OUT std_logic_vector(31 downto 0);  --Shifted output
        ShiftC: OUT std_logic);                      --bit number 32 from shifter

END Shifter;

ARCHITECTURE Shifter_behav OF Shifter IS
  begin
    Shift_control:PROCESS(Contrl,Input,Amnt)
    variable Amnt_int : integer range 0 to 31;
    variable Input_bit : bit_vector(31 downto 0);
    variable Output_bit : bit_vector(31 downto 0);
    begin
      Amnt_int  := conv_integer(Amnt);
      Input_bit := to_bitvector(Input);
      case Contrl is
      when "00" =>      --Logical Shift Left
        Output_bit := Input_bit sll Amnt_int-1;
      when "01" =>      --Logical Shift Right
        Output_bit := Input_bit srl Amnt_int-1;
      when "10" =>      --Arithmetic Shift Right
        Output_bit := Input_bit sra Amnt_int-1;
      when "11" =>      --Rotate Right
        Output_bit := Input_bit ror Amnt_int-1;
      when others =>
        Output_bit := x"00000000";
      end case;
      Output <= to_stdlogicvector(Output_bit);
      ShiftC <= '0';
    end process Shift_control;
  end Shifter_behav;

