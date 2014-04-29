LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;

ENTITY Data_Cache IS
  
  PORT( W1      : IN  std_logic;
        W2      : IN  std_logic;
        W3      : IN  std_logic;  
        W4      : IN  std_logic;    
        RE      : IN  std_logic;    
        Datain  : IN  std_logic_vector(31 downto 0);  --ALU_SRCA OUTPUT VL COME HERE
        Address : IN  std_logic_vector(31 downto 0);    --Carry bit from the shifter
        clk     : IN  std_logic;    --clk
        reset   : IN  std_logic;    --reset
        DC_hit  : OUT std_logic;    
        Dataout : OUT std_logic_vector(31 downto 0));
END Data_Cache;

ARCHITECTURE Data_Cache_behav OF Data_Cache IS
  subtype MEM is std_logic_vector ( 31 downto 0); -- define size of Register
  type DC is array (0 to 255) of MEM; -- define size of MEMORY
  signal DC_arr: DC := (others=>x"00000000");
  
  
  begin
    PROCESS(clk)
    variable ADDR: integer range 0 to 255; -- to translate address to integer
    begin
      DC_hit <= '1';
      ADDR := conv_integer(Address(7 downto 0)); -- converts address to integer 
      if(clk'event and clk='1') then
        if(W1 = '1') then
          DC_arr(ADDR)(7 downto 0) <= Datain(7 downto 0);
        end if;
        if(W2 = '1') then
          DC_arr(ADDR)(15 downto 8) <= Datain(15 downto 8);
        end if;
        if(W3 = '1') then
          DC_arr(ADDR)(23 downto 16) <= Datain(23 downto 16);
        end if;
        if(W4 = '1') then
          DC_arr(ADDR)(31 downto 24) <= Datain(31 downto 24);
        end if;
        if(RE = '1') then
          Dataout <= DC_arr(ADDR);
        end if;
      end if;
    end process;
  end Data_Cache_behav;
