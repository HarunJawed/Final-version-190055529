--------------------------------------------------------------------------------
-- Title:       : Package with common declarations
-- Project      : EE4DSA Practical Work
-- Author       : Dr. John Williams
-- Copyright    : 2019-2022 Aston University
--------------------------------------------------------------------------------
-- Purpose      : Package providing vga declarations for EExDSA
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use work.util.nbits;

package vga is

  type vga_timing_t is record
    h_pixels      : integer;
    h_fp          : integer;
    h_pulse       : integer;
    h_bp          : integer;
    v_pixels      : integer;
    v_fp          : integer;
    v_pulse       : integer;
    v_bp          : integer;
    h_pol         : std_logic;
    v_pol         : std_logic;
    pixel_clk_div : integer;
  end record;

  -- these resolutions are chosen as the pixel clock is close to integer
  -- fraction of 100MHz system clock
  constant vga640x350 : vga_timing_t :=
    (h_pixels      => 640, h_fp => 16, h_pulse => 96, h_bp => 48,
     v_pixels      => 350, v_fp => 37, v_pulse => 2, v_bp => 60,
     h_pol         => '1', v_pol => '0',
     pixel_clk_div => 4);

  constant vga640x400 : vga_timing_t :=
    (h_pixels      => 640, h_fp => 16, h_pulse => 96, h_bp => 48,
     v_pixels      => 400, v_fp => 12, v_pulse => 2, v_bp => 35,
     h_pol         => '0', v_pol => '1',
     pixel_clk_div => 4);

   constant vga640x480 : vga_timing_t :=
    (h_pixels      => 640, h_fp => 16, h_pulse => 96, h_bp => 48,
     v_pixels      => 480, v_fp => 10, v_pulse => 2, v_bp => 33,
     h_pol         => '0', v_pol => '0',
     pixel_clk_div => 4);

  constant vga800x600 : vga_timing_t :=
    (h_pixels      => 800, h_fp => 56, h_pulse => 120, h_bp => 64,
     v_pixels      => 600, v_fp => 37, v_pulse => 6, v_bp => 23,
     h_pol         => '1', v_pol => '1',
     pixel_clk_div => 2);

  constant vga160x8test : vga_timing_t :=
    (h_pixels      => 160, h_fp => 16, h_pulse => 96, h_bp => 48,
     v_pixels      => 8, v_fp => 37, v_pulse => 2, v_bp => 60,
     h_pol         => '1', v_pol => '0',
     pixel_clk_div => 4);

  constant display : vga_timing_t := vga640x480;

  -- video ram derived values
  constant VRAM_DEPTH  : integer := display.H_PIXELS*display.V_PIXELS;
  constant COLOR_DEPTH : integer := 6;  -- 2 per each RGB
  subtype vga_row is unsigned(nbits(display.v_pulse + display.v_bp + display.v_pixels + display.v_fp)-1 downto 0);
  subtype vga_col is unsigned(nbits(display.h_pulse + display.h_bp + display.h_pixels + display.h_fp)-1 downto 0);
  subtype vga_addr is unsigned(nbits(VRAM_DEPTH)-1 downto 0);
  subtype vga_pixel is std_logic_vector(5 downto 0);

  component vga_controller is
    port (
      sys_clk   : in  std_logic;        -- system clock
      pixel_clk : in  std_logic;        -- pixel clock
      reset     : in  std_logic;        -- asynchronous reset
      Hsync     : out std_logic;        -- Horizontal sync pulse
      Vsync     : out std_logic;        -- vertical sync pulse;
      column    : out vga_col;          -- horizontal pixel coordinate
      row       : out vga_row;          -- vertical pixel coordinate
      disp_en   : out std_logic         -- display enable ('1'=display active)
      );
  end component;

  component vga_pattern_generator is
    port (
      clk                      : in  std_logic;  -- clock to update pattern
      data_in                  : in  std_logic_vector(15 downto 0);  -- pattern or color input
      load_pattern, load_color : in  std_logic;  --  update pattern or color
      refresh                  : in  std_logic;
      valid                    : out std_logic;  -- false if ram is being updated
      addr                     : out vga_addr;   -- ram address
      data_out                 : out vga_pixel
      );
  end component;

end package;

