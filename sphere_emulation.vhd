--------------------------------------------------------------------------------
-- Title:       : Emulated processing of binary instructions for sphere example
-- Project      : EExDSA Practical Work
-- Author       : Dr. John Williams
-- Copyright    : 2020--2022 Aston University
--------------------------------------------------------------------------------
-- Purpose      :
-- To demonstrate emulated microprocessor using rom
-- read from file and signals.
--------------------------------------------------------------------------------

library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use STD.textio.all;
use IEEE.std_logic_textio.all;
use work.sphere_declarations.all;
use work.util.all;

entity sphere_emulation is
end;

architecture impl of sphere_emulation is
  constant outfile: string:="vga_sphere_emulation.txt";

  constant clk_period : time := 10 ns;
  constant debug   : boolean  := false;
  constant max_ins : positive := 60;

  subtype rom_type is instruction_memory(0 to 127);

  impure function InitRomFromFile (RomFileName : in string)
    return rom_type is
    file RomFile : text open read_mode is RomFilename;
    variable buf : line;
    variable rom : rom_type := (others => (others => '0'));
  begin
    for i in rom_type'range loop
      if not(endfile(RomFile)) then
        readline (RomFile, buf);
        read (buf, rom(i));
      end if;
    end loop;
    return rom;
  end function;

  constant rom : rom_type := InitRomFromFile(rom_fname);

  signal hlt : std_logic                              := '0';
  signal clk : std_logic                              := '0';
  signal pc  : unsigned(15 downto 0) := (others => '0');
  signal reg : register_file(0 to num_reg-1)
    := (others => to_signed(0, word'length));
  signal ram : memory(0 to N_x*N_y-1) := (others => (others => '0'));

  signal ins    : instruction_word := rom(0);
  signal opcode : opcode_type;
  signal rr1    : natural;
  signal rr2    : natural;
  signal wr     : natural;
  signal imm    : immediate;

  -- write a string to buffer - gets around generic "write" function issue
  -- which cannot differentate between string or standard_logic_vector constant
  procedure swrite(L         : inout line; VALUE : in string;
                   JUSTIFIED : in    side := right; FIELD : in WIDTH := 0) is
  begin
    write(L, string'(value), justified, field);
  end swrite;

  --  print out registers
  procedure log_reg is
    variable buf : line;
  begin
    for i in reg'range loop
      write(buf, to_integer(reg(i)), right, 8);
    end loop;
    writeline(OUTPUT, buf); -- OUTPUT is standard output.
  end log_reg;

  -- print out instruction components
  procedure log_ins is
    variable buf : line;
  begin
    write(buf, to_integer(pc));
    swrite(buf, " : ");
    write(buf,ins);     swrite(buf, " : ");
    write(buf, op_name(opcode));
    swrite(buf, "( rr1=");
    write(buf, rr1); swrite(buf, ", rr2=");
    write(buf, rr2); swrite(buf, ", wr=");
    write(buf, wr); swrite(buf, ", imm=");
    write(buf, to_integer(imm)); swrite(buf, ")");
    writeline(OUTPUT, buf);
  end log_ins;

begin

  -- decode instructions into fields - opcode, rr1, rr2, wr and imm
  ins    <= rom(to_integer(pc));
  opcode <= ins(15 downto 12);
  rr1    <= to_integer(unsigned(ins(11 downto 9)));
  rr2    <= to_integer(unsigned(ins(8 downto 6)));
  wr     <= to_integer(unsigned(ins(5 downto 3)));
  imm    <= signed(ins(5 downto 0));

  -- generate clock until halt instruction is reached
  clk_proc : process
    variable ins_cnt : natural;         -- count instructions
  begin
    ins_cnt := 0;
    while hlt = '0' and (not(debug) or ins_cnt < max_ins) loop
      clk     <= '0'; wait for clk_period/2;
      clk     <= '1'; wait for clk_period/2;
      ins_cnt := ins_cnt+1;
    end loop;

    report "Finished in "&integer'image(ins_cnt)&" instructions.";
    memdump(outfile, ram);
    wait;
  end process clk_proc;

  -- process fetches and decodes instructions until halt is true
  -- or maximum instruction count exceeded.
  run_proc : process(clk)
  begin

    if rising_edge(clk) then

      -- output debugging info
      if debug then
        log_reg;
        log_ins;
      end if;

      pc <= pc+1;

      case opcode is
        when op_halt'opc =>
          hlt <= '1';
          pc  <= pc;

        when op_nop'opc =>

        when op_jmp'opc => pc <= resize(unsigned(imm),pc'length);

        when op_jmp_lt'opc =>
          if reg(rr1) < reg(rr2) then
            pc <= resize(unsigned(imm),pc'length);
          end if;

        when op_jmp_nz'opc =>
          if reg(rr1) /= 0 then
            pc <= resize(unsigned(imm),pc'length);
          end if;

        -- note load instruction uses rr2 field for destination
        when op_load'opc => reg(rr2) <= resize(imm, word'length);

        when op_add'opc => reg(wr) <= reg(rr1)+reg(rr2);

        when op_sub'opc => reg(wr) <= reg(rr1)-reg(rr2);

        when op_mul'opc => reg(wr) <= resize(reg(rr1)*reg(rr2), word'length);

        when op_addi'opc => reg(rr2) <= reg(rr1)+resize(imm, word'length);

        when op_shrl'opc =>
          reg(rr2) <= shift_right(reg(rr1), to_integer(unsigned(imm)));

        when op_shll'opc =>
          reg(rr2) <= shift_left(reg(rr1), to_integer(unsigned(imm)));

        when op_wb'opc =>
          if reg(rr1) > ram'high then
            log_reg;
          end if;
          assert
            reg(rr1) <= ram'high+1
            report "Address out of memory bounds" severity error;

          ram(to_integer(reg(rr1))) <= std_logic_vector(reg(rr2)(7 downto 0));

        when others =>
          report "Unknown instruction" severity error;
      end case;

    end if;

  end process run_proc;


end;
