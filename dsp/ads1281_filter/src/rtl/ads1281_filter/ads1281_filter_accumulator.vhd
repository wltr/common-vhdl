--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Add input data to a stored result.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ads1281_filter_accumulator is
  port (
    -- Clock and resets
    clk_i       : in std_ulogic;
    rst_asy_n_i : in std_ulogic;
    rst_syn_i   : in std_ulogic;

    -- Multiplier result
    data_i    : in signed(30 downto 0);
    data_en_i : in std_ulogic;

    -- Coefficient done flag
    coeff_done_i : in std_ulogic;

    -- MAC result
    data_o    : out signed(23 downto 0);
    data_en_o : out std_ulogic);
end entity ads1281_filter_accumulator;

architecture rtl of ads1281_filter_accumulator is

  ------------------------------------------------------------------------------
  -- Types and Constants
  ------------------------------------------------------------------------------

  type state_t is (ACC_1, ACC_2, ACC_3, ACC_4);

  type reg_t is record
    state : state_t;
    sum   : signed(34 downto 0);
    carry : std_ulogic;
    done  : std_ulogic;
    en    : std_ulogic;
  end record reg_t;

  constant init_c : reg_t := (
    state => ACC_1,
    sum   => (others => '0'),
    carry => '0',
    done  => '0',
    en    => '0');

  ------------------------------------------------------------------------------
  -- Internal Registers
  ------------------------------------------------------------------------------

  signal reg : reg_t;

  ------------------------------------------------------------------------------
  -- Internal Wires
  ------------------------------------------------------------------------------

  signal next_reg : reg_t;
  signal sum_1    : signed(9 downto 0);
  signal sum_2    : signed(9 downto 0);
  signal sum_3    : signed(9 downto 0);
  signal sum_4    : signed(10 downto 0);
  signal sign     : std_ulogic_vector(3 downto 0);

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------

  data_o    <= reg.sum(reg.sum'high downto reg.sum'length - data_o'length);
  data_en_o <= reg.en;

  ------------------------------------------------------------------------------
  -- Signal Assignments
  ------------------------------------------------------------------------------

  -- 1st Adder: sum(8:0) + y(8:0)
  sum_1 <= signed('0' & std_ulogic_vector(reg.sum(8 downto 0))) + signed('0' & std_ulogic_vector(data_i(8 downto 0)));

  -- 2nd Adder: sum(16:9) + y(16:9)
  sum_2 <= signed('0' & std_ulogic_vector(reg.sum(16 downto 9)) & reg.carry) + signed('0' & std_ulogic_vector(data_i(16 downto 9)) & '1');

  -- 3rd Adder: sum(24:17) + y(24:17)
  sum_3 <= signed('0' & std_ulogic_vector(reg.sum(24 downto 17)) & reg.carry) + signed('0' & std_ulogic_vector(data_i(24 downto 17)) & '1');

  -- 4th Adder: sum(34:25) + y(30:25) + sign extension
  sum_4 <= signed(std_ulogic_vector(reg.sum(34 downto 25)) & reg.carry) + signed(sign & std_ulogic_vector(data_i(30 downto 25)) & '1');

  -- 4th Adder: sign extension of y
  sign <= (others => data_i(data_i'high));

  ------------------------------------------------------------------------------
  -- Registers
  ------------------------------------------------------------------------------

  regs : process (clk_i, rst_asy_n_i) is
    procedure reset is
    begin
      reg <= init_c;
    end procedure reset;
  begin -- process regs
    if rst_asy_n_i = '0' then
      reset;
    elsif rising_edge(clk_i) then
      if rst_syn_i = '1' then
        reset;
      else
        reg <= next_reg;
      end if;
    end if;
  end process regs;

  ------------------------------------------------------------------------------
  -- Combinatorics
  ------------------------------------------------------------------------------

  comb : process (reg, data_en_i, coeff_done_i, sum_1, sum_2, sum_3, sum_4) is
  begin -- process comb
    -- Defaults
    next_reg <= reg;

    next_reg.en <= '0';

    -- Remember if coefficient is the last one
    if coeff_done_i = '1' then
      next_reg.done <= '1';
    end if;

    case reg.state is
      when ACC_1 =>
        if reg.en = '1' then
          next_reg.sum <= (others => '0');
        end if;

        if data_en_i = '1' then
          -- If result of multiplier is available save 1st partial sum
          next_reg.sum(8 downto 0) <= sum_1(8 downto 0);
          -- Save carry for next state
          next_reg.carry <= sum_1(sum_1'high);
          next_reg.state <= ACC_2;
        end if;

      when ACC_2 =>
        -- Save 2nd partial sum
        next_reg.sum(16 downto 9) <= sum_2(8 downto 1);
        -- Save carry for next state
        next_reg.carry <= sum_2(sum_2'high);
        next_reg.state <= ACC_3;

      when ACC_3 =>
        -- Save 3rd partial sum
        next_reg.sum(24 downto 17) <= sum_3(8 downto 1);
        -- Save carry for next state
        next_reg.carry <= sum_3(sum_3'high);
        next_reg.state <= ACC_4;

      when ACC_4 =>
        -- Save 4th partial sum
        next_reg.sum(34 downto 25) <= sum_4(10 downto 1);
        -- Check if done
        next_reg.done  <= '0';
        next_reg.en    <= reg.done;
        next_reg.state <= ACC_1;
    end case;
  end process comb;

end architecture rtl;
