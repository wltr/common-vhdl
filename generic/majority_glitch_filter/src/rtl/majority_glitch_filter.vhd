--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Detect Filter glitches by counting bit occurrences.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity majority_glitch_filter is
  generic (
    -- Initial value of input signal
    init_value_g : std_ulogic := '0';

    -- Length of window
    max_value_g : positive := 16;

    -- Number of '1' within window for output to be '1'
    high_threshold_g : positive := 12;

    -- Number of '0' within window for output to be '0'
    low_threshold_g : natural := 4);
  port (
    -- Clock and resets
    clk_i       : in std_ulogic;
    rst_asy_n_i : in std_ulogic;
    rst_syn_i   : in std_ulogic;

    -- Enable
    en_i : in std_ulogic;

    -- Input signal
    sig_i : in  std_ulogic;

    -- Filtered output signal
    sig_o : out std_ulogic);
end entity majority_glitch_filter;

architecture rtl of majority_glitch_filter is

  ------------------------------------------------------------------------------
  -- Internal Registers
  ------------------------------------------------------------------------------

  signal cnt : unsigned(integer(ceil(log2(real(max_value_g)))) - 1 downto 0) := (others => '0');
  signal sig : std_ulogic := init_value_g;

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Assertions
  ------------------------------------------------------------------------------

  assert high_threshold_g < max_value_g
  report "high_threshold_g needs to be smaller than max_value_g."
  severity error;

  assert low_threshold_g < max_value_g
  report "low_threshold_g needs to be smaller than max_value_g."
  severity error;

  assert high_threshold_g > low_threshold_g
  report "high_threshold_g needs to be bigger than low_threshold_g."
  severity error;

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------

  sig_o <= sig;

  ------------------------------------------------------------------------------
  -- Registers
  ------------------------------------------------------------------------------

  -- Filter signal
  regs : process (clk_i, rst_asy_n_i) is
    procedure reset is
    begin
      cnt <= to_unsigned(0, cnt'length);
      sig <= init_value_g;
    end procedure reset;
  begin -- process regs
    if rst_asy_n_i = '0' then
      reset;
    elsif rising_edge(clk_i) then
      if rst_syn_i = '1' then
        reset;
      elsif en_i = '1' then
        if sig_i = '1' and to_integer(cnt) < max_value_g - 1 then
          cnt <= cnt + 1;
        elsif sig_i = '0' and to_integer(cnt) > 0 then
          cnt <= cnt - 1;
        end if;

        if to_integer(cnt) >= high_threshold_g then
          sig <= '1';
        elsif to_integer(cnt) <= low_threshold_g then
          sig <= '0';
        end if;
      end if;
    end if;
  end process regs;

end architecture rtl;
