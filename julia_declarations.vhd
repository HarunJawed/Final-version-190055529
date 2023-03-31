--------------------------------------------------------------------------------
-- Title        : Common Declarations for julia microprocessor
-- Project      : EE4DSH Practical Work
-- Author       : Dr. John Williams
-- Copyright    : 2020--2022 Aston University
--------------------------------------------------------------------------------
-- Purpose      :
-- Student Declarations template for EE3DSA Julia example.
--------------------------------------------------------------------------------
-- Comments:
-- Suggestions Where additional VHDL may be needed will be
-- marked with a comment starting with TODO:
-- Values which students must make decisions on and complete are marked <??>
-- and the lines will be commented out
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;
use work.vga.all;
use STD.textio.all;
use IEEE.std_logic_textio.all;

package julia_declarations is
  -- Common constants
  -- screen dimensions from display
  constant N_x     : positive := display.h_pixels;
  constant N_y     : positive := display.v_pixels;

  -- constant N_x     : positive := 10;
  -- constant N_y     : positive := 10;
  
  -- TODO:
  constant Npixels : positive := N_x*N_y;

  constant fxp_base : integer := 12;   -- fixed point scaling as power of 2

  function FxP(x     : real) return integer;  -- convert real to fixed point

  -- INTERPRETER
  -- abstract types for instruction set
  -- types for representing opcodes etc also for representing
  -- instruction, data storage and registers;
  -- in abstract types.
  -- uses variables and a loop
  
  -- TODO:
  constant num_reg : positive := 14; -- the number of registers in architecture
  
  type opcode is (op_halt, op_nop, op_jmp, op_jmp_lt, op_jmp_eq, op_jmp_nz,
                  op_load, op_fixed_load, op_add, op_addi, op_sub, op_mul, op_fixed_mul, op_shrl,
                  op_shll, op_wb);-- opcodes for additional instructions

  subtype lbl_string is string(1 to 10);

  -- function converts a string to a labl_string.
  function lbl(s : string) return lbl_string;

  constant none : lbl_string := lbl("");

  type instruction is record
    op       : opcode;
    src_a    : integer;                 -- src reg a
    src_b    : integer;                 -- src reg b  or an immediate value
    dest     : integer;                 -- dest reg
    jmp_dest : lbl_string;              -- jump destination label for jmp
    lbl      : lbl_string;              -- optional label
  end record;

  -- types for simulating processor storage
  type instruction_vector is array (natural range <>) of instruction;
  type memory is array (natural range <>) of std_logic_vector(7 downto 0);
  type register_vector is array (natural range <>) of integer;

  -- dump memory to file
  constant rom_fname: string :="julia.rom";
  procedure memdump(fname : string; ram : memory);
  procedure ramdump(fname       :     string; n : integer;
                    signal clk  : out std_logic;
                    signal addr : out unsigned;
                    signal data : in  std_logic_vector);

  -- return absolute position of labeled instruction in instruction vector
  function dest_addr(lb : lbl_string; v : instruction_vector) return integer;

  -- functions to create instruction records for each instruction
  function halt(lb      : string := "") return instruction;
  function nop(lb       : string := "") return instruction;
  function jmp(jmp_dest : string) return instruction;
  function jmp_lt(reg_a : integer; reg_b : integer; jmp_dest : string)
    return instruction;
  function jmp_eq(reg_a : integer; reg_b : integer; jmp_dest : string)
    return instruction;
  function jmp_nz(reg_a : integer; jmp_dest : string) return instruction;
  function load(reg_d   : integer; v : integer; lb : string := "")
    return instruction;
  function fixed_load(reg_d : integer; v : integer; lb : string := "")
    return instruction;
  function mv(reg_d : integer; reg_s : integer; lb : string := "")
    return instruction;
  function addi(reg_d : integer; v : integer; reg_a : integer;
                lb    : string := "")
    return instruction;
  function add(reg_d : integer; reg_a : integer; reg_b : integer;
               lb    : string := "")
    return instruction;
  function sub(reg_d : integer; reg_a : integer; reg_b : integer;
               lb    : string := "")
    return instruction;
  function mul(reg_d : integer; reg_a : integer; reg_b : integer;
               lb    : string := "")
    return instruction;
  function fixed_mul(reg_d : integer; reg_a : integer; reg_b : integer;
                lb    : string := "")
    return instruction;
  function shrl(reg_d : integer; reg_a : integer; imm : natural;
                lb    : string := "")
    return instruction;
  function shll(reg_d : integer; reg_a : integer; imm : natural;
                lb    : string := "")
    return instruction;
  function wb(reg_addr : integer; reg_v : integer; lb : string := "")
    return instruction;
  -- TODO:
  -- Add in function declarations for any additional instructions your need here
  -- and implement them in package body.

  subtype instruction_word is std_logic_vector(31 downto 0);
  subtype address is unsigned(31 downto 0);


  -- 
  -- ASSEMBLER
  -- mapping abstract types to concrete binary types
  -- opcodes and instruction formats in std_logic
  -- declarations for concrete types
  -- we have 32 bit instructions,

  -- TODO:

  subtype word is signed(31 downto 0);
  subtype halfword is signed(15 downto 0);
  subtype byte is signed(7 downto 0);
  subtype ram_address is unsigned(31 downto 0);  -- same width as reg
  -- instruction subcomponents
  -- TODO:
  subtype regnum is unsigned(4 downto 0);  -- 5 bits for registers
  subtype immediate is halfword;           -- immediate or jump data is 16 bits
  -- TODO:
  -- define our opcodes in 6 bits (for future expansion - only 4 bits necessary).
  subtype opcode_type is std_logic_vector(5 downto 0);
  attribute opc : opcode_type;

  attribute opc of op_nop    : literal is "000000";
  attribute opc of op_halt   : literal is "000001";
  attribute opc of op_jmp    : literal is "000010";
  attribute opc of op_jmp_lt : literal is "000011";
  attribute opc of op_jmp_eq : literal is "000100";
  attribute opc of op_jmp_nz : literal is "000101";
  attribute opc of op_load   : literal is "000110";
  attribute opc of op_add    : literal is "000111";
  attribute opc of op_sub    : literal is "001000";
  attribute opc of op_mul    : literal is "001001";
  attribute opc of op_shrl   : literal is "001010";
  attribute opc of op_shll   : literal is "001011";
  attribute opc of op_addi   : literal is "001100";
  attribute opc of op_wb     : literal is "001101";
  -- TODO: define opcodes for extra instructions here  --
  attribute opc of op_fixed_mul   : literal is "001110";
  attribute opc of op_fixed_load  : literal is "010000";


  function op_name(op :    opcode_type) return string;
  function op_name(op : in opcode) return string;
----------------------------------------------------------------------------------------------------------------
  -- EMULATOR
  -- Julia 3 - microprocessor emulation from binary code
  -- using signals and implementable types
  type instruction_memory is array (natural range <>) of instruction_word;
  type register_file is array(natural range <>) of word;

  -- IMPLEMENTATION
  -- Julia 4  - implementable on Basys 3 Board

  -- alu operations
  -- TODO:
  type alucontrol is (alu_op1, alu_op2, alu_add, alu_sub, alu_and, alu_mul,
                      alu_shll, alu_shrl, alu_fixed_load, alu_fixed_mul);-- add in new ALU controls here

  -- memory map for switches, LEDs, buttons and  7SEG display hardware
  constant HWBASE: address:=to_unsigned(NPixels,address'length);
  constant SWBASE: address:=HWBASE;
  constant LEDBASE: address:=SWBASE+2;
  constant BTNBASE: address:=LEDBASE+2;
  constant SEGBASE: address:=BTNBASE+1;

  -- components
  component rom is
    generic (
      dwidth   : integer := instruction_word'length;  -- width of data
      awidth   : integer := address'length;           -- width address
      depth    : integer := 256;  -- how many elements of this width to store.
      initfile : string                 -- filename to read binary data from
      );
    port (
      clk  : in  std_logic;             -- system clock
      addr : in  unsigned(awidth-1 downto 0);
      dout : out std_logic_vector(dwidth-1 downto 0) := (others => '0')
      );
  end component;

  component debounce is
    port (
      clk                   : in  std_logic;
      clk_en                : in  std_logic;
      button                : in  std_logic;
      debounced, down_event : out std_logic := '0'
      );
  end component;

  component clk_prescaler is
    generic (
      n : integer
      );
    port (
      clk     : in  std_logic;
      clk_div : out std_logic := '0'
      );
  end component;

  component dual_port_ram is
    generic (
      dwidth : integer := 8;
      awidth : integer := 8;
      depth  : integer := 256
      );
    port (
      clka, clkb   : in  std_logic;
      wea, enb     : in  std_logic;
      addra, addrb : in  unsigned(awidth-1 downto 0);
      dina         : in  std_logic_vector(dwidth-1 downto 0);
      doutb        : out std_logic_vector(dwidth-1 downto 0) := (others => '0')
      );
  end component;

  component fixed_alu is
    port (
      operand1 : in  word;
      operand2 : in  word;
      result   : out word;
      zero     : out std_logic;         -- result is 0
      neg      : out std_logic;         -- result is negative
      control  : in  alucontrol
      );
  end component;

  component registerfile is
    generic (
      depth : integer := num_reg
      );
    port (
      clk       : in  std_logic;        -- system clock
      reset     : in  std_logic := '0';
      regwrite  : in  std_logic;        -- if true write to register
      readreg1  : in  regnum;
      readreg2  : in  regnum;
      writereg  : in  regnum;
      readdata1 : out word;
      readdata2 : out word;
      writedata : in  word
      );
  end component;







end julia_declarations;

package body julia_declarations is

  function FxP(x : real) return integer is
  begin
    return integer(x*real(2**fxp_base));
  end function;

  function lbl(s : string) return lbl_string is
    variable r : lbl_string := "          ";
  begin
    for i in s'range loop
      r(i) := s(i);
    end loop;
    return r;
  end function;

  -- dump byte vector to a file for display
  procedure memdump(fname : string; ram : memory) is
    file outfile : text;
    variable buf : line;
  begin
    file_open(outfile, fname, write_mode);
    for i in ram'range loop
      write(buf, to_integer(unsigned(ram(i)(7 downto 0))));
      writeline(outfile, buf);
    end loop;
    file_close(outfile);
    report "Wrote memory to "&fname;
  end memdump;

  -- dump ram to a file for display
  procedure ramdump(fname       :     string; n : integer;
                    signal clk  : out std_logic;
                    signal addr : out unsigned;
                    signal data : in  std_logic_vector) is
    file outfile : text;
    variable buf : line;
  begin
    file_open(outfile, fname, write_mode);
    for i in 0 to N-1 loop
      clk  <= '0'; wait for 10 ns;
      addr <= to_unsigned(i, addr'length);
      clk  <= '1'; wait for 10 ns;
      write(buf, to_integer(unsigned(data)));
      writeline(outfile, buf);
    end loop;
    file_close(outfile);
    report "Wrote ram to "&fname;
  end ramdump;

  -- look up instruction vector to find position of a destination label  -- 
  function dest_addr(lb : lbl_string; v : instruction_vector) return integer is
  begin
    for i in v'range loop
      if (v(i).lbl = lb) then
        return i;
      end if;
    end loop;
    report "jmp label '" & lb & "' not found." severity failure;
    return 0;
  end function;

  -- functions to make instruction records
  function halt(lb : string := "")
    return instruction is
  begin
    return (op_halt, 0, 0, 0, none, lbl(lb));
  end;

  function nop(lb : string := "")
    return instruction is
  begin
    return (op_nop, 0, 0, 0, none, lbl(lb));
  end;

  function jmp(jmp_dest : string)
    return instruction is
  begin
    return (op_jmp, 0, 0, 0, lbl(jmp_dest), none);
  end;

  function jmp_lt(reg_a : integer; reg_b : integer; jmp_dest : string)
    return instruction is
  begin
    return (op_jmp_lt, reg_a, reg_b, 0, lbl(jmp_dest), none);
  end;

  function jmp_eq(reg_a : integer; reg_b : integer; jmp_dest : string)
    return instruction is
  begin
    return (op_jmp_eq, reg_a, reg_b, 0, lbl(jmp_dest), none);
  end;

  function jmp_nz(reg_a : integer; jmp_dest : string)
    return instruction is
  begin
    return (op_jmp_nz, reg_a, 0, 0, lbl(jmp_dest), none);
  end;

  function load(reg_d : integer; v : integer; lb : string := "")
    return instruction is
  begin
    return (op_load, 0, v, reg_d, none, lbl(lb));
  end;

  function addi(reg_d : integer; v : integer; reg_a : integer; lb : string := "")
    return instruction is
  begin
    return (op_addi, reg_a, v, reg_d, none, lbl(lb));
  end;

  function mv(reg_d : integer; reg_s : integer; lb : string := "")
    return instruction is
  begin
    return addi(reg_d, 0, reg_s, lb);
  end;

  function add(reg_d : integer; reg_a : integer; reg_b : integer;
               lb    : string := "")
    return instruction is
  begin
    return (op_add, reg_a, reg_b, reg_d, none, lbl(lb));
  end;

  function sub(reg_d : integer; reg_a : integer; reg_b : integer;
               lb    : string := "")
    return instruction is
  begin
    return (op_sub, reg_a, reg_b, reg_d, none, lbl(lb));
  end;

  function mul(reg_d : integer; reg_a : integer; reg_b : integer;
               lb    : string := "")
    return instruction is
  begin
    return (op_mul, reg_a, reg_b, reg_d, none, lbl(lb));
  end;

  function shrl(reg_d : integer; reg_a : integer; imm : natural;
                lb    : string := "")
    return instruction is
  begin
    return (op_shrl, reg_a, imm, reg_d, none, lbl(lb));
  end;

  function shll(reg_d : integer; reg_a : integer; imm : natural;
                lb    : string := "")
    return instruction is
  begin
    return (op_shll, reg_a, imm, reg_d, none, lbl(lb));
  end;

  function wb(reg_addr : integer; reg_v : integer; lb : string := "")
    return instruction is
  begin
    return (op_wb, reg_addr, reg_v, 0, none, lbl(lb));
  end;

  function fixed_load(reg_d : integer; v : integer; lb : string := "")
    return instruction is
  begin
    return (op_fixed_load, 0, v, reg_d, none, lbl(lb));
  end;

  function fixed_mul(reg_d : integer; reg_a : integer; reg_b : integer;
                lb    : string := "")
    return instruction is
  begin
    return (op_fixed_mul, reg_a, reg_b, reg_d, none, lbl(lb));
  end;



  -- TODO: Add in new functions for instructions here

  function op_name(op : opcode_type) return string is
  begin
    case op is
      when op_halt'opc   => return "halt";
      when op_nop'opc    => return "nop";
      when op_jmp'opc    => return "jmp";
      when op_jmp_lt'opc => return "jmp_lt";
      when op_jmp_eq'opc => return "jmp_eq";
      when op_jmp_nz'opc => return "jmp_nz";
      when op_load'opc   => return "load";
      when op_fixed_load'opc  => return "fixed_load";
      when op_add'opc    => return "add";
      when op_addi'opc   => return "addi";
      when op_sub'opc    => return "sub";
      when op_mul'opc    => return "mul";
      when op_fixed_mul'opc   => return "fixed_mul";
      when op_shrl'opc   => return "shrl";
      when op_shll'opc   => return "shll";
      when op_wb'opc     => return "wb";
      -- TODO: Add in names for new instructions
      when others        => return "unknown";
    end case;
  end op_name;

  function op_name(op : in opcode) return string is
  begin
    case op is
      when op_halt   => return "halt";
      when op_nop    => return "nop";
      when op_jmp    => return "jmp";
      when op_jmp_lt => return "jmp_lt";
      when op_jmp_eq => return "jmp_eq";
      when op_jmp_nz => return "jmp_nz";
      when op_load   => return "load";
      when op_fixed_load  => return "fixed_load";
      when op_add    => return "add";
      when op_addi   => return "addi";
      when op_sub    => return "sub";
      when op_mul    => return "mul";
      when op_fixed_mul   => return "fixed_mul";
      when op_shrl   => return "shrl";
      when op_shll   => return "shll";
      when op_wb     => return "wb";
      -- TODO: Add in names for new instructions
    end case;
  end op_name;

end julia_declarations;

