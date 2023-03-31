--------------------------------------------------------------------------------
-- Title:       : Procedural version of Sphere plot in VHDL
-- Project      : EExDSA Practical Work
-- Author       : Dr. John Williams
-- Copyright    : 2019-2022 Aston University
--------------------------------------------------------------------------------
-- Purpose      : To demonstrate procedural VHDL
--------------------------------------------------------------------------------

library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use STD.textio.all;
use work.sphere_declarations.all;

entity sphere_procedural is
end;

architecture impl of sphere_procedural is
  constant outfile : string := "vga_sphere_procedural.txt";

  function sphere(x : integer; y : integer) return string is
    variable x_r   : integer;
    variable y_r   : integer;
    variable delta : integer;
    variable r     : integer;
    variable g     : integer;
    variable b     : integer;
    variable buf   : line;
  begin
    x_r := x - N_x / 2;
    y_r := y - N_y / 2;

    delta := ((x_r * x_r) + (y_r * y_r)) / 128;

    if (delta > 255) then
      delta := 255;
    end if;

    write(buf, delta);
    return buf.all;
  end function;

begin

  process
    file f : text;
    variable buf : line;
  begin
    file_open(f, outfile, write_mode);
    for y in 0 to N_y - 1 loop
      for x in 0 to N_x - 1 loop
        write(buf, sphere(x, y));
        writeline(f, buf);
      end loop;
    end loop;
    file_close(f);
    wait;
  end process;

end;
