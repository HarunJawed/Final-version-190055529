--------------------------------------------------------------------------------
-- Title:       : Clock Prescaler Implementation
-- Project      : EE4DSH Practical Work
-- Author       : Dr. John Williams
-- Copyright    : 2018--2022 Aston University
--------------------------------------------------------------------------------
-- Purpose:
-- Derive a low frequency clock enable signal by
-- dividing a master system clock by an integer n.
-- Output clk_div is 1 for a single period every n system clock pulses
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;

entity clk_prescaler is
  generic (
    n: integer                   --  divide clk by n to generate clk_div
  );
  port (
    clk: in std_logic;           -- input (system) clock
    clk_div: out std_logic:='0'  -- output clock enable signal at freq=clk/n
    );
end clk_prescaler;

architecture rtl of clk_prescaler is
  -- determine required register bit length pre-synthesis as constant
  constant no_bits: integer:=integer(ceil(log2(real(n))));
  -- counting up is more efficient than counting down in Vivado synthesis
  signal count: unsigned(no_bits-1 downto 0) :=(others=>'0');
begin
  
  -- Clocked synchronous process sets clk_div to 1 for a single period
  -- every n clk pulses.
  cp: process(clk)
  begin
    if(rising_edge(clk)) then
      if (count=to_unsigned(n-1,no_bits)) then
        clk_div<='1';
        count<=(others=>'0');
      else
        clk_div<='0';
        count<=count+1;
      end if;
    end if;
  end process;

end rtl;

--                                                                            --
