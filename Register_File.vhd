LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;

ENTITY Register_File IS
  
  PORT( reset : IN  std_logic;
        clk   : IN  std_logic;                    --clk
        WrA   : IN  std_logic;                    --Write enable A
		    WrB	  : IN  STD_logic;                    --WRITE ENABLE B
        WrPC  : IN  std_logic;                    --Write enable
        WrCPSR: IN  std_logic;                    --Write enable
        WrSPSR: IN  std_logic;                    --Write enable
        RA    : IN  std_logic_vector(3 downto 0);  --Register A address
        RB    : IN  std_logic_vector(3 downto 0);  --Register B address
        RC    : IN  std_logic_vector(3 downto 0);  --Register C address
        WA_WRITEBACK    : IN  std_logic_vector(3 downto 0);  --Register Write A address FROM WRITE BACK STAGE
        WB_WRITEBACK    : IN  std_logic_vector(3 downto 0);  --Register Write B address FROM WRITE BACK STAGE
        DWA   : IN  std_logic_vector(31 downto 0);  --Register Write A data in FROM MUXES
        DWB   : IN  std_logic_vector(31 downto 0);  --Register Write B data in FROM MUXES
        PCin  : IN  std_logic_vector(31 downto 0);  --PC data in
        CPSRin: IN  std_logic_vector(31 downto 0);  --CPSR data in FROM MUXES
        SPSRin: IN  std_logic_vector(31 downto 0);  --SPSR data in FROM MUXES
        DA   : OUT std_logic_vector(31 downto 0);  --Register Read A data out
        DB   : OUT std_logic_vector(31 downto 0);  --Register Read B data out
        DC   : OUT std_logic_vector(31 downto 0);  --Register Read C data out
        PC    : OUT std_logic_vector(31 downto 0);  --PC data out
        CPSR  : OUT std_logic_vector(31 downto 0);  --CPSR data out
        SPSR  : OUT std_logic_vector(31 downto 0));  --SPSR data out
END Register_File;

ARCHITECTURE RF_behav OF Register_File IS
  subtype REG is std_logic_vector ( 31 downto 0); -- define size of Register
  type Reg_F is array (0 to 15) of REG; -- define size of MEMORY
  signal RF_arr: Reg_f;
  signal CPSR_reg,SPSR_reg: std_logic_vector(31 downto 0); -- PC,CPSR and SPSR register
  signal clk_inv: std_logic;
 
  begin
    clk_inv <= NOT clk;
   
    Dual_wr: PROCESS(clk,reset)
    variable REG_ADDR_INWA: integer range 0 to 15; -- to translate address to integer 
    variable REG_ADDR_INWB: integer range 0 to 15; -- to translate address to integer 
    begin
      REG_ADDR_INWA := conv_integer (WA_WRITEBACK); -- converts address to integer 
      REG_ADDR_INWB := conv_integer (WB_WRITEBACK); -- converts address to integer
      if (reset='1') then
        RF_arr<=(others=>x"00000000");  --default state on reset.
        CPSR_reg<=x"00000000";
        SPSR_reg<=x"00000000";
      elsif (clk = '1') then
        if(WrA='1') then
          RF_arr(REG_ADDR_INWA) <= DWA;  --Write register when Write enable
        end if;
		  if(WrB='1') then
          RF_arr(REG_ADDR_INWB) <= DWB;  --Write register when Write enable
        end if;
        if(WrCPSR='1') then
          CPSR_reg<= CPSRin;
        end if;
        if(WrSPSR='1') then
          SPSR_reg<= SPSRin;
        end if;
        if(WrPC='1') then
          RF_arr(15) <= PCin;
        end if;
      end if;
    end process Dual_wr;
    
    Dual_rd: PROCESS(clk_inv,reset)
    variable REG_ADDR_INRA: integer range 0 to 15; -- to translate address to integer 
    variable REG_ADDR_INRB: integer range 0 to 15; -- to translate address to integer 
    variable REG_ADDR_INRC: integer range 0 to 15; -- to translate address to integer 
    begin
      REG_ADDR_INRA := conv_integer (RA); -- converts address to integer 
      REG_ADDR_INRB := conv_integer (RB); -- converts address to integer 
      REG_ADDR_INRC := conv_integer (RC); -- converts address to integer 
      if (reset='1') then
        DA <= x"00000000";   
        DB <= x"00000000";
        DC <= x"00000000";
        CPSR<= x"00000000";
        SPSR<= x"00000000";
      elsif(clk_inv = '0') then
        DA <= RF_arr(REG_ADDR_INRA);   --Register read.
        DB <= RF_arr(REG_ADDR_INRB);   --Register read.
        DC <= RF_arr(REG_ADDR_INRC);   --Register read.
        CPSR<= CPSR_reg;
        SPSR<= SPSR_reg;
        PC <= RF_arr(15);
      end if;
    end process Dual_rd;
      
  end RF_behav;
        
    
