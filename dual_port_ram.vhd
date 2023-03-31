--------------------------------------------------------------------------------
-- Title:       : Clock Prescaler Implementation
-- Project      : EE4DSH Practical Work
-- Author       : Dr. John Williams
-- Copyright    : 2020-2022 Aston University
--------------------------------------------------------------------------------
-- Purpose:
-- Implementation for asymmetric dual port ram
-- synthesises to Block Ram element with Xilinx 2019.1
-- ports are a and b use separate clocks and enables
-- port a is writeable, port b readable
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity dual_port_ram is
  generic (
    dwidth : integer := 8;              -- width of data
    awidth : integer := 8;  -- width address - needs to be sufficient for depth
    depth  : integer := 256  -- how many elements of this width to store.
    );
  port (
    clka, clkb   : in  std_logic;       -- system clock
    wea, enb     : in  std_logic;       --  enable
    addra, addrb : in  unsigned(awidth-1 downto 0);          -- addresses
    dina         : in  std_logic_vector(dwidth-1 downto 0);  -- data write buses
    doutb        : out std_logic_vector(dwidth-1 downto 0):=(others=>'0')   -- data read buses
    );
end dual_port_ram;

architecture behavioral of dual_port_ram is
  -- Declaration of type and signal for RAM
  type ram_t is array (0 to depth-1)
    of std_logic_vector(dwidth-1 downto 0);
  signal ram : ram_t := (others => (others => '0'));

  attribute ram_style : string;
  attribute ram_style of ram : signal is "block";
begin

--behavioural process for read and write operations.
  pa : process(clka)
  begin
    if(rising_edge(clka) and wea = '1') then
      assert addra<depth report "Error: RAM Write Addr ="&integer'image(to_integer(addra));
      ram(to_integer(addra)) <= dina;
    end if;
  end process;

  pb : process(clkb)
  begin
    if(rising_edge(clkb) and enb = '1') then
      doutb <= ram(to_integer(addrb));
    end if;
  end process;

end behavioral;
