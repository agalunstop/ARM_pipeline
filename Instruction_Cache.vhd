LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;

ENTITY Instr_Cache IS
  
  PORT( Load    : IN  std_logic;  
        Datain  : IN  std_logic_vector(31 downto 0);  --ALU_SRCA OUTPUT VL COME HERE
        Address : IN  std_logic_vector(31 downto 0);    --Carry bit from the shifter
        clk     : IN  std_logic;    --clk
        reset   : IN  std_logic;    --reset
        IC_hit  : OUT std_logic;    
        Dataout : OUT std_logic_vector(31 downto 0));
END Instr_Cache;

ARCHITECTURE Instr_Cache_behav OF Instr_Cache IS
  subtype MEM is std_logic_vector ( 31 downto 0); -- define size of Register
  type IC is array (0 to 255) of MEM; -- define size of MEMORY
  signal IC_arr: IC := (others=>x"00000000");
  
  
  begin
    PROCESS(clk)
    variable ADDR: integer range 0 to 255; -- to translate address to integer
    begin
      IC_hit <= '1';
      ADDR := conv_integer(Address(7 downto 0)); -- converts address to integer 
      if(clk'event and clk='1') then
        if(Load = '1') then
          IC_arr(ADDR) <= Datain;
        else
          Dataout <= IC_arr(ADDR);
        end if;
      end if;
    end process;
  end Instr_Cache_behav;