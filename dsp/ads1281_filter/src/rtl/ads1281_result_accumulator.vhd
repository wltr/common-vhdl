--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Accumulate filter results.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.lfsr_pkg.all;

entity ads1281_result_accumulator is
  generic (
    -- Number of results to be accumulated
    num_results_g : positive := 10);
  port (
    -- Clock and resets
    clk_i       : in std_ulogic;
    rst_asy_n_i : in std_ulogic;
    rst_syn_i   : in std_ulogic;

    -- Filter results
    result_i    : in std_ulogic_vector(23 downto 0);
    result_en_i : in std_ulogic;

    -- Accumulated results
    result_o    : out std_ulogic_vector(27 downto 0);
    result_en_o : out std_ulogic);
end entity ads1281_result_accumulator;

architecture rtl of ads1281_result_accumulator is

  ------------------------------------------------------------------------------
  -- Types and Constants
  ------------------------------------------------------------------------------

  -- LFSR counter bit length
  constant len_c : natural := lfsr_length(num_results_g);

  -- LFSR counter initial value
  constant seed_c : std_ulogic_vector(len_c - 1 downto 0) := lfsr_seed(len_c);

  -- LFSR counter maximal value
  constant max_c : std_ulogic_vector(len_c - 1 downto 0) := lfsr_shift(seed_c, num_results_g - 1);

  ------------------------------------------------------------------------------
  -- Internal Registers
  ------------------------------------------------------------------------------

  signal count  : std_ulogic_vector(len_c - 1 downto 0);
  signal sum    : signed(27 downto 0);
  signal sum_en : std_ulogic;
  signal num    : std_ulogic;
  signal carry  : std_ulogic;

  ------------------------------------------------------------------------------
  -- Internal Wires
  ------------------------------------------------------------------------------

  signal sum_0 : signed(14 downto 0);
  signal sum_1 : signed(14 downto 0);

begin   -- architecture rtl

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------

  result_o    <= std_ulogic_vector(sum);
  result_en_o <= sum_en;

  ------------------------------------------------------------------------------
  -- Signal Assignments
  ------------------------------------------------------------------------------

  sum_0 <= signed('0' & std_ulogic_vector(sum(13 downto 0))) + signed('0' & result_i(13 downto 0));

  sum_1 <= signed(std_ulogic_vector(sum(27 downto 14)) & carry) + signed(result_i(23 downto 14) & '1');

  ------------------------------------------------------------------------------
  -- Registers
  ------------------------------------------------------------------------------

  regs : process (clk_i, rst_asy_n_i) is
    procedure reset is
    begin
      count  <= seed_c;
      sum    <= to_signed(0, sum'length);
      sum_en <= '0';
      num    <= '0';
      carry  <= '0';
    end procedure reset;
  begin -- process regs
    if rst_asy_n_i = '0' then
      reset;
    elsif rising_edge(clk_i) then
      -- Defaults
      sum_en <= '0';

      if rst_syn_i = '1' then
        reset;
      else
        if result_en_i = '1' then
          sum(13 downto 0) <= sum_0(13 downto 0);
          carry            <= sum_0(14);
          num              <= '1';
        elsif sum_en = '0' and num = '1' then
          sum(27 downto 14) <= sum_1(14 downto 1);
          carry             <= '0';
          num               <= '0';

          if count = max_c then
            sum_en <= '1';
          else
            count <= lfsr_shift(count);
          end if;
        elsif sum_en = '1' then
          reset;
        end if;
      end if;
    end if;
  end process regs;

end architecture rtl;
