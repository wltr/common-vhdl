--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Multiply the filter coefficients with the input data and accumulate
-- the results.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ads1281_filter_mac is
  port (
    -- Clock and resets
    clk_i       : in std_ulogic;
    rst_asy_n_i : in std_ulogic;
    rst_syn_i   : in std_ulogic;

    -- Decoded data
    data_i : in signed(6 downto 0);

    -- Coefficient
    coeff_i      : in unsigned(23 downto 0);
    coeff_en_i   : in std_ulogic;
    coeff_done_i : in std_ulogic;

    -- MAC result
    data_o    : out signed(23 downto 0);
    data_en_o : out std_ulogic);
end entity ads1281_filter_mac;

architecture rtl of ads1281_filter_mac is

  ------------------------------------------------------------------------------
  -- Internal Wires
  ------------------------------------------------------------------------------

  signal res    : signed(30 downto 0);
  signal res_en : std_ulogic;

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Instances
  ------------------------------------------------------------------------------

  -- Multiply filter coefficient with input data
  ads1281_filter_multiplier_inst : entity work.ads1281_filter_multiplier
    port map (
      clk_i       => clk_i,
      rst_asy_n_i => rst_asy_n_i,
      rst_syn_i   => rst_syn_i,
      data_i      => data_i,
      coeff_i     => coeff_i,
      coeff_en_i  => coeff_en_i,
      res_o       => res,
      res_en_o    => res_en);

  -- Accumulate result
  ads1281_filter_accumulator_inst : entity work.ads1281_filter_accumulator
    port map (
      clk_i        => clk_i,
      rst_asy_n_i  => rst_asy_n_i,
      rst_syn_i    => rst_syn_i,
      data_i       => res,
      data_en_i    => res_en,
      coeff_done_i => coeff_done_i,
      data_o       => data_o,
      data_en_o    => data_en_o);

end architecture rtl;
