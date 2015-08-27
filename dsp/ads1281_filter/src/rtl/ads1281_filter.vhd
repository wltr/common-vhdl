--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Calculate the coefficients and pass them on the each channel.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.ads1281_filter_pkg.all;

entity ads1281_filter is
  port (
    -- Clock and resets
    clk_i       : in std_ulogic;
    rst_asy_n_i : in std_ulogic;
    rst_syn_i   : in std_ulogic;

    -- Synchronization strobe
    strb_ms_i     : in std_ulogic;
    -- Sample strobe
    strb_sample_o : out std_ulogic;

    -- ADC bit streams
    adc_m0_i : in std_ulogic_vector(ads1281_filter_num_channels_c - 1 downto 0);
    adc_m1_i : in std_ulogic_vector(ads1281_filter_num_channels_c - 1 downto 0);

    -- Filter results
    result_o    : out ads1281_filter_result_t;
    result_en_o : out std_ulogic_vector(ads1281_filter_num_channels_c - 1 downto 0));
end entity ads1281_filter;

architecture rtl of ads1281_filter is

  ------------------------------------------------------------------------------
  -- Internal Wires
  ------------------------------------------------------------------------------

  signal m1_changed   : std_ulogic;
  signal sample_strb  : std_ulogic;
  signal coeff1       : unsigned(23 downto 0);
  signal coeff1_en    : std_ulogic;
  signal coeff1_done  : std_ulogic;
  signal coeff1_start : std_ulogic;
  signal coeff2       : unsigned(23 downto 0);
  signal coeff2_en    : std_ulogic;
  signal coeff2_done  : std_ulogic;
  signal coeff2_start : std_ulogic;

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------

  strb_sample_o <= sample_strb;

  ------------------------------------------------------------------------------
  -- Instances
  ------------------------------------------------------------------------------

  -- Check for changes on any M1 bit stream
  ads1281_filter_sampling_inst : entity work.ads1281_filter_sampling
    port map (
      clk_i       => clk_i,
      rst_asy_n_i => rst_asy_n_i,
      rst_syn_i   => rst_syn_i,
      adc_m1_i    => adc_m1_i,
      changed_o   => m1_changed);

  -- Create sampling strobe from incoming M1 (has typically more edges) bit stream
  bit_clock_recovery_inst : entity work.bit_clock_recovery
    generic map (
      num_cycles_g => 40,
      offset_g     => -3,
      edge_type_g  => 0)
    port map (
      clk_i       => clk_i,
      rst_asy_n_i => rst_asy_n_i,
      rst_syn_i   => rst_syn_i,
      en_i        => '1',
      sig_i       => m1_changed,
      bit_clk_o   => sample_strb);

  -- Alternate between the two interleaved filters
  ads1281_filter_select_inst : entity work.ads1281_filter_select
    port map (
      clk_i          => clk_i,
      rst_asy_n_i    => rst_asy_n_i,
      rst_syn_i      => rst_syn_i,
      strb_ms_i      => strb_ms_i,
      coeff1_start_o => coeff1_start,
      coeff2_start_o => coeff2_start);

  -- Calculating the filter coefficients for the 1st interleaved filter
  ads1281_filter_coefficients_inst_0 : entity work.ads1281_filter_coefficients
    port map (
      clk_i       => clk_i,
      rst_asy_n_i => rst_asy_n_i,
      rst_syn_i   => rst_syn_i,
      start_i     => coeff1_start,
      next_i      => sample_strb,
      coeff_o     => coeff1,
      coeff_en_o  => coeff1_en,
      done_o      => coeff1_done);

  -- Calculating the filter coefficients for the 2nd interleaved filter
  ads1281_filter_coefficients_inst_1 : entity work.ads1281_filter_coefficients
    port map (
      clk_i       => clk_i,
      rst_asy_n_i => rst_asy_n_i,
      rst_syn_i   => rst_syn_i,
      start_i     => coeff2_start,
      next_i      => sample_strb,
      coeff_o     => coeff2,
      coeff_en_o  => coeff2_en,
      done_o      => coeff2_done);

  -- Generate filter channels
  ads1281_filter_channel_gen : for i in 0 to ads1281_filter_num_channels_c - 1 generate
    ads1281_filter_channel_inst : entity work.ads1281_filter_channel
      port map (
        clk_i         => clk_i,
        rst_asy_n_i   => rst_asy_n_i,
        rst_syn_i     => rst_syn_i,
        sample_i      => sample_strb,
        adc_m0_i      => adc_m0_i(i),
        adc_m1_i      => adc_m1_i(i),
        coeff1_i      => coeff1,
        coeff1_en_i   => coeff1_en,
        coeff1_done_i => coeff1_done,
        coeff2_i      => coeff2,
        coeff2_en_i   => coeff2_en,
        coeff2_done_i => coeff2_done,
        result_o      => result_o(i),
        result_en_o   => result_en_o(i));
  end generate ads1281_filter_channel_gen;

end architecture rtl;
