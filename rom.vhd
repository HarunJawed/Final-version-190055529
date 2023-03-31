--------------------------------------------------------------------------------
-- Title:       : ROM implementation
-- Project      : EExDSA Practical Work
-- Author       : Dr. John Williams
-- Copyright    : 2019-2022 Aston University
--------------------------------------------------------------------------------
-- Purpose      : 
-- single port rom - synthesises to Block Rom element ROM18E1
-- with Xilinx 2019.1
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use IEEE.std_logic_textio.all;

entity rom is
  generic (
    dwidth   : integer := 32;           -- width of data
    awidth   : integer := 8;            -- width address
    depth    : integer := 256;  -- how many elements of this width to store.
    initfile : string                   -- filename to read binary data from
    );
  port (
    clk  : in  std_logic;               -- system clock
    addr : in  unsigned(awidth-1 downto 0);
    dout : out std_logic_vector(dwidth-1 downto 0):=(others=>'0')
    );
end rom;

architecture behavioral of rom is
  -- Declaration of type and signal for ROM
  type rom_type is array (0 to depth-1)
    of std_logic_vector(dwidth-1 downto 0);

  impure function InitRomFromFile (RomFileName : in string)
    return rom_type is
    file RomFile : text open read_mode is RomFilename;
    variable buf : line;
    variable rom : rom_type:=(others=>(others=>'0'));
  begin
    for i in rom_type'range loop
      if not(endfile(RomFile)) then
        readline (RomFile, buf);
        read (buf, rom(i));
      end if;
    end loop;
    return rom;
  end function;

  constant rom               : rom_type := InitRomFromFile(initfile);
  attribute rom_style        : string;
  attribute rom_style of rom : constant is "block";

begin

--behavioural process for read and write operation (simulation).
  process(clk)
  begin
    if(rising_edge(clk)) then           -- and en='1' then
      dout <= rom(to_integer(addr));
    end if;
  end process;

end behavioral;
