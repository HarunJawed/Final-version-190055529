--------------------------------------------------------------------------------
-- Title:       : VGA display controller
-- Project      : EExDSA Practical Work
-- Author       : Dr. John Williams
-- Copyright    : 2019-2022 Aston University
--------------------------------------------------------------------------------
-- Purpose      : 
-- Generate sync pulses for VGA output
-- Povides column and row information for display control
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.vga.all;
use work.util.nbits;

entity vga_controller is
  port (
    sys_clk   : in  std_logic;          -- system clock
    pixel_clk : in  std_logic;          -- pixel clock
    reset     : in  std_logic;          -- asynchronous reset
    Hsync     : out std_logic;          -- Horizontal sync pulse
    Vsync     : out std_logic;          -- vertical sync pulse;
    column    : out vga_col;            -- horizontal pixel coordinate
    row       : out vga_row;            -- vertical pixel coordinate
    disp_en   : out std_logic           -- display enable ('1'=display active)
    );
end vga_controller;

architecture behaviour of vga_controller is
  constant h_period : integer
    := display.h_pulse + display.h_bp + display.h_pixels + display.h_fp;  --total number of pixel clocks in a row
  constant v_period : integer
    := display.v_pulse + display.v_bp + display.v_pixels + display.v_fp;  --total number of rows in column

  signal h_count : unsigned(nbits(h_period)-1 downto 0);  -- horizontal (column) counter
  signal v_count : unsigned(nbits(v_period)-1 downto 0);  -- vertical (row counter)

begin

  column  <= h_count;
  row     <= v_count;
  disp_en <= '1' when (h_count < display.h_pixels-1)
             and (v_count < display.v_pixels-1)
             else '0';

  -- master pixel clock driven process
  SYNC_PROC : process (sys_clk, reset)
  begin
    if reset = '1' then
      h_count <= (others => '0');         --reset horizontal counter
      v_count <= (others => '0');         --reset vertical counter
    elsif rising_edge(sys_clk) and pixel_clk = '1' then
      if (h_count < h_period - 1) then    --horizontal counter (pixels)
        h_count <= h_count + 1;
      else
        h_count <= (others => '0');
        if (v_count < v_period - 1) then  --vertical counter (rows)
          v_count <= v_count + 1;
        else
          v_count <= (others => '0');
        end if;
      end if;
    end if;
  end process;

  -- horizontal sync signal
  HS : process(h_count)
  begin
    if(h_count < display.h_pixels + display.h_fp or h_count >= display.h_pixels + display.h_fp + display.h_pulse) then
      Hsync <= not display.h_pol;       --deassert horiztonal sync pulse
    else
      Hsync <= display.h_pol;           --assert horiztonal sync pulse
    end if;
  end process;

  -- vertical sync signal
  VS : process(v_count)
  begin
    if(v_count < display.v_pixels + display.v_fp or v_count >= display.v_pixels + display.v_fp + display.v_pulse) then
      Vsync <= not display.v_pol;       --deassert vertical sync pulse
    else
      Vsync <= display.v_pol;           --assert vertical sync pulse
    end if;
  end process;

end behaviour;
