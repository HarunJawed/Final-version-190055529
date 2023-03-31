--------------------------------------------------------------------------------
-- Title:       : julia_mp testbench
-- Project      : EE4DSH Practical Work
-- Author       : Dr. John Williams
-- Copyright    : 2020--2022 Aston University
--------------------------------------------------------------------------------
-- Purpose      : 
-- Testbench runs julia_mp in simulation
-- allowing debugging.
--------------------------------------------------------------------------------
-- EE4DSH 2022 Term 2
-- Name: Harun Jawed
-- Collaborators: Phil Rosario, Shiv Tailor

library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use STD.textio.all;
use IEEE.std_logic_textio.all;
use work.julia_declarations.all;
use work.util.all;

entity julia_testbench is
end;

architecture impl of julia_testbench is
  constant outfile    : string   := "vga_julia_testbench.txt";
  constant clk_period : time     := 10 ns;
  constant debug      : boolean  := true;
  constant max_ins    : positive := 60;
  -- comment these out to enable debugging output
  --constant debug      : boolean  := true;
  --constant Npixels    : positive := 60;  -- for debugging

  -- flow signals
  signal hlt     : std_logic := '0';
  signal sys_clk : std_logic := '0';
  signal reset   : std_logic := '1';

  -- ram control signals for display
  signal ram_write, ram_read : std_logic   := '0';
  signal addr, ram_ab        : ram_address := (others => '0');
  signal ram_din, ram_dout   : std_logic_vector(7 downto 0);
  -- write a string to buffer.

  component julia_mp is
    generic (
      infile : string;
      debug  : boolean
      );
    port (
      clk       : in  std_logic;
      reset     : in  std_logic;
      hlt       : out std_logic;
      mem_write : out std_logic;
      addr      : out ram_address;
      data_out  : out std_logic_vector(7 downto 0);
      mem_read  : out std_logic;
      data_in   : in  std_logic_vector(7 downto 0) := (others => '0')
      );
  end component julia_mp;

begin

  mp : julia_mp
    generic map (
      infile => rom_fname,
      debug  => debug
      )
    port map(
      clk       => sys_clk,
      reset     => reset,
      hlt       => hlt,
      mem_write => ram_write,
      addr      => addr,
      data_out  => ram_din);

  ram1 : dual_port_ram
    generic map(dwidth => 8,
                awidth => ram_address'length,
                depth  => Npixels)
    port map (clka  => sys_clk,
              wea   => ram_write,
              addra => addr,
              dina  => ram_din,
              clkb  => sys_clk,
              enb   => ram_read,
              addrb => ram_ab,
              doutb => ram_dout);

  -- generate clock until halt instruction is reached
  clk_proc : process
    variable ins_cnt : natural;         -- count instructions
  begin
    ins_cnt  := 0;
    -- assert reset for a clock cycle
    reset    <= '1';
    ram_read <= '0';
    while hlt = '0' and (not(debug) or (ins_cnt < max_ins)) loop
      sys_clk <= '0'; wait for clk_period/2;
      sys_clk <= '1'; wait for clk_period/2;
      ins_cnt := ins_cnt+1;
      reset   <= '0';
    end loop;
    -- extra clock cycle finish write to ram.
    sys_clk <= '0'; wait for clk_period/2;
    sys_clk <= '1'; wait for clk_period/2;
    report "Finished in "&integer'image(ins_cnt)&" instructions.";
    if not(debug) then
      ram_read <= '1';
      ramdump(fname => outfile, n => Npixels,
              clk   => sys_clk, addr => ram_ab, data => ram_dout);
    end if;
    wait;
  end process clk_proc;

end;
