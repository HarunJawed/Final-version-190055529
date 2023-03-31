--------------------------------------------------------------------------------
-- Title:       : Synthesisable microprocessor example for sphere example
-- Project      : EE4DSH Practical Work
-- Author       : Dr. John Williams
-- Copyright    : 2020--2022 Aston University
--------------------------------------------------------------------------------
-- Purpose       : 
-- Implemented microprocessor suitable for synthesis
--------------------------------------------------------------------------------

library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use STD.textio.all;
use IEEE.std_logic_textio.all;
use work.julia_declarations.all;
use work.util.all;

entity julia_mp is
  generic (
    infile : string  := rom_fname;
    debug  : boolean := false
    );
  port (
    clk       : in  std_logic;
    reset     : in  std_logic;
    hlt       : out std_logic                    := '0';
    -- interface to ram
    mem_write : out std_logic                    := '0';
    addr      : out ram_address                  := (others => '0');
    data_out  : out std_logic_vector(7 downto 0);
    mem_read  : out std_logic                    := '0';
    data_in   : in  std_logic_vector(7 downto 0) := (others => '0')
    );
end julia_mp;

architecture impl of julia_mp is

  -- flow signals
  signal pc, next_pc : address   := (others => '0');  -- program counter
  signal hlt_i       : std_logic := '0';

  -- register file signals
  signal rr1, rr2, wr : regnum;
  signal rd1, rd2, wd : word;

  -- Alu signals
  signal operand2, result : word;
  signal zero, neg        : std_logic;

  -- Control signals
  signal reg_dst, mem_to_reg      : std_logic := '0';
  signal alu_src, reg_write, jump : std_logic := '0';
  signal alu_op                   : alucontrol;

  -- instruction and decoding
  signal ins : instruction_word := (others => '0');


  -- write a string to buffer.
  procedure swrite(L         : inout line; VALUE : in string;
                   JUSTIFIED : in    side := right; FIELD : in WIDTH := 0) is
  begin
    write(L, string'(value), justified, field);
  end swrite;

  -- print out instruction components
  procedure log_ins(pc : address; ins : instruction_word) is
    variable buf    : line;
    variable opcode : opcode_type := ins(31 downto 26);
    variable rr1    : natural     := to_integer(unsigned(ins(25 downto 21)));
    variable rr2    : natural     := to_integer(unsigned(ins(20 downto 16)));
    variable wr     : natural     := to_integer(unsigned(ins(15 downto 11)));
    variable imm    : immediate   := signed(ins(15 downto 0));
  begin
    write(buf, to_integer(pc));
    swrite(buf, " : ");
    write(buf, ins); swrite(buf, " : ");
    write(buf, op_name(opcode));
    -- TODO: FIX ORDER
    swrite(buf, "( rr1=");
    write(buf, rr1); swrite(buf, ", rr2=");
    write(buf, rr2); swrite(buf, ", wr=");
    write(buf, wr); swrite(buf, ", imm=");
    write(buf, to_integer(imm)); swrite(buf, ")");
    writeline(OUTPUT, buf);
  end log_ins;

  --  print out registers
  procedure log_reg(signal rr1 : in word;
                    signal rr2 : in word;
                    signal wr  : in word) is
    variable buf : line;
  begin
    write(buf, to_integer(rr1), right, 20);
    write(buf, to_integer(rr2), right, 20);
    write(buf, to_integer(wr), right, 20);
    writeline(OUTPUT, buf);
  end log_reg;

begin
  -- decode instructions into fields
  rr1 <= unsigned(ins(25 downto 21));
  rr2 <= unsigned(ins(20 downto 16));

  -- multiplexers
  wr <= unsigned(ins(15 downto 11)) when reg_dst = '1' 
        else unsigned(ins(20 downto 16)); 
  operand2 <= rd2 when alu_src = '0' else
              resize(signed(ins(15 downto 0)), operand2'length);
  wd <= result when mem_to_reg = '0' else
        resize(signed(data_in), wd'length);

  -- outputs to ram
  data_out <= std_logic_vector(rd2(7 downto 0));
  addr     <= unsigned(result(addr'range));
  hlt      <= hlt_i;
  next_pc  <= (others => '0') when reset = '1' else
             pc+1 when jump = '0' else
             resize(unsigned(ins(15 downto 0)), pc'length);

  -- subcomponents
  rom1 : rom
    generic map (dwidth   => instruction_word'length,
                 awidth   => address'length,
                 depth    => 127,
                 initfile => infile)
    port map (clk  => clk,
              addr => next_pc,
              dout => ins);
  alu1 : fixed_alu
    port map(operand1 => rd1, operand2 => operand2, control => alu_op,
             zero     => zero, neg => neg, result => result);
  reg1 : registerfile
    generic map (depth => num_reg)    
    port map(clk       => clk,
             reset     => reset, regwrite => reg_write,
             readreg1  => rr1, readreg2 => rr2, writereg => wr,
             readdata1 => rd1, readdata2 => rd2, writedata => wd);

  -- Main synchronous process updates pc register on clock.
  sync_proc : process(clk, reset)
  begin
    if rising_edge(clk) then
      if debug then
        log_ins(pc, ins);
        log_reg(rd1, rd2, wd);
      end if;
      if reset = '1' then
        hlt_i <= '0';
      elsif ins(31 downto 26) = op_halt'opc or hlt_i = '1' then
        hlt_i <= '1';
      elsif hlt_i = '0' then
        pc <= next_pc;
      end if;
    end if;
  end process;

  -- the control combinational process - should be in another entity?
  control_proc : process(ins, zero, neg)
    variable opcode : opcode_type;
  begin
    -- for convenience we break instruction into components for decoding
    opcode := ins(31 downto 26);

    -- set defaults for all control signals
    reg_write  <= '0';
    reg_dst    <= '0';
    mem_to_reg <= '0';
    mem_read   <= '0';
    mem_write  <= '0';
    alu_src    <= '0';
    reg_write  <= '0';
    jump       <= '0';
    alu_op     <= alu_op1;

    case opcode is
      when op_halt'opc =>
      when op_nop'opc =>
      when op_jmp'opc =>
        alu_op <= alu_op1; alu_src <= '0'; jump <= '1';
      when op_jmp_lt'opc =>
        alu_op <= alu_sub; alu_src <= '0';
        if neg = '1' then
          jump <= '1';
        end if;
      when op_jmp_nz'opc =>
        alu_op <= alu_op1; alu_src <= '0';
        if zero = '0' then
          jump <= '1';
        end if;
      when op_load'opc =>
        alu_op <= alu_op2; alu_src <= '1'; reg_write <= '1'; reg_dst <= '0';
      when op_add'opc =>
        alu_op <= alu_add; alu_src <= '0'; reg_write <= '1'; reg_dst <= '1';
      when op_sub'opc =>
        alu_op <= alu_sub; alu_src <= '0'; reg_write <= '1'; reg_dst <= '1';
      when op_mul'opc =>
        alu_op <= alu_mul; alu_src <= '0'; reg_write <= '1'; reg_dst <= '1';
      when op_addi'opc =>
        alu_op <= alu_add; alu_src <= '1'; reg_write <= '1'; reg_dst <= '0';
      when op_shrl'opc =>
        alu_op <= alu_shrl; alu_src <= '1'; reg_write <= '1'; reg_dst <= '0';
      when op_shll'opc =>
        alu_op <= alu_shll; alu_src <= '1'; reg_write <= '1'; reg_dst <= '0';
      when op_wb'opc =>
        alu_op <= alu_add; alu_src <= '1'; mem_write <= '1';
      when op_fixed_mul'opc=>
      	alu_op <= alu_fixed_mul; alu_src <= '0'; reg_write <= '1'; reg_dst <= '1';
      when others =>
        report "Unknown instruction" severity error;
    end case;
  end process control_proc;


end;
