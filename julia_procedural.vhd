--------------------------------------------------------------------------------
-- Title:       : Procedural Julia Implementation
-- Project      : EE4DSH Practical Work
-- Author       : Dr. John Williams
-- Copyright    : 2020--2022 Aston University
--------------------------------------------------------------------------------
-- Purpose       : To show write procedural programs in VHDL
--               : and provide a starting point for the design exercise
--------------------------------------------------------------------------------
-- EE4DSH 2022 Term 2
-- Name: Harun Jawed
-- Collaborators: Phil Rosario, Shiv Tailor

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use STD.textio.all;
use WORK.util.all;
use work.vga.all;

entity julia_procedural is
end;

architecture impl of julia_procedural is
  constant outfile : string   := "vga_julia_procedural.txt";  -- filename
  constant c_r     : real     := 0.36;  -- real component of c
  constant c_i     : real     := 0.10;  -- imag compoennt of c
  constant N_x     : positive := display.h_pixels;   -- Number of x pixels
  constant N_y     : positive := display.v_pixels;   -- Number of y pixels
  constant xscale  : real     := 3.2/real(N_x);   -- scaling factor for x axis
  constant yscale  : real     := 2.4/real(N_y);   -- scaling factor for y axis

  function julia(x : integer; y : integer) return integer is
    -- given coordinate x,y return the number of iterations
    -- to diverge for the Julia set for c value (c_r,c_i)
    constant d_lim : real     := 2.0 * 2.0;
    variable i     : integer  := 255;
    variable z_r   : real     := xscale * real(x-N_x/2);
    variable z_i   : real     := yscale * real(y-N_y/2);
    variable t_r   : real     := 0.0;
    variable t_i   : real     := 0.0;
  begin
    while (((z_r * z_r) + (z_i * z_i)) < d_lim) and (i >0) loop
      i   := i - 1;
      t_r := z_r;
      t_i := z_i;
      z_r := t_r * t_r - t_i * t_i + c_r;
      z_i := 2.0 * (t_r * t_i) + c_i;
    end loop;
    return i;
  end function;

begin
  process
    file f       : text;
    variable buf : line;
  begin
    file_open(f, outfile, write_mode);
    for y in N_y-1 downto 0 loop
      for x in N_x-1 downto 0 loop
        write(buf, julia(x, y));
        writeline(f, buf);
      end loop;
    end loop;
    file_close(f);
    wait;
  end process;
end;
