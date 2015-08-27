--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2013 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Delay signal through an N-stage shift register.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity delay is
  generic (
    -- Initial value of input signal
    init_value_g : std_ulogic := '0';

    -- Number of delay stages
    num_delay_g : positive := 2);
  port (
    -- Clock and resets
    clk_i       : in std_ulogic;
    rst_asy_n_i : in std_ulogic;
    rst_syn_i   : in std_ulogic;

    -- Enable
    en_i : in std_ulogic;

    -- Input signal
    sig_i : in std_ulogic;

    -- Delayed signal
    dlyd_o : out std_ulogic);
end entity delay;

architecture rtl of delay is

  ------------------------------------------------------------------------------
  -- Internal Registers
  ------------------------------------------------------------------------------

  signal sig : std_ulogic_vector(num_delay_g - 1 downto 0) := (others => init_value_g);

  ------------------------------------------------------------------------------
  -- Internal Wires
  ------------------------------------------------------------------------------

  signal next_sig : std_ulogic_vector(num_delay_g - 1 downto 0);

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------

  dlyd_o <= sig(sig'high);

  ------------------------------------------------------------------------------
  -- Signal Assignments
  ------------------------------------------------------------------------------

  -- Delay only for one clock cycle
  single_delay_gen : if num_delay_g = 1 generate
    next_sig(0) <= sig_i;
  end generate single_delay_gen;

  -- Delay for multiple clock cycles
  multiple_delays_gen : if num_delay_g > 1 generate
    next_sig <= sig(sig'high - 1 downto sig'low) & sig_i;
  end generate multiple_delays_gen;

  ------------------------------------------------------------------------------
  -- Registers
  ------------------------------------------------------------------------------

  regs : process (clk_i, rst_asy_n_i) is
    procedure reset is
    begin
      sig <= (others => init_value_g);
    end procedure reset;
  begin -- process regs
    if rst_asy_n_i = '0' then
      reset;
    elsif rising_edge(clk_i) then
      if rst_syn_i = '1' then
        reset;
      elsif en_i = '1' then
        sig <= next_sig;
      end if;
    end if;
  end process regs;

end architecture rtl;
