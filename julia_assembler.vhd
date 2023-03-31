--------------------------------------------------------------------------------
-- Title:       : Assembler for sphere example instruction set
-- Project      : EE4DSH Practical Work
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
use WORK.julia_declarations.all;

entity julia_assembler is
end;

architecture impl of julia_assembler is

   -- constants
  constant n_lim  : integer := 255;     -- max iterations
  constant c_r    : real    := 0.36;    -- julia real and imag params
  constant c_i    : real    := 0.1;
  constant xscale : real    := 3.2/real(N_x);
  constant yscale : real    := 2.4/real(N_y);
  constant d_lim  : real    := 2.0*2.0;
  constant N_x_2  : integer := (N_x/2); -- halfs the screen resolution (horizontal axis)
  constant N_y_2  : integer := (N_y/2); -- halfs the screen resolution (vertical axis) 

  -- declare registers used.
  constant reg_addr      : integer := 0;
  constant reg_x         : integer := 1;
  constant reg_y         : integer := 2; 
  constant reg_i         : integer := 3;
  constant reg_tmp_xscale   : integer := 4; 
  constant reg_tmp_yscale   : integer := 5;  
  constant reg_z_real    : integer := 6;
  constant reg_z_imag    : integer := 7;
  constant reg_tmp_real : integer := 8;
  constant reg_tmp_imag : integer := 9;
  constant reg_zr    : integer := 10;
  constant reg_zi    : integer := 11;
  constant reg_z_ri 	 : integer := 12;
  constant reg_dlim	 : integer := 13;

  -- our program in assembler.
  constant ins_list : instruction_vector :=
    (
      -- In assembler we are going to write to memory  instead of
      -- directly to a file so we need a register to hold the current
      -- address to be written to

      load(reg_addr, 0),                      -- #1 load reg memory address destination
	

      -- HINT: you may wish to load the xscale and yscale constants
      -- into registers here as they are used on every loop iteration
      -- Don't forget to correctly scale the values to your fractional
      -- Arithmetic format.

      load(reg_tmp_xscale, FxP(xscale)),	-- #2 Load reg_tmp_xscale in register as fixed point
      load(reg_tmp_yscale, FxP(yscale)),	-- #3 Load reg_tmp_xscale in register as fixed point
  
      -- Procedural -- for y in 0 to N_y - 1 loop
      -- In assembler it is easier and more idiomatic to wound down to 0
      -- If you use longer instructions you won't need to load and shift
      -- as in the sphere example

      load(reg_y, N_y), 			--#4 load Number of y pixels into reg_y
      addi(reg_y, -1, reg_y, "y loop"), 	--#5 substract -1

       -- Procedural: for x in 0 to N_x - 1 loop

      load(reg_x, N_x), 			--#6 load Number of y pixels into reg_y
      addi (reg_x, -1, reg_x, "x loop"), 	--#7 substract -1

      -- HINT: Calculate z_r and z_i and  store in registers
      
      load(reg_zr, N_x_2), 			--#8 Load constant for calculations
      sub(reg_zr, reg_x, reg_zr), 		--#9 sub reg_x from reg_zr  
      mul(reg_z_real, reg_tmp_xscale, reg_zr), --#10 multiplying to finish cal(x): xscale * real(x-N_x/2)

      load(reg_zi, N_y_2), 			--#11 Load constant for calculations
      sub(reg_zi, reg_y, reg_zi), 		--#12 sub reg_y from reg_zi 
      mul(reg_z_imag, reg_tmp_yscale, reg_zi), -- '' #13 multiplying to finish cal(y): yscale * real(y-N_y/2)
      
      --Procedural: variable i     : integer  := 255;
      -- HINT: Initialise a register for i to 255 (n_lim) so you can count
      -- down number of iterations
      
      load(reg_i, n_lim), 			--#14 initialising reg by loading n_lim in


           
      -- PROCEDURAL: while ....
      -- HINT: Use a label to denote start of loop so we can jump back here
      -- Use registers to calculate (((z_r * z_r) + (z_i * z_i))
      -- I suggest keeping zr*zr and zi*zi as we will reuse these later
      -- in you fractional arithmetic format

      fixed_mul(reg_zr, reg_z_real, reg_z_real, "i loop")  --#15 stores z_r * z_r in reg_zr
      fixed_mul(reg_zi, reg_z_imag, reg_z_imag),	   --#16 stores z_i * z_i in reg_zi 
      

      -- PROCEDURAL:  (((z_r * z_r) + (z_i * z_i)) < d_lim)
      -- HINT: Load a register with d_lim and then test and
      
      load(reg_dlim, FxP(d_lim)),			--#17 stores d_lim as fixed point to reg_dlim
      add(reg_z_ri , reg_zr, reg_zi),			--#18 stores (z_r * z_r) + (z_i * z_i) in reg_z_ri
      

      
      -- jump out of loop if we are finished - this is idiomatic assembler
      
      jmp_lt(reg_dlim, reg_z_ri , "end i loop"),	--#19 if reg_z_ri < reg_dlim jumps to the end of the loop     

      
      -- HINT: Calculate zr*zr-zi*zi and store in a register here
      
      sub(reg_zr, reg_zr, reg_zi),			--#20 store zr*zr-zi*zi in reg_zr, free's reg_zi
      
      -- this frees up a register we can reuse.
  
      -- PROCEDURAL:    t_r := z_r; t_i := z_i;
      
      addi(reg_tmp_real, 0, reg_z_real),		-- t_r := z_r; #19
      addi(reg_tmp_imag, 0, reg_z_imag),		-- t_i := z_i; #20
  
      -- PROCEDURAL: z_r := z_r * z_r - z_i * z_i + c_r;
       -- z_r := z_r * z_r - z_i * z_i + c_r;
       
       addi(reg_z_real, FxP(c_r), reg_zr),		--#21 storing (z_r * z_r - z_i * z_i) + c_r in reg_z_real
  
       -- z_i := 2.0 * (t_r * t_i) + c_i;
       
       fixed_mul(reg_zr, reg_tmp_real, reg_tmp_imag),	--#22 storing t_r * t_i in reg_zr
       add(reg_zr, reg_zr, reg_zr),			--#23 add reg_zr to reg_zr (multiplying by 2)
       addi(reg_z_imag, FxP(c_i), reg_zr),		--#24 add dixed c_i to reg_zr
       							
	
      -- Procedural: i=i-1
      
      addi(reg_i, -1, reg_i),						
      
      -- Then jump back to beginning of loop if nz

      
      jmp_nz(reg_i, "i loop"),				--#25 once loop finishes,jumps to the start

      -- Write i out to memory loop, inc
      wb(reg_addr, reg_i, "end i loop"),  		--#26 write (reg_i)byte out to addr
      addi(reg_addr, 1, reg_addr),        		--#27 add +1 to addr

      jmp_nz(reg_x, "x loop"),				--#28 jump to x loop
      jmp_nz(reg_y, "y loop"),          		--#29 jump to y loop
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
    return c&"00000000000000000000000000"; --18 bits
  end function mk_slv;

  function mk_slv(c    : opcode_type; src_a : regnum; src_b : regnum;
                  dest : regnum)
    return instruction_word is
  begin
    return c&std_logic_vector(src_a)&std_logic_vector(src_b)
      &std_logic_vector(dest)&"00000000000";
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
    return c&"00000"&std_logic_vector(dest)&std_logic_vector(imm);
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
          
        when op_jmp_eq =>
          w := mk_slv(op_jmp_nz'opc, reg(ins.src_a), reg(ins.src_b),
                      imm(dest_addr(ins.jmp_dest, ins_list)));

        when op_fixed_load =>
          w := mk_slv(op_fixed_load'opc, reg(ins.dest), imm(ins.src_b));
          
        when op_fixed_mul =>
          w := mk_slv(op_fixed_mul'opc, reg(ins.src_a),
                      reg(ins.src_b), reg(ins.dest)); 
          
      end case;
      write(buf, w);
      writeline(outfile, buf);
    end loop;
    file_close(outfile);
    wait;

  end process;


end;
