--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Generate a sampling bit clock base on a data signal as reference.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity bit_clock_recovery is
  generic (
    -- Number of system clock cycles per bit clock cycle
    num_cycles_g : positive := 40;

    -- Sampling point offset from the middle of each cycle
    offset_g : integer := 0;

    -- Edge type: 0 = Rising, 1 = Falling, 2 = Both
    edge_type_g : natural range 0 to 2 := 2);
  port (
    -- Clock and resets
    clk_i       : in std_ulogic;
    rst_asy_n_i : in std_ulogic;
    rst_syn_i   : in std_ulogic;

    -- Enable
    en_i : in std_ulogic;

    -- Reference signal
    sig_i : in  std_ulogic;

    -- Recovered bit clock
    bit_clk_o : out std_ulogic);
end entity bit_clock_recovery;

architecture rtl of bit_clock_recovery is

  ------------------------------------------------------------------------------
  -- Types and Constants
  ------------------------------------------------------------------------------

  constant bit_width_c : natural := integer(ceil(log2(real(num_cycles_g))));

  ------------------------------------------------------------------------------
  -- Internal Wires
  ------------------------------------------------------------------------------

  signal edge : std_ulogic;

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Instances
  ------------------------------------------------------------------------------

  -- Detect rising and falling edges on reference signal
  edge_detector_inst : entity work.edge_detector
    generic map (
      init_value_g => '0',
      edge_type_g  => edge_type_g,
      hold_flag_g  => false)
    port map (
      clk_i       => clk_i,
      rst_asy_n_i => rst_asy_n_i,
      rst_syn_i   => rst_syn_i,
      en_i        => en_i,
      ack_i       => '0',
      sig_i       => sig_i,
      edge_o      => edge);

  -- Generate strobe synchronized with detected edges
  lfsr_strobe_generator_inst : entity work.lfsr_strobe_generator
    generic map (
      period_g       => num_cycles_g,
      preset_value_g => num_cycles_g / 2 - offset_g - 1)
    port map (
      clk_i       => clk_i,
      rst_asy_n_i => rst_asy_n_i,
      rst_syn_i   => rst_syn_i,
      en_i        => en_i,
      pre_i       => edge,
      strobe_o    => bit_clk_o);

end architecture rtl;
