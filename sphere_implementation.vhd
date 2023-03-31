--------------------------------------------------------------------------------
-- Title:       : Implementable microprocessor for sphere example
-- Project      : EExDSA Practical Work
-- Author       : Dr. John Williams
-- Copyright    : 2020--2022 Aston University
--------------------------------------------------------------------------------
-- Purpose      : 
-- Demonstrate implemented microprocessor for simulation
-- using synthesisable vhdl
--------------------------------------------------------------------------------


library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use STD.textio.all;
use IEEE.std_logic_textio.all;
use work.sphere_declarations.all;
use work.util.all;

entity sphere_implementation is
end;

architecture impl of sphere_implementation is
  constant infile     : string   := "sphere.bin";
  constant outfile    : string   := "implementation.vga";
  constant clk_period : time     := 10 ns;
  constant debug      : boolean  := false;
  constant max_ins    : positive := 60;

  -- flow signals
  signal hlt         : std_logic := '0';
  signal clk         : std_logic := '0';
  signal reset       : std_logic := '1';
  signal pc, next_pc : address   := (others => '0');  -- program counter

  -- ram read control signals for display
  signal ram_en   : std_logic   := '0';
  signal ram_ab   : ram_address := to_unsigned(0, ram_address'length);
  signal ram_dout : std_logic_vector(7 downto 0);

  -- register file signals
  signal rr1, rr2, wr : regnum;
  signal rd1, rd2, wd : word;

  -- Alu signals
  signal operand2, result : word;
  signal zero, neg        : std_logic;

  -- Control signals
  signal reg_dst, mem_to_reg, mem_read, mem_write : std_logic := '0';
  signal alu_src, reg_write, jump                 : std_logic := '0';
  signal alu_op                                   : alucontrol;

  -- instruction and decoding
  signal ins : instruction_word := op_nop'opc&"000000000000";

  -- write a string to buffer.
  procedure swrite(L         : inout line; VALUE : in string;
                   JUSTIFIED : in    side := right; FIELD : in WIDTH := 0) is
  begin
    write(L, string'(value), justified, field);
  end swrite;

  -- print out instruction components
  procedure log_ins(pc : address; ins : instruction_word) is
    variable buf    : line;
    variable opcode : opcode_type := ins(15 downto 12);
    variable rr1    : natural     := to_integer(unsigned(ins(11 downto 9)));
    variable rr2    : natural     := to_integer(unsigned(ins(8 downto 6)));
    variable wr     : natural     := to_integer(unsigned(ins(5 downto 3)));
    variable imm    : immediate   := signed(ins(5 downto 0));
  begin
    write(buf, to_integer(pc));
    swrite(buf, " : ");
    write(buf, ins); swrite(buf, " : ");
    write(buf, op_name(opcode));
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
    write(buf, to_integer(rr1), right, 8);
    write(buf, to_integer(rr2), right, 8);
    write(buf, to_integer(wr), right, 8);
    writeline(OUTPUT, buf);
  end log_reg;

begin
  -- decode instructions into fields
  rr1 <= unsigned(ins(11 downto 9));
  rr2 <= unsigned(ins(8 downto 6));

  -- multiplexers
  wr <= unsigned(ins(5 downto 3)) when reg_dst = '1'
        else unsigned(ins(8 downto 6));
  operand2 <= rd2 when alu_src = '0' else
              resize(signed(ins(15 downto 0)), operand2'length);
  wd <= result when mem_to_reg = '0' else
        resize(signed(ram_dout), wd'length);
  next_pc <= pc+1 when jump = '0' else
             resize(unsigned(ins(5 downto 0)), pc'length);

  -- subcomponents
  rom1 : rom
    generic map (dwidth   => instruction_word'length,
                 awidth   => address'length,
                 depth    => 127,
                 initfile => infile)
    port map (clk  => clk,
              addr => next_pc,
              dout => ins);
  ram1 : dual_port_ram
    generic map(dwidth => 8, awidth => ram_address'length, depth => Npixels)
    port map (clka  => clk, clkb => clk, wea => mem_write, enb => ram_en,
              addra => unsigned(result), addrb => ram_ab,
              dina  => std_logic_vector(rd2(7 downto 0)), doutb => ram_dout);
  reg1 : registerfile
    port map(clk       => clk, regwrite => reg_write,
             readreg1  => rr1, readreg2 => rr2, writereg => wr,
             readdata1 => rd1, readdata2 => rd2, writedata => wd);
  alu1 : alu
    port map(operand1 => rd1, operand2 => operand2, control => alu_op,
             zero     => zero, neg => neg, result => result);

  -- generate clock until halt instruction is reached
  clk_proc : process
    variable ins_cnt : natural;         -- count instructions
  begin
    ins_cnt := 0;
    -- assert reset for a clock cycle
    reset   <= '1';
    ram_en  <= '0';
    while hlt = '0' and (not(debug) or ins_cnt < max_ins) loop
      clk     <= '0'; wait for clk_period/2;
      clk     <= '1'; wait for clk_period/2;
      ins_cnt := ins_cnt+1;
      reset   <= '0';
    end loop;
    reset <= '1';
    -- extra clock cycle finish write to ram.
    clk   <= '0'; wait for clk_period/2;
    clk   <= '1'; wait for clk_period/2;
    report "Finished in "&integer'image(ins_cnt)&" instructions.";
    if not(debug) then
      ram_en <= '1';
      ramdump(fname => outfile, n => Npixels,
              clk   => clk, addr => ram_ab, data => ram_dout);
    end if;
    wait;
  end process clk_proc;

  -- Main synchronous process updates pc register on clock.
  sync_proc : process(clk)
  begin
    if rising_edge(clk) then
      -- output debugging info
      if debug then
        log_ins(pc, ins);
        log_reg(rd1, rd2, wd);
      end if;
      if reset = '1' then
        pc <= (others => '0');
      elsif hlt = '0' then
        pc <= next_pc;
      else
        pc <= pc;
      end if;
    end if;
  end process;

  -- the control combinational process - should be in another entity?
  control_proc : process(ins, zero, neg)
    variable opcode : opcode_type;
  begin
    -- for convenience we break instruction into components for decoding
    opcode := ins(15 downto 12);

    -- set defaults for all control signals
    reg_write  <= '0';
    reg_dst    <= '0';
    mem_to_reg <= '0';
    mem_read   <= '0';
    mem_write  <= '0';
    alu_src    <= '0';
    reg_write  <= '0';
    jump       <= '0';
    alu_op     <= alu_add;

    case opcode is
      when op_halt'opc => hlt <= '1';
      when op_nop'opc =>
      when op_jmp'opc =>
        alu_op <= alu_add; alu_src <= '0';
        jump   <= '1';
      when op_jmp_lt'opc =>
        alu_op                 <= alu_sub; alu_src <= '0';
        if neg = '1' then jump <= '1'; end if;
      when op_jmp_nz'opc =>
        alu_op                  <= alu_add; alu_src <= '0';
        if zero = '0' then jump <= '1'; end if;
      when op_load'opc =>
        alu_op <= alu_add; alu_src <= '1'; reg_write <= '1'; reg_dst <= '0';
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
        assert
          rd1 < Npixels
          report "Address out of memory bounds" severity error;
      when others =>
        log_ins(pc, ins);
        report "Unknown instruction" severity error;
    end case;
  end process control_proc;


end;
