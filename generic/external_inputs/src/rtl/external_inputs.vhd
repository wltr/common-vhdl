--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Synchronize and filter external inputs.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity external_inputs is
  generic (
    -- Initial value of input signals
    init_value_g : std_ulogic := '0';

    -- Number of inputs
    num_inputs_g : positive := 1;

    -- Add glitch filter
    filter_g : boolean := true);
  port (
    -- Clock and resets
    clk_i       : in std_ulogic;
    rst_asy_n_i : in std_ulogic;
    rst_syn_i   : in std_ulogic;

    -- Input signals
    sig_i : in  std_ulogic_vector(num_inputs_g - 1 downto 0);

    -- Synchronized and filtered output signals
    sig_o : out std_ulogic_vector(num_inputs_g - 1 downto 0));
end entity external_inputs;

architecture rtl of external_inputs is

  ------------------------------------------------------------------------------
  -- Internal Wires
  ------------------------------------------------------------------------------

  signal sig : std_ulogic_vector(sig_i'range);

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Instances
  ------------------------------------------------------------------------------

  inst_gen : for i in sig_i'range generate
    -- Synchronize the inputs into the local clock domain
    delay_inst : entity work.delay
      generic map (
        init_value_g => init_value_g,
        num_delay_g  => 2)
      port map (
        clk_i       => clk_i,
        rst_asy_n_i => rst_asy_n_i,
        rst_syn_i   => rst_syn_i,
        en_i        => '1',
        sig_i       => sig_i(i),
        dlyd_o      => sig(i));

    -- Direct output without glitch filter
    no_filter_gen : if filter_g = false generate
      sig_o(i) <= sig(i);
    end generate no_filter_gen;

    -- Filter glitches
    filter_gen : if filter_g = true generate
      glitch_filter_inst : entity work.glitch_filter
        generic map (
          init_value_g => init_value_g,
          num_delay_g  => 1)
        port map (
          clk_i       => clk_i,
          rst_asy_n_i => rst_asy_n_i,
          rst_syn_i   => rst_syn_i,
          en_i        => '1',
          sig_i       => sig(i),
          sig_o       => sig_o(i));
    end generate filter_gen;
  end generate inst_gen;

end architecture rtl;
