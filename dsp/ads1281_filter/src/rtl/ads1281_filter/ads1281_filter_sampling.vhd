--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Check for changes on one of the input channels.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.ads1281_filter_pkg.all;

entity ads1281_filter_sampling is
  port (
    -- Clock and resets
    clk_i       : in std_ulogic;
    rst_asy_n_i : in std_ulogic;
    rst_syn_i   : in std_ulogic;

    -- ADC M1 bit streams
    adc_m1_i : in std_ulogic_vector(ads1281_filter_num_channels_c - 1 downto 0);

    -- Change detected
    changed_o : out std_ulogic);
end entity ads1281_filter_sampling;

architecture rtl of ads1281_filter_sampling is

  ------------------------------------------------------------------------------
  -- Internal Registers
  ------------------------------------------------------------------------------

  signal adc_m1  : std_ulogic_vector(adc_m1_i'range);
  signal changed : std_ulogic;

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------

  changed_o <= changed;

  ------------------------------------------------------------------------------
  -- Registers
  ------------------------------------------------------------------------------

  regs : process (clk_i, rst_asy_n_i) is
    procedure reset is
    begin
      adc_m1  <= (others => '0');
      changed <= '0';
    end procedure reset;
  begin -- process regs
    if rst_asy_n_i = '0' then
      reset;
    elsif rising_edge(clk_i) then
      if rst_syn_i = '1' then
        reset;
      else
        -- Defaults
        changed <= '0';

        if adc_m1_i /= adc_m1 then
          changed <= '1';
        end if;

        adc_m1 <= adc_m1_i;
      end if;
    end if;
  end process regs;

end architecture rtl;
