--------------------------------------------------------------------------------
-- Title:       : Top level microprocessor structure for sphere example
-- Project      : EE4DSH Practical Work
-- Author       : Dr. John Williams
-- Copyright    : 2020--2022 Aston University
--------------------------------------------------------------------------------
-- Purpose       : Top level for sphere microprocessor synthesis
--------------------------------------------------------------------------------

library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use STD.textio.all;
use IEEE.std_logic_textio.all;
use work.julia_declarations.all;
use work.vga.all;
use work.util.all;

entity julia is
  generic (
    infile : string := "julia.bin"
    );
  port(
    sys_clk  : in  std_logic;
    reset    : in  std_logic;
    hlt      : out std_logic;
    -- VGA connector
    vgaRed   : out std_logic_vector(3 downto 0);
    vgaBlue  : out std_logic_vector(3 downto 0);
    vgaGreen : out std_logic_vector(3 downto 0);
    Hsync    : out std_logic;
    Vsync    : out std_logic
    );
end;

architecture impl of julia is
  signal clk_pixel : std_logic;         -- vga pixel clock

  -- ram control signals for display
  signal ram_write         : std_logic := '0';
  signal waddr, raddr      : ram_address   := to_unsigned(0, ram_address'length);
  signal ram_din, ram_dout : std_logic_vector(7 downto 0);

  -- vga connections
  signal disp_en : std_logic;           -- true if display is on
  signal column  : vga_col;
  signal row     : vga_row;

  -- registers between ram and display
  signal dout_i                          : std_logic_vector(7 downto 0);
  signal vgaRed_i, vgaGreen_i, vgaBlue_i : std_logic_vector(3 downto 0);

  component julia_mp is
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
  vhd_prescaler : clk_prescaler
    generic map (n => display.pixel_clk_div)
    port map(clk   => sys_clk, clk_div => clk_pixel);

  mp : julia_mp
    port map(
      clk       => sys_clk,
      reset     => reset,
      hlt       => hlt,
      mem_write => ram_write,
      addr      => waddr,
      data_out  => ram_din,
      data_in   => (others => '0')
      );
  ram1 : dual_port_ram
    generic map(dwidth => 8,
                awidth => ram_address'length,
                depth  => Npixels)
    port map (clka  => sys_clk,
              wea   => ram_write,
              addra => waddr,
              dina  => ram_din,
              clkb  => clk_pixel,
              enb   => disp_en,
              addrb => raddr,
              doutb => ram_dout);
  vgac : vga_controller
    port map(
      sys_clk => sys_clk, pixel_clk => clk_pixel, reset => '0',
      Hsync   => Hsync, Vsync => Vsync,
      row     => row, column => column,
      disp_en => disp_en);

  raddr <=
    resize(column+row*to_unsigned(display.H_PIXELS, column'length),
           raddr'length);
  -- colour map process from ram to vha
  display_proc : process(clk_pixel)
    variable delta : unsigned(3 downto 0);
  begin
    delta      := unsigned(dout_i(7 downto 4));
    if rising_edge(clk_pixel) then
      vgaRed_i   <= (others => '0');
      vgaGreen_i <= (others => '0');
      vgaBlue_i  <= (others => '0');
      if disp_en = '1' then
        -- pipelining
        dout_i     <= ram_dout;
        vgaRed     <= vgaRed_i; vgaGreen <= vgaGreen_i; vgaBlue <= vgaBlue_i;
        --color map
        vgaRed_i   <= std_logic_vector(to_unsigned(15, 4)-delta);
        vgaGreen_i <= std_logic_vector(to_unsigned(15, 4)-delta);
        vgaBlue_i  <= std_logic_vector(shift_right(delta, 1));
      end if;
    end if;
  end process;


end;
