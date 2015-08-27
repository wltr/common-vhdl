--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Calculate the coefficients and pass them on the each channel.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ads1281_filter_channel is
  port (
    -- Clock and resets
    clk_i       : in std_ulogic;
    rst_asy_n_i : in std_ulogic;
    rst_syn_i   : in std_ulogic;

    -- Control strobes
    sample_i : in std_ulogic;

    -- ADC bit streams
    adc_m0_i : in std_ulogic;
    adc_m1_i : in std_ulogic;

    -- Filter coefficients
    coeff1_i      : in unsigned(23 downto 0);
    coeff1_en_i   : in std_ulogic;
    coeff1_done_i : in std_ulogic;

    coeff2_i      : in unsigned(23 downto 0);
    coeff2_en_i   : in std_ulogic;
    coeff2_done_i : in std_ulogic;

    -- Filter values
    result_o    : out std_ulogic_vector(23 downto 0);
    result_en_o : out std_ulogic);
end entity ads1281_filter_channel;

architecture rtl of ads1281_filter_channel is

  ------------------------------------------------------------------------------
  -- Internal Wires
  ------------------------------------------------------------------------------

  signal adc_m0_fifo : std_ulogic_vector(2 downto 0);
  signal adc_m1_fifo : std_ulogic_vector(2 downto 0);
  signal dec_data    : signed(6 downto 0);
  signal mac1        : signed(23 downto 0);
  signal mac1_en     : std_ulogic;
  signal mac2        : signed(23 downto 0);
  signal mac2_en     : std_ulogic;

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Instances
  ------------------------------------------------------------------------------

  -- Buffer M0 bit stream
  ads1281_filter_fifo_inst_0 : entity work.ads1281_filter_fifo
    generic map (
      init_value_g => '0',
      offset_g     => 0)
    port map (
      clk_i       => clk_i,
      rst_asy_n_i => rst_asy_n_i,
      rst_syn_i   => rst_syn_i,
      en_i        => sample_i,
      sig_i       => adc_m0_i,
      fifo_o      => adc_m0_fifo);

  -- Buffer M1 bit stream
  ads1281_filter_fifo_inst_1 : entity work.ads1281_filter_fifo
    generic map (
      init_value_g => '0',
      offset_g     => 2)
    port map (
      clk_i       => clk_i,
      rst_asy_n_i => rst_asy_n_i,
      rst_syn_i   => rst_syn_i,
      en_i        => sample_i,
      sig_i       => adc_m1_i,
      fifo_o      => adc_m1_fifo);

  -- Decode M0 and M1 bit stream samples
  ads1281_filter_decoder_inst : entity work.ads1281_filter_decoder
    port map (
      clk_i       => clk_i,
      rst_asy_n_i => rst_asy_n_i,
      rst_syn_i   => rst_syn_i,
      adc_m0_i    => adc_m0_fifo,
      adc_m1_i    => adc_m1_fifo,
      data_o      => dec_data);

  -- Multiply input data with 1st filter coefficients and accumulate
  ads1281_filter_mac_inst_0 : entity work.ads1281_filter_mac
    port map (
      clk_i        => clk_i,
      rst_asy_n_i  => rst_asy_n_i,
      rst_syn_i    => rst_syn_i,
      data_i       => dec_data,
      coeff_i      => coeff1_i,
      coeff_en_i   => coeff1_en_i,
      coeff_done_i => coeff1_done_i,
      data_o       => mac1,
      data_en_o    => mac1_en);

  -- Multiply input data with 2nd filter coefficients and accumulate
  ads1281_filter_mac_inst_1 : entity work.ads1281_filter_mac
    port map (
      clk_i        => clk_i,
      rst_asy_n_i  => rst_asy_n_i,
      rst_syn_i    => rst_syn_i,
      data_i       => dec_data,
      coeff_i      => coeff2_i,
      coeff_en_i   => coeff2_en_i,
      coeff_done_i => coeff2_done_i,
      data_o       => mac2,
      data_en_o    => mac2_en);

  -- Alternate between the two filter output values
  ads1281_filter_output_inst : entity work.ads1281_filter_output
    port map (
      clk_i       => clk_i,
      rst_asy_n_i => rst_asy_n_i,
      rst_syn_i   => rst_syn_i,
      data1_i     => mac1,
      data1_en_i  => mac1_en,
      data2_i     => mac2,
      data2_en_i  => mac2_en,
      data_o      => result_o,
      data_en_o   => result_en_o);

end architecture rtl;
