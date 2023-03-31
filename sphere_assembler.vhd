--------------------------------------------------------------------------------
-- Title:       : Assembler for sphere example instruction set
-- Project      : EExDSA Practical Work
-- Author       : Dr. John Williams
-- Copyright    : 2020--2022 Aston University
--------------------------------------------------------------------------------
-- Purpose      : 
-- Demonstration of an assembler in VHDL
-- writes instruction list to a file of std_logic_vector
--------------------------------------------------------------------------------

library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use STD.textio.all;
use IEEE.std_logic_textio.all;
use WORK.sphere_declarations.all;

entity sphere_assembler is
end;

architecture impl of sphere_assembler is

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
      load(reg_addr, 0),                -- destination address is 0

      -- max size of immediate is 6 bits (64) so we load in Nx/32 and Ny/32
      -- and then sift left by 5 to multiply by 32 to get them in registers
      load(reg_y, N_y/32),                -- y = N_y/32
      shll(reg_y, reg_y, 5),              -- y=N_y
      addi (reg_y, -1, reg_y, "y loop"),  -- y = y - 1

      load (reg_tmp_a, N_y/32),               -- tmp_a = N_y/32
      shll(reg_tmp_a, reg_tmp_a, 4),          -- tmp_a= N_y/2
      sub (reg_tmp_a, reg_y, reg_tmp_a),      -- tmp_a = y - N_y/2
      mul (reg_tmp_a, reg_tmp_a, reg_tmp_a),  -- tmp_a = (y - N_y/2)^2

      load (reg_x, N_x/32),               -- x = N_x/32
      shll(reg_x, reg_x, 5),              -- x=N_x
      addi (reg_x, -1, reg_x, "x loop"),  -- x = x - 1      

      load (reg_tmp_b, N_x/32),               -- tmp_b = N_x/32
      shll(reg_tmp_b, reg_tmp_b, 4),          -- tmp_b=N_x/2
      sub (reg_tmp_b, reg_x, reg_tmp_b),      -- tmp_b = x - N_x/2
      mul (reg_tmp_b, reg_tmp_b, reg_tmp_b),  -- tmp_b = (x - N_x/2)^2

      add (reg_tmp_b, reg_tmp_a, reg_tmp_b),  -- tmp_b = (x - N_x/2)^2 + (y - N_y/2)^2
      shrl (reg_tmp_b, reg_tmp_b, 7),  -- tmp_b = ((x - 320)^2 + (y - 240)^2) >> 7
      load (reg_tmp_c, 256/32),         -- tmp_c = 256/32
      shll(reg_tmp_c, reg_tmp_c, 5),    -- tmp_c = 256
      jmp_lt (reg_tmp_b, reg_tmp_c, "end if"),  -- if (tmp_b < tmp_c) jump to then
      load (reg_tmp_b, -1),             -- tmp_b = 255
      wb(reg_addr, reg_tmp_b, "end if"),      -- write byte out to addr

      addi(reg_addr, 1, reg_addr),      -- addr=addr+1
      jmp_nz (reg_x, "x loop"),         -- if (x != 0) jump to x loop
      jmp_nz (reg_y, "y loop"),         -- if (y != 0) jump to y loop

      halt
      );

  signal hlt : std_logic := '0';

  -- convert integer values to appropriate signed/unsigned values.
  function reg(n : integer) return regnum is
  begin
    return to_unsigned(n, regnum'length);
  end;

  function imm(n : integer) return immediate is
  begin
    return to_signed(n, immediate'length);
  end;


  -- create instruction words in standard logic vector format
  -- opcode|----|
  -- opcode|src_a|src_b|dest_reg|
  -- opcode|src_a|dest_reg|jump or immediate|
  -- opcode|---|dest_reg|immediate|

  function mk_slv (c : opcode_type)
    return instruction_word is
  begin
    return c&"000000000000";
  end function mk_slv;

  function mk_slv(c    : opcode_type; src_a : regnum; src_b : regnum;
                  dest : regnum)
    return instruction_word is
  begin
    return c&std_logic_vector(src_a)&std_logic_vector(src_b)
      &std_logic_vector(dest)&"000";
  end function mk_slv;

  function mk_slv(c   : opcode_type; src_a : regnum; dest : regnum;
                  imm : immediate)
    return instruction_word is
  begin
    return c&std_logic_vector(src_a)&std_logic_vector(dest)
      &std_logic_vector(imm);
  end function mk_slv;

  function mk_slv(c : opcode_type; dest : regnum; imm : immediate)
    return instruction_word is
  begin
    return c&"000"&std_logic_vector(dest)&std_logic_vector(imm);
  end function mk_slv;

begin

  -- process fetches and decodes instructions until halt is true
  run_proc : process
    variable ins : instruction;
    variable w   : instruction_word;
    file outfile : text;
    variable buf : line;
  begin
    file_open(outfile, rom_fname, write_mode);
    for i in ins_list'range loop
      ins := ins_list(i);

      -- Encode instructions below to match documented binary format
      -- see instruction_format document.
      case ins.op is

        when op_halt => w := mk_slv(op_halt'opc);

        when op_nop => w := mk_slv(op_nop'opc);

        when op_jmp =>
          w := mk_slv(op_jmp'opc, reg(0), reg(0),
                      imm(dest_addr(ins.jmp_dest, ins_list)));

        when op_jmp_lt =>
          w := mk_slv(op_jmp_lt'opc, reg(ins.src_a), reg(ins.src_b),
                      imm(dest_addr(ins.jmp_dest, ins_list)));

        when op_jmp_nz =>
          w := mk_slv(op_jmp_nz'opc, reg(ins.src_a), reg(0),
                      imm(dest_addr(ins.jmp_dest, ins_list)));

        when op_load =>
          w := mk_slv(op_load'opc, reg(ins.dest), imm(ins.src_b));

        when op_add =>
          w := mk_slv(op_add'opc, reg(ins.src_a),
                      reg(ins.src_b), reg(ins.dest));

        when op_sub =>
          w := mk_slv(op_sub'opc, reg(ins.src_a),
                      reg(ins.src_b), reg(ins.dest));

        when op_mul =>
          w := mk_slv(op_mul'opc, reg(ins.src_a),
                      reg(ins.src_b), reg(ins.dest));

        when op_addi =>
          w := mk_slv(op_addi'opc, reg(ins.src_a), reg(ins.dest),
                      imm(ins.src_b));

        when op_shrl =>
          w := mk_slv(op_shrl'opc, reg(ins.src_a), reg(ins.dest),
                      imm(ins.src_b));

        when op_shll =>
          w := mk_slv(op_shll'opc, reg(ins.src_a), reg(ins.dest),
                      imm(ins.src_b));

        when op_wb =>
          w := mk_slv(op_wb'opc, reg(ins.src_a), reg(ins.src_b), reg(0));

      end case;
      write(buf, w);
      writeline(outfile, buf);
    end loop;
    file_close(outfile);
    wait;

  end process;


end;
