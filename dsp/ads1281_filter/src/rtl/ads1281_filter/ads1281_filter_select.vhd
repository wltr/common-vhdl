--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Alternate between the two interleaved filters.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity ads1281_filter_select is
  port (
    -- Clock and resets
    clk_i       : in std_ulogic;
    rst_asy_n_i : in std_ulogic;
    rst_syn_i   : in std_ulogic;

    -- Synchronization strobes
    strb_ms_i : in std_ulogic;

    -- Start interleaved filters
    coeff1_start_o : out std_ulogic;
    coeff2_start_o : out std_ulogic);
end entity ads1281_filter_select;

architecture rtl of ads1281_filter_select is

  ------------------------------------------------------------------------------
  -- Internal Registers
  ------------------------------------------------------------------------------

  signal toggle : std_ulogic;

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------

  coeff1_start_o <= strb_ms_i and not toggle;
  coeff2_start_o <= strb_ms_i and toggle;

  ------------------------------------------------------------------------------
  -- Registers
  ------------------------------------------------------------------------------

  regs : process (clk_i, rst_asy_n_i) is
    procedure reset is
    begin
      toggle <= '0';
    end procedure reset;
  begin -- process regs
    if rst_asy_n_i = '0' then
      reset;
    elsif rising_edge(clk_i) then
      if rst_syn_i = '1' then
        reset;
      else
        if strb_ms_i = '1' then
          toggle <= not toggle;
        end if;
      end if;
    end if;
  end process regs;

end architecture rtl;
