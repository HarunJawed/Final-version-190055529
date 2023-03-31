--------------------------------------------------------------------------------
-- Title:        : Simple ALU implementation
-- Project       : EE4DSH Practical Work
-- Author        : Dr. John A.R. Williams
-- Copyright     : 2020-2022 Aston University
--------------------------------------------------------------------------------
-- Purpose       : Provides ALU implementation
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use work.julia_declarations.all;

entity fixed_alu is
  port (
    operand1 : in  word;
    operand2 : in  word;
    result   : out word      := (others => '0');
    zero     : out std_logic := '0';    -- result is 0
    neg      : out std_logic := '0';    -- result is negative
    control  : in  alucontrol
    );
end fixed_alu;

architecture behavioral of fixed_alu is
-- Declaration of type and signal for RAM
  signal result_i : word := (others => '0');
begin
  result <= result_i;
  zero   <= '1' when result_i = 0 else '0';  -- result is zero
  neg    <= result_i(result'high);           -- result is negative

  process(control, operand1, operand2)
  begin
    result_i <= (others => '0');
    case control is
      when alu_op1 => result_i <= operand1;  -- useful to test op1
      when alu_op2 => result_i <= operand2;  -- or op2
      when alu_add => result_i <= operand1+operand2;
      when alu_sub => result_i <= operand1-operand2;
      when alu_and => result_i <= operand1 and operand2;
      when alu_mul => result_i <= resize(operand1*operand2, result'length);
      when alu_shll =>
        result_i <= shift_left(operand1, to_integer(operand2));
      when alu_shrl =>
        result_i <= shift_right(operand1, to_integer(operand2));
	-- x/2^y == shiftright x,y 
      when alu_fixed_mul => result_i <= resize(shift_right(operand1*operand2, (fxp_base)), result'length); 
	--x*2^y ==shiftleft x,y
      when alu_fixed_load => result_i <= shift_left(operand2, (fxp_base)); 
    end case;
  end process;


end behavioral;

