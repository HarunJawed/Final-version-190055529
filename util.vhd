--------------------------------------------------------------------------------
-- Title:       : Package with common declarations
-- Project      : EExDSA Practical Work
-- Author       : Dr. John Williams
-- Copyright    : 2019-2022 Aston University
--------------------------------------------------------------------------------
-- Purpose       : 
-- Package with component declarations for EE3DSA coursework 
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;
use STD.textio.all;

package util is

  -- return number of its to address n elements
  function nbits(n      : in integer) return integer;
  
  -- function to produce a string representation of a std_logic_vector
  function to_string (a :    std_logic_vector) return string;

  -- wait for delay time then check v=tv and assert error if not
  procedure check_vector(v  : in std_logic_vector; delay : in time;
                         tv : in std_logic_vector);

end package;


package body util is

  function nbits(n : in integer) return integer is
  begin
    return integer(ceil(log2(real(n))));
  end function nbits;

  function to_string (a : STD_LOGIC_VECTOR) return string is
    variable b    : string (1 to a'length) := (others => NUL);
    variable stri : integer                := 1;
  begin
    for i in a'range loop
      b(stri) := std_logic'image(a((i)))(2);
      stri    := stri+1;
    end loop;
    return b;
  end function;

  procedure check_vector(
    v     : in std_logic_vector;
    delay : in time;
    tv    : in std_logic_vector
    ) is
  begin
    wait for delay;
    assert v = tv report to_string(tv) & " failed - output=" & to_string(v);
  end check_vector;

end package body util;
