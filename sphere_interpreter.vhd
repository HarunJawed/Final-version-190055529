--------------------------------------------------------------------------------
-- Title:       : Simulated interpreter for assembler instructions
-- Project      : EExDSA Practical Work
-- Author       : Dr. John Williams
-- Copyright    : 2020--2022 Aston University
--------------------------------------------------------------------------------
-- Purpose      : 
-- To demonstrate assembler interpreter
-- Finished in 4201747 clock cycles.
--------------------------------------------------------------------------------


library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use STD.textio.all;
use IEEE.std_logic_textio.all;
use work.sphere_declarations.all;

entity sphere_interpreter is
end;

architecture impl of sphere_interpreter is
  constant outfile : string   := "vga_sphere_interpreter.txt";
  constant debug   : boolean  := false;
  constant max_ins : positive := 60;

  -- write a string to buffer. Gets around the problem that quoted arrays
  -- of characters can represent std_log_vectors or strings and therefore
  -- cannot be differentiated by the write function.
  procedure swrite(L         : inout line; VALUE : in string;
                   JUSTIFIED : in    side := right; FIELD : in WIDTH := 0) is
  begin
    write(L, string'(value), justified, field);
  end swrite;

  -- return an op code name for debugging
  function op_name(op : in opcode) return string is
  begin
    case op is
      when op_halt   => return "halt";
      when op_nop    => return "nop";
      when op_jmp    => return "jmp";
      when op_jmp_lt => return "jmp_lt";
      when op_jmp_nz => return "jmp_nz";
      when op_load   => return "load";
      when op_add    => return "add";
      when op_addi   => return "addi";
      when op_sub    => return "sub";
      when op_mul    => return "mul";
      when op_shrl   => return "shrl";
      when op_shll   => return "shll";
      when op_wb     => return "wb";
    end case;
  end op_name;

  --  print out instructions and registers
  procedure log_ins(pc : integer; ins : instruction) is
    variable buf : line;
  begin
    -- print instruction label if it is present
    if not(ins.lbl(1) = ' ') then
      write(buf, ins.lbl);
      write(buf, LF);
    end if;
    write(buf, pc);
    swrite(buf, " : ");
    write(buf, op_name(ins.op));
    swrite(buf, "(");
    write(buf, ins.dest); swrite(buf, ",");
    write(buf, ins.src_a); swrite(buf, ",");
    write(buf, ins.src_b);
    if not(ins.jmp_dest(1) = ' ') then
      swrite(buf, ",");
      write(buf, ins.jmp_dest);
    end if;
    swrite(buf, ")");
    writeline(OUTPUT, buf);
  end log_ins;

  --  print out registers
  procedure log_reg(regs : register_vector) is
    variable buf : line;
  begin
    for i in regs'range loop
      write(buf, regs(i), right, 8);
    end loop;
    writeline(OUTPUT, buf);
  end log_reg;

  -- declare registers used.
  constant reg_y     : integer := 0;
  constant reg_x     : integer := 1;
  constant reg_tmp_a : integer := 2;
  constant reg_tmp_b : integer := 3;
  constant reg_tmp_c : integer := 4;
  constant reg_addr  : integer := 5;

  -- our program in assembler.
  constant ins_list : instruction_vector :=
    (
      -- In assembler we are going to write to memory  instead of
      -- directly to a file so we need a register to hold the current
      -- address to be written to
      load(reg_addr, 0),                -- destination address is 0

      -- Procedural -- for y in 0 to N_y - 1 loop
      -- In assembler it is easier and more idiomatic to wound down to 0
      -- So we initialise reg_y with N_y, subract 1 and then at end of the opp
      -- can use a jmp_nz to test reg_y and jump back if not 0 - simarly for 

      -- Since max size of immediate is 6 bits (64) so we load in Nx/32 and Ny/32
      -- and then sift left by 5 to multiply by 32 to get them in registers
      load(reg_y, N_y/32),                -- y = N_y/32
      shll(reg_y, reg_y, 5),              -- y=N_y
      addi (reg_y, -1, reg_y, "y loop"),  -- y = y - 1

      -- Procedural: y_r=y-N_y/2
      -- we use reg_tmp_a to store y_r and again have to load and shift
      load (reg_tmp_a, N_y/32),               -- tmp_a = N_y/32
      shll(reg_tmp_a, reg_tmp_a, 4),          -- tmp_a= N_y/2
      sub (reg_tmp_a, reg_y, reg_tmp_a),      -- tmp_a = y - N_y/2

      -- Procedural: y_r * y_r
      mul (reg_tmp_a, reg_tmp_a, reg_tmp_a),  -- tmp_a = (y - N_y/2)^2

      -- Procedural: for x in 0 to N_x - 1 loop
      -- Similar to y loop
      load (reg_x, N_x/32),               -- x = N_x/32
      shll(reg_x, reg_x, 5),              -- x=N_x
      addi (reg_x, -1, reg_x, "x loop"),  -- x = x - 1      

      -- Procedural:  x_r := x - N_x / 2;
      -- we use reg_tmp_b to store x_r
      load (reg_tmp_b, N_x/32),               -- tmp_b = N_x/32
      shll(reg_tmp_b, reg_tmp_b, 4),          -- tmp_b=N_x/2
      sub (reg_tmp_b, reg_x, reg_tmp_b),      -- tmp_b = x - N_x/2

      -- Procedural: x_r*x_r
      mul (reg_tmp_b, reg_tmp_b, reg_tmp_b),  -- tmp_b = (x - N_x/2)^2

      -- Procedural: delta := ((x_r * x_r) + (y_r * y_r)) / 128;
      -- we reuse reg_tmp_b to store delta as we do not need to retain
      -- it's previous value - this reuse of registers is idiomatic in assember
      add (reg_tmp_b, reg_tmp_a, reg_tmp_b),  -- tmp_b = (x - N_x/2)^2 + (y - N_y/2)^2
      shrl (reg_tmp_b, reg_tmp_b, 7),  -- tmp_b = ((x - 320)^2 + (y - 240)^2) >> 7
      -- Procedural: If delta>255 then
      -- In assembler we have a jmp_lt (<)
      -- so use this to test the oposite condition and then jump over the
      -- conditional code - very idiomatic assembler
      -- We first load 256 into reg_tmp_c so we can do comparison
      load (reg_tmp_c, 256/32),         -- tmp_c = 256/32
      shll(reg_tmp_c, reg_tmp_c, 5),    -- tmp_c = 256
      jmp_lt (reg_tmp_b, reg_tmp_c, "end if"),  -- if (tmp_b < tmp_c) jump to then
      -- Procedural: delta=255
      load (reg_tmp_b, -1),             -- tmp_b = 255

      --Procedural: write(buf,delta)
      -- In assembler we write to a memory address and then increment the address
      wb(reg_addr, reg_tmp_b, "end if"),      -- write byte out to addr
      addi(reg_addr, 1, reg_addr),      -- addr=addr+1

      -- Procedural: End loop
      jmp_nz (reg_x, "x loop"),         -- if (x != 0) jump to x loop
      -- Procedural: End loop
      jmp_nz (reg_y, "y loop"),         -- if (y != 0) jump to y loop

      -- Need halt at end to stop process
      halt
      );

  signal hlt : std_logic := '0';

begin

  -- process fetches and decodes instructions until halt is true
  -- or maximum instruction count exceeded.
  run_proc : process
    variable pc      : integer                 := 0;
    variable ins     : instruction;
    variable ins_cnt : integer                 := 0;
    variable reg     : register_vector(0 to num_reg-1) := (others => 0);
    variable ram     : memory(0 to N_x*N_y-1)  := (others => (others => '0'));
    variable buf     : line;
  begin
    while hlt = '0' and (not(debug) or ins_cnt < max_ins) loop

      ins_cnt := ins_cnt + 1;
      ins     := ins_list(pc);

      if debug then
        log_ins(pc, ins);
      end if;

      case ins.op is

        when op_halt =>
          hlt <= '1';

        when op_nop =>

        when op_jmp =>
          pc := dest_addr(ins.jmp_dest, ins_list) - 1;

        when op_jmp_lt =>
          if reg(ins.src_a) < reg(ins.src_b) then
            pc := dest_addr(ins.jmp_dest, ins_list) - 1;
          end if;

        when op_jmp_nz =>
          if reg(ins.src_a) /= 0 then
            pc := dest_addr(ins.jmp_dest, ins_list) - 1;
          end if;

        when op_load =>
          reg(ins.dest) := ins.src_b;

        when op_add =>
          reg(ins.dest) := reg(ins.src_a) + reg(ins.src_b);

        when op_addi =>
          reg(ins.dest) := reg(ins.src_a) + ins.src_b;

        when op_sub =>
          reg(ins.dest) := reg(ins.src_a) - reg(ins.src_b);

        when op_mul =>
          reg(ins.dest) := reg(ins.src_a) * reg(ins.src_b);

        when op_shrl =>
          reg(ins.dest) := reg(ins.src_a) / (2 ** ins.src_b);

        when op_shll =>
          reg(ins.dest) := reg(ins.src_a) * (2 ** ins.src_b);

        when op_wb =>
          -- if out of memory bounds output registers and stop
          if reg(ins.src_a) > ram'high then
            log_reg(reg);
          end if;
          assert
            reg(ins.src_a) <= ram'high+1
            report "Address out of memory bounds" severity error;

          ram(reg(ins.src_a)) :=
            std_logic_vector(to_signed(reg(ins.src_b), 16)(7 downto 0));

      end case;

      if debug then
        log_reg(reg);
      end if;

      wait for 10 ns;  -- helps for using waveform analysis debugging.
      pc := pc + 1;

    end loop;

    report "Finished in "&integer'image(ins_cnt)&" instructions.";
    memdump(outfile, ram);
    wait;

  end process;


end;
