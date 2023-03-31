--------------------------------------------------------------------------------
-- Title:       : Register file implementation
-- Project      : EE4DSH Practical Work
-- Author       : Dr. John Williams
-- Copyright    : 2019-2022 Aston University
--------------------------------------------------------------------------------
-- Purpose:
-- Provides register file implementation
-- Read operations are asynchronous.
-- Write is synchronous.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity registerfile is
  generic (
    depth  : integer := 8;              -- number of registers
    awidth : integer := 5;              -- register address width
    dwidth : integer := 32              -- width of registers
    );
  port (
    clk       : in  std_logic;          -- system clock for write
    reset     : in  std_logic                 := '0';
    regwrite  : in  std_logic                 := '0';  -- if true write to register
    readreg1  : in  unsigned(awidth-1 downto 0);
    readreg2  : in  unsigned(awidth-1 downto 0);
    writereg  : in  unsigned(awidth-1 downto 0);
    readdata1 : out signed(dwidth-1 downto 0) := (others => '0');
    readdata2 : out signed(dwidth-1 downto 0) := (others => '0');
    writedata : in  signed(dwidth-1 downto 0) := (others => '0')
    );
end registerfile;

architecture behavioral of registerfile is
  -- Declaration of type and signal for Rregisters
  type reg_t is array (0 to DEPTH-1) of signed(dwidth-1 downto 0);
  signal reg : reg_t := (others => (others => '0'));

  signal destreg : unsigned(awidth-1 downto 0);
begin
  -- register outputs are combinational
  readdata1 <= reg(to_integer(readreg1));
  readdata2 <= reg(to_integer(readreg2));

  process(clk)
  begin
    -- writing data is done on next clock edge
    if(rising_edge(clk)) then
      if reset = '1' then
        for i in reg'range loop
          reg(i) <= (others => '0');
        end loop;
      elsif(regwrite = '1') then
        reg(to_integer(writereg)) <= writedata;
      end if;
    end if;
  end process;

end behavioral;

