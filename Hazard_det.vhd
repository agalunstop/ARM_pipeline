LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;

ENTITY Hazard_DU IS
  
  PORT( RA        : IN  std_logic_vector(3 downto 0);
        RB        : IN  std_logic_vector(3 downto 0);
        RC        : IN  std_logic_vector(3 downto 0);
        ID_EX_HDU : IN  std_logic_vector(9 downto 0);
        stall     : OUT std_logic);
end Hazard_DU;

ARCHITECTURE Hazard_DU_behav OF Hazard_DU IS

  begin
    
    HDU: PROCESS(RA,RB,RC,ID_EX_HDU)
    begin
      if(ID_EX_HDU(0)='1') then
        if((RA = ID_EX_HDU(5 downto 2))or(RB = ID_EX_HDU(5 downto 2))or(RC = ID_EX_HDU(5 downto 2))) then
          stall <= '1';
        else
          stall <= '0';
        end if;
      elsif((ID_EX_HDU(1) = '1')) then
        if((RA = ID_EX_HDU(9 downto 6))or(RB = ID_EX_HDU(9 downto 6))or(RC = ID_EX_HDU(9 downto 6))) then
          stall <= '1';
        else
          stall <= '0';
        end if;
      else
        stall <= '0';
      end if;
    end process;
  end Hazard_DU_behav;
              
          




